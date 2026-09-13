//
//  CollapsedNotchView.swift
//  mynotch
//

import SwiftUI
import Combine

struct CollapsedNotchView: View {
    @ObservedObject var mediaManager = MediaManager.shared
    
    @State private var bar1Height: CGFloat = 8
    @State private var bar2Height: CGFloat = 14
    @State private var bar3Height: CGFloat = 10
    
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            // Main collapsed notch bar
            HStack(spacing: 12) {
                // Left: Mini Album Art
                miniAlbumArtwork
                    .padding(.leading, 6)
                
                Spacer()
                
                // Right: Animated Audio Waveform Bars
                equalizerWaveform
                    .padding(.trailing, 8)
            }
            .frame(height: 32)
            .padding(.horizontal, 6)
            

        }
        .onReceive(timer) { _ in
            if mediaManager.track.isPlaying {
                withAnimation(.easeInOut(duration: 0.22)) {
                    bar1Height = CGFloat.random(in: 4...15)
                    bar2Height = CGFloat.random(in: 8...18)
                    bar3Height = CGFloat.random(in: 4...14)
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    bar1Height = 4
                    bar2Height = 4
                    bar3Height = 4
                }
            }
        }
    }
    
    // MARK: - Mini Album Artwork
    private var miniAlbumArtwork: some View {
        Group {
            if let artwork = mediaManager.track.artworkImage {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Default artistic dark album cover matching screenshot
                ZStack {
                    LinearGradient(
                        colors: [Color(white: 0.25), Color(white: 0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    Image(systemName: "music.note")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
        .frame(width: 22, height: 22)
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
    }
    
    // MARK: - Equalizer Waveform
    private var equalizerWaveform: some View {
        HStack(alignment: .center, spacing: 2.5) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.white.opacity(0.9))
                .frame(width: 2.8, height: bar1Height)
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.white.opacity(0.9))
                .frame(width: 2.8, height: bar2Height)
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.white.opacity(0.9))
                .frame(width: 2.8, height: bar3Height)
        }
        .frame(height: 20)
    }
}
