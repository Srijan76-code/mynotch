//
//  mynotchApp.swift
//  mynotch
//

import SwiftUI
import AppKit
import DynamicNotchKit
import Pow
import LaunchAtLogin
import Defaults
import KeyboardShortcuts

@main
struct mynotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsSheetView()
                .frame(width: 450, height: 400)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var notch: DynamicNotch<NotchContentView>?
    
    private var mouseMonitor: Any?
    private var clickMonitor: Any?
    private var hoverTimer: Timer?
    private var isExpanded = false
    private var collapseWorkItem: DispatchWorkItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory app (no Dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize background monitors
        _ = PowerMonitor.shared
        _ = BluetoothMonitor.shared
        _ = MediaManager.shared
        _ = CalendarManager.shared
        
        setupNotchWindow()
        notch?.show()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    private func setupNotchWindow() {
        let dynamicNotch = DynamicNotch(style: .auto) {
            NotchContentView()
        }
        self.notch = dynamicNotch
        
        // Set up mouse tracking to expand on hover, collapse on leave
        setupMouseTracking()
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.handleMouseMoved(nil)
        }
    }
    
    private func setupMouseTracking() {
        // Use a global mouse-moved monitor to detect when cursor is near the notch
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved(event)
        }
        
        // Also monitor local events (when our window is key)
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved(event)
            return event
        }

        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.handleMouseClick()
        }
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.handleMouseClick()
            return event
        }
    }

    private func handleMouseMoved(_ event: NSEvent?) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        
        // Calculate the notch region (top-center of the screen)
        let notchWidth: CGFloat = 400 // generous hit area
        let notchHeight: CGFloat = 40  // menu bar height region
        let screenFrame = screen.frame
        
        let notchRect = NSRect(
            x: screenFrame.midX - (notchWidth / 2),
            y: screenFrame.maxY - notchHeight,
            width: notchWidth,
            height: notchHeight
        )
        
        let isInNotchArea = notchRect.contains(mouseLocation)
        
        let stateManager = NotchStateManager.shared
        if isInNotchArea && !isExpanded {
            // Cancel any pending collapse
            collapseWorkItem?.cancel()
            collapseWorkItem = nil
            
            isExpanded = true
            stateManager.presentation = .hovered
            notch?.show()
        } else if !isInNotchArea && isExpanded {
            // Check if mouse is still inside the expanded window
            if let window = notch?.windowController?.window {
                let windowFrame = window.frame
                // Add a generous margin so it doesn't collapse while moving within the expanded content
                let expandedRect = windowFrame.insetBy(dx: -25, dy: -25)
                
                if !expandedRect.contains(mouseLocation) {
                    // Debounce: wait a moment before collapsing (in case user is moving back)
                    collapseWorkItem?.cancel()
                    let workItem = DispatchWorkItem { [weak self] in
                        guard let self = self else { return }
                        // Double check mouse is still outside
                        let currentMouse = NSEvent.mouseLocation
                        if let window = self.notch?.windowController?.window {
                            let currentExpandedRect = window.frame.insetBy(dx: -25, dy: -25)
                            let currentNotchRect = NSRect(
                                x: screenFrame.midX - (notchWidth / 2),
                                y: screenFrame.maxY - notchHeight,
                                width: notchWidth,
                                height: notchHeight
                            )
                            if !currentExpandedRect.contains(currentMouse) && !currentNotchRect.contains(currentMouse) {
                                self.isExpanded = false
                                stateManager.presentation = .natural
                            }
                        } else {
                            self.isExpanded = false
                            stateManager.presentation = .natural
                        }
                    }

                    collapseWorkItem = workItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
                }
            }
        }
    }

    private func handleMouseClick() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let location = NSEvent.mouseLocation
        let notchRect = NSRect(
            x: screen.frame.midX - 200,
            y: screen.frame.maxY - 40,
            width: 400,
            height: 40
        )
        guard notchRect.contains(location) ||
              (notch?.windowController?.window.frame.contains(location) == true) else {
            return
        }

        isExpanded = true
        NotchStateManager.shared.presentation = .expanded
        notch?.show()
    }
    
    deinit {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
        }
        hoverTimer?.invalidate()
    }
}
