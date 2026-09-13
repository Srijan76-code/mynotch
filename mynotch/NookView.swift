//
//  NookView.swift
//  mynotch
//

import SwiftUI

struct NookView: View {
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Left Widget: Music Player
            MusicPlayerView()
                .frame(width: 250)
            
            // Subtle Divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: 74)
            
            // Center Widget: Camera / Mirror
            CameraMirrorView()
                .frame(width: 90)
            
            // Subtle Divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: 74)
            
            // Right Widget: Calendar
            CalendarWidgetView()
                .frame(width: 240)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
