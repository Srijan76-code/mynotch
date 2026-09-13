//
//  CompactLeadingView.swift
//  mynotch
//

import SwiftUI
import Combine

/// Mini view shown to the LEFT of the notch in compact state.
/// Displays album art + tiny equalizer bars (like the collapsed view).
struct CompactLeadingView: View {
    @ObservedObject var mediaManager = MediaManager.shared
    
    @State private var bar1: CGFloat = 8
    @State private var bar2: CGFloat = 12
    @State private var bar3: CGFloat = 6
    
    private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 6) {
            // Mini Album Art
            Group {
                if let artwork = mediaManager.track.artworkImage {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [Color(white: 0.25), Color(white: 0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        Image(systemName: "music.note")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .frame(width: 16, height: 16)
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            
            // Tiny equalizer
            HStack(alignment: .center, spacing: 1.5) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 2, height: bar1)
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 2, height: bar2)
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 2, height: bar3)
            }
            .frame(height: 14)
        }
        .onReceive(timer) { _ in
            if mediaManager.track.isPlaying {
                withAnimation(.easeInOut(duration: 0.2)) {
                    bar1 = .random(in: 3...13)
                    bar2 = .random(in: 5...14)
                    bar3 = .random(in: 3...12)
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    bar1 = 3; bar2 = 3; bar3 = 3
                }
            }
        }
    }
}
