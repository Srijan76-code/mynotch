//
//  BluetoothMonitor.swift
//  mynotch
//

import Foundation
import IOBluetooth

final class BluetoothMonitor {
    static let shared = BluetoothMonitor()
    
    private var connectedDeviceNames = Set<String>()
    private var timer: Timer?
    private var isInitialized = false
    
    private init() {
        checkConnectedDevices(initial: true)
        setupPolling()
    }
    
    private func setupPolling() {
        // Poll connected bluetooth devices every 2.0 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkConnectedDevices(initial: false)
        }
    }
    
    private func checkConnectedDevices(initial: Bool) {
        guard let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return
        }
        
        var currentConnected = Set<String>()
        for device in paired {
            if device.isConnected() {
                let name = device.nameOrAddress ?? "Bluetooth Device"
                currentConnected.insert(name)
            }
        }
        
        if initial || !isInitialized {
            connectedDeviceNames = currentConnected
            isInitialized = true
            return
        }
        
        // Check for new connections
        let newlyConnected = currentConnected.subtracting(connectedDeviceNames)
        for deviceName in newlyConnected {
            NotchAlertManager.shared.triggerBluetoothConnected(deviceName: deviceName)
        }
        
        // Check for disconnections
        let newlyDisconnected = connectedDeviceNames.subtracting(currentConnected)
        for deviceName in newlyDisconnected {
            NotchAlertManager.shared.triggerBluetoothDisconnected(deviceName: deviceName)
        }
        
        connectedDeviceNames = currentConnected
    }
}
