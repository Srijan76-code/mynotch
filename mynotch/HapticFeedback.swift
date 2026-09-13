//
//  HapticFeedback.swift
//  mynotch
//

import AppKit

enum HapticFeedback {
    static func perform(_ pattern: NSHapticFeedbackManager.FeedbackPattern = .alignment) {
        DispatchQueue.main.async {
            NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .default)
        }
    }
    
    static func lightTap() {
        perform(.alignment)
    }
    
    static func stateChange() {
        perform(.levelChange)
    }
    
    static func notificationPulse() {
        perform(.levelChange)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        }
    }
}
