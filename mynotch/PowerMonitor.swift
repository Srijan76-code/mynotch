//
//  PowerMonitor.swift
//  mynotch
//

import Foundation
import IOKit.ps

final class PowerMonitor {
    static let shared = PowerMonitor()
    
    private var isACConnected: Bool? = nil
    private var runLoopSource: CFRunLoopSource?
    private var timer: Timer?
    
    private init() {
        checkCurrentPowerState(initial: true)
        setupPolling()
    }
    
    private func setupPolling() {
        // Poll every 1.5s for fast detection of plug/unplug events
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.checkCurrentPowerState(initial: false)
        }
    }
    
    private func checkCurrentPowerState(initial: Bool) {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else {
            return
        }
        
        for source in sources {
            let description = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any] ?? [:]
            if description[kIOPSIsPresentKey] as? Bool == true {
                let powerState = description[kIOPSPowerSourceStateKey] as? String ?? ""
                let currentAC = (powerState == kIOPSACPowerValue)
                
                if let previousAC = isACConnected {
                    if previousAC != currentAC {
                        isACConnected = currentAC
                        if currentAC {
                            NotchAlertManager.shared.triggerPowerConnected()
                        } else {
                            NotchAlertManager.shared.triggerPowerDisconnected()
                        }
                    }
                } else {
                    // Initial recording
                    isACConnected = currentAC
                }
                return
            }
        }
    }
}
