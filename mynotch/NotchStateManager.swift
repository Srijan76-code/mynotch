//
//  NotchStateManager.swift
//  mynotch
//

import SwiftUI
import Combine

enum NotchTab: String, CaseIterable, Identifiable {
    case nook = "Nook"
    case tray = "Tray"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .nook: return "lamp.desk"
        case .tray: return "tray.and.arrow.down"
        }
    }
}

enum NotchPresentation {
    case natural
    case hovered
    case expanded
}

final class NotchStateManager: ObservableObject {
    static let shared = NotchStateManager()
    
    @Published var selectedTab: NotchTab = .nook
    @Published var isSettingsPresented: Bool = false
    @Published var presentation: NotchPresentation = .natural
    
    // For legacy compatibility, although DynamicNotch handles hover now
    @Published var isHovered: Bool = false
    var onResizeNeeded: ((CGFloat, CGFloat) -> Void)?
    
    private init() {}
    
    func setHovered(_ hovered: Bool) {
        // Now handled by DynamicNotchKit, but keeping this for MenuBarExtra manual trigger
        // Actual expansion should call dynamicNotch.expand() from AppDelegate
        guard isHovered != hovered else { return }
        self.isHovered = hovered
        if hovered {
            HapticFeedback.lightTap()
        }
    }
    
    func updateWindowDimensions() {
        // No-op: DynamicNotchKit handles sizing dynamically based on SwiftUI frame
    }
}
