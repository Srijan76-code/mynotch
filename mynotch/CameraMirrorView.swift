//
//  CameraMirrorView.swift
//  mynotch
//

import SwiftUI
import AVFoundation

struct CameraMirrorView: View {
    @ObservedObject var cameraManager = CameraManager.shared
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            cameraManager.toggleMirror()
        }) {
            ZStack {
                if cameraManager.isMirrorActive {
                    // Live camera mirror feed
                    ZStack {
                        CameraPreviewView(cameraManager: cameraManager)
                            .frame(width: 86, height: 86)
                            .clipShape(Circle())
                        
                        // Active live border
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.8), Color.teal.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                        
                        // Close / stop indicator on hover
                        if isHovered {
                            Circle()
                                .fill(Color.black.opacity(0.45))
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            // Small live indicator dot
                            VStack {
                                Spacer()
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                    .shadow(color: .green.opacity(0.8), radius: 3)
                                    .padding(.bottom, 6)
                            }
                        }
                    }
                    .frame(width: 86, height: 86)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                } else {
                    // Inactive Circular Mirror button matching Screenshot 2
                    ZStack {
                        Circle()
                            .fill(Color(white: 0.16))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(isHovered ? 0.2 : 0.08), lineWidth: 1)
                            )
                        
                        VStack(spacing: 5) {
                            // Webcam / Mirror Icon
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.8), lineWidth: 1.8)
                                    .frame(width: 18, height: 18)
                                
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 6, height: 6)
                                
                                // Stand base line
                                Rectangle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 12, height: 1.8)
                                    .offset(y: 13)
                            }
                            .frame(height: 24)
                            .offset(y: -2)
                            
                            Text("Mirror")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }
                    .frame(width: 86, height: 86)
                    .scaleEffect(isHovered ? 1.04 : 1.0)
                    .shadow(color: .black.opacity(0.3), radius: isHovered ? 6 : 2)
                    .transition(.opacity)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
            if hovering {
                HapticFeedback.lightTap()
            }
        }
    }
}
