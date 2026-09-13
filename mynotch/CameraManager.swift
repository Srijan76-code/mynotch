//
//  CameraManager.swift
//  mynotch
//

import Foundation
import AVFoundation
import SwiftUI
import AppKit
import Combine

final class CameraManager: NSObject, ObservableObject {
    static let shared = CameraManager()
    
    @Published var isMirrorActive: Bool = false
    @Published var permissionGranted: Bool = false
    @Published var isSessionRunning: Bool = false
    @Published var errorMessage: String? = nil
    
    let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "dev.srijan.mynotch.cameraQueue")
    private var isConfigured = false
    
    override private init() {
        super.init()
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        self.permissionGranted = (status == .authorized)
        if status == .notDetermined {
            checkPermission()
        }
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.permissionGranted = true
                self.errorMessage = nil
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted && (self?.isMirrorActive ?? false) {
                        self?.startSession()
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.permissionGranted = false
                self.errorMessage = "Camera access denied. Enable in System Settings > Privacy & Security > Camera."
            }
        @unknown default:
            break
        }
    }
    
    func toggleMirror() {
        HapticFeedback.stateChange()
        isMirrorActive.toggle()
        if isMirrorActive {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .authorized {
                permissionGranted = true
                startSession()
            } else if status == .notDetermined {
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    DispatchQueue.main.async {
                        self?.permissionGranted = granted
                        if granted && (self?.isMirrorActive ?? false) {
                            self?.startSession()
                        }
                    }
                }
            } else {
                permissionGranted = false
                errorMessage = "Camera access denied. Enable in System Settings > Privacy & Security > Camera."
            }
        } else {
            stopSession()
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.isConfigured {
                self.configureSession()
            }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        guard let videoDevice = discoverySession.devices.first ?? AVCaptureDevice.default(for: .video) else {
            DispatchQueue.main.async {
                self.errorMessage = "No camera found"
            }
            captureSession.commitConfiguration()
            return
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                isConfigured = true
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to access camera: \(error.localizedDescription)"
            }
        }
        
        captureSession.commitConfiguration()
    }
}

// MARK: - Custom NSView for Camera Preview

class CameraNSView: NSView {
    override func makeBackingLayer() -> CALayer {
        let layer = AVCaptureVideoPreviewLayer(session: CameraManager.shared.captureSession)
        layer.videoGravity = .resizeAspectFill
        if let conn = layer.connection, conn.isVideoMirroringSupported {
            conn.automaticallyAdjustsVideoMirroring = false
            conn.isVideoMirrored = true
        }
        return layer
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer? {
        layer as? AVCaptureVideoPreviewLayer
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }
}

// MARK: - NSViewRepresentable for Camera Feed
struct CameraPreviewView: NSViewRepresentable {
    @ObservedObject var cameraManager = CameraManager.shared
    
    func makeNSView(context: Context) -> CameraNSView {
        let view = CameraNSView()
        return view
    }
    
    func updateNSView(_ nsView: CameraNSView, context: Context) {
        if let conn = nsView.previewLayer?.connection, conn.isVideoMirroringSupported {
            conn.automaticallyAdjustsVideoMirroring = false
            conn.isVideoMirrored = true
        }
    }
}
