//
//  SettingsSheetView.swift
//  mynotch
//

import SwiftUI
import AppKit

final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?
    
    @MainActor
    func showSettings() {
        if let window = self.window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsSheetView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "mynotch Settings"
        newWindow.styleMask = [.titled, .closable]
        newWindow.isReleasedWhenClosed = false
        newWindow.center()
        
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct SettingsSheetView: View {
    @ObservedObject var alertManager = NotchAlertManager.shared
    @ObservedObject var mediaManager = MediaManager.shared
    @ObservedObject var cameraManager = CameraManager.shared
    
    var body: some View {
        TabView {
            GeneralSettingsView(mediaManager: mediaManager, alertManager: alertManager)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            PermissionsSettingsView(cameraManager: cameraManager)
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }
        }
        .frame(width: 450, height: 350)
        .padding()
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @ObservedObject var mediaManager: MediaManager
    @ObservedObject var alertManager: NotchAlertManager
    
    var body: some View {
        Form {
            Section("Media Player") {
                HStack {
                    Text("Now Playing App:")
                    Spacer()
                    Text(mediaManager.nowPlayingAppName.isEmpty ? "None detected" : mediaManager.nowPlayingAppName)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Media Status:")
                    Spacer()
                    Text(mediaManager.mediaStatus)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }

                if mediaManager.mediaStatus.contains("System Settings") {
                    Button("Open Automation Settings") {
                        mediaManager.openAutomationSettings()
                    }
                }
                
                Text("Spotify and Apple Music support metadata, timeline, and controls. Browser apps are detected, but macOS does not expose universal tab media metadata or controls.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            Section("Test Dynamic Island Animations") {
                HStack(spacing: 8) {
                    Button("⚡ Power Connect") {
                        alertManager.triggerPowerConnected()
                    }
                    Button("🔌 Power Disconnect") {
                        alertManager.triggerPowerDisconnected()
                    }
                }
                HStack(spacing: 8) {
                    Button("🎧 AirPods Connect") {
                        alertManager.triggerBluetoothConnected()
                    }
                    Button("📡 AirPods Disconnect") {
                        alertManager.triggerBluetoothDisconnected()
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            Button("Quit mynotch") {
                NSApplication.shared.terminate(nil)
            }
            .foregroundColor(.red)
        }
        .padding()
    }
}

// MARK: - Permissions Settings

struct PermissionsSettingsView: View {
    @ObservedObject var cameraManager: CameraManager
    @State private var calendarAccess: Bool = false
    
    var body: some View {
        Form {
            Section("Required Permissions") {
                // Camera
                HStack {
                    Image(systemName: cameraManager.permissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(cameraManager.permissionGranted ? .green : .red)
                    Text("Camera (Mirror)")
                    Spacer()
                    if !cameraManager.permissionGranted {
                        Button("Request") {
                            cameraManager.checkPermission()
                        }
                    } else {
                        Text("Granted")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Accessibility note
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Media Control")
                    Spacer()
                    Text("Uses player automation permissions")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                // Calendar
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.cyan)
                    Text("Calendar")
                    Spacer()
                    Button("Open Privacy Settings") {
                        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.systempreferences") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .font(.caption)
                }
            }
            
            Text("If a permission is missing, macOS will prompt you when the feature is first used. You can also grant access via System Settings > Privacy & Security.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .padding()
    }
}
