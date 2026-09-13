//
//  MusicPlayerView.swift
//  mynotch
//

import SwiftUI

struct MusicPlayerView: View {
    @ObservedObject var mediaManager = MediaManager.shared
    @State private var isDraggingSlider = false
    @State private var dragPosition: Double = 0
    @State private var isHoveringControls = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Upper row: Artwork + Metadata + Playback Controls
            HStack(spacing: 12) {
                // Large Album Artwork
                albumArtwork
                
                // Track Info & Controls
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mediaManager.track.title)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(mediaManager.track.album)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.65))
                                .lineLimit(1)
                            
                            Text(mediaManager.track.artist)
                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.45))
                                .lineLimit(1)
                        }
                        
                        Spacer()
                    }
                    
                    Spacer(minLength: 4)
                    
                    // Controls (Previous, Play/Pause, Next)
                    HStack(spacing: 16) {
                        Button(action: { mediaManager.previousTrack() }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { mediaManager.togglePlayPause() }) {
                            Image(systemName: mediaManager.track.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { mediaManager.nextTrack() }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // Media Source Switcher Menu
                        Menu {
                            ForEach(mediaManager.availableSources) { source in
                                Button(action: { mediaManager.selectSource(source) }) {
                                    HStack {
                                        Text(source.rawValue)
                                        if mediaManager.selectedSource == source {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: mediaManager.selectedSource.iconName)
                                    .font(.system(size: 9))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8))
                            }
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                        }
                        .menuStyle(.borderlessButton)
                    }
                }
            }
            
            // Scrubber Bar & Timestamps
            VStack(spacing: 3) {
                // Interactive Progress Track
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background track
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 4)
                        
                        // Elapsed progress track
                        Capsule()
                            .fill(Color.white)
                            .frame(width: max(0, min(geo.size.width, CGFloat(progressRatio) * geo.size.width)), height: 4)
                        
                        // Draggable thumb knob
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .offset(x: max(0, min(geo.size.width - 10, CGFloat(progressRatio) * (geo.size.width - 10))))
                            .shadow(color: .black.opacity(0.4), radius: 2)
                    }
                    .frame(height: 12)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDraggingSlider = true
                                let clampedX = max(0, min(value.location.x, geo.size.width))
                                let ratio = Double(clampedX / geo.size.width)
                                dragPosition = ratio * mediaManager.track.duration
                            }
                            .onEnded { value in
                                let clampedX = max(0, min(value.location.x, geo.size.width))
                                let ratio = Double(clampedX / geo.size.width)
                                let targetTime = ratio * mediaManager.track.duration
                                mediaManager.seek(to: targetTime)
                                isDraggingSlider = false
                                HapticFeedback.lightTap()
                            }
                    )
                }
                .frame(height: 12)
                
                // Timestamp labels
                HStack {
                    Text(formatTime(isDraggingSlider ? dragPosition : mediaManager.track.currentTime))
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .monospacedDigit()
                    
                    Spacer()
                    
                    Text(formatTime(mediaManager.track.duration))
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .monospacedDigit()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Album Artwork
    private var albumArtwork: some View {
        Group {
            if let artwork = mediaManager.track.artworkImage {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Sleek moody album cover matching "Heavenly" / Cigarettes After Sex style
                ZStack {
                    LinearGradient(
                        colors: [Color(white: 0.35), Color(white: 0.15), Color(white: 0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack(spacing: 2) {
                        Text(mediaManager.track.artist.uppercased())
                            .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.75))
                            .tracking(1.5)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 18, height: 1)
                    }
                }
            }
        }
        .frame(width: 70, height: 70)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
        )
        .shadow(color: .black.opacity(0.6), radius: 6, y: 3)
    }
    
    private var progressRatio: Double {
        let total = max(1, mediaManager.track.duration)
        let current = isDraggingSlider ? dragPosition : mediaManager.track.currentTime
        return min(max(0, current / total), 1.0)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
