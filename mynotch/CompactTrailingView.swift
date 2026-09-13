//
//  CompactTrailingView.swift
//  mynotch
//

import SwiftUI

/// Mini view shown to the RIGHT of the notch in compact state.
/// Displays the next calendar event or a small clock.
struct CompactTrailingView: View {
    @ObservedObject var calendarManager = CalendarManager.shared
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.cyan.opacity(0.9))
            
            Text(shortEventText)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
    }
    
    private var shortEventText: String {
        let text = calendarManager.todayEventsText
        if text.isEmpty || text == "Loading events..." || text == "No events today" {
            // Show current time instead
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: Date())
        }
        // Truncate long event text
        if text.count > 18 {
            return String(text.prefix(18)) + "…"
        }
        return text
    }
}
