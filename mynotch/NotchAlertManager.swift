//
//  NotchAlertManager.swift
//  mynotch
//

import Foundation
import SwiftUI
import AppKit
import Combine
import DynamicNotchKit

final class NotchAlertManager: ObservableObject {
    static let shared = NotchAlertManager()
    
    // For legacy compat (just in case)
    @Published var isAlertActive: Bool = false
    
    private var currentAlertTask: Task<Void, Never>?
    private var currentNotchInfo: DynamicNotchInfo<Image>?
    
    private init() {}
    
    func showAlert(icon: String, iconColor: Color, title: String, duration: TimeInterval) {
        currentAlertTask?.cancel()
        
        currentAlertTask = Task { @MainActor in
            // Hide previous if exists
            if let previous = currentNotchInfo {
                previous.hide()
            }
            
            let info = DynamicNotchInfo(
                icon: Image(systemName: icon),
                title: title,
                iconColor: iconColor
            )
            self.currentNotchInfo = info
            self.isAlertActive = true
            
            info.show(for: duration)
            HapticFeedback.notificationPulse()
            
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            if self.currentNotchInfo === info {
                self.isAlertActive = false
                self.currentNotchInfo = nil
            }
        }
    }
    
    // MARK: - Quick Triggers
    func triggerPowerConnected() {
        showAlert(icon: "bolt.fill", iconColor: .green, title: "Power Connected", duration: 2.8)
    }
    
    func triggerPowerDisconnected() {
        showAlert(icon: "cable.connector.slash", iconColor: .orange, title: "Power Disconnected", duration: 2.5)
    }
    
    func triggerBluetoothConnected(deviceName: String = "AirPods Pro") {
        showAlert(icon: "headphones", iconColor: .blue, title: "\(deviceName) Connected", duration: 2.8)
    }
    
    func triggerBluetoothDisconnected(deviceName: String = "AirPods Pro") {
        showAlert(icon: "antenna.radiowaves.left.and.right.slash", iconColor: .gray, title: "\(deviceName) Disconnected", duration: 2.5)
    }
}
