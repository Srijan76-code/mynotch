//
//  NotchContentView.swift
//  mynotch
//

import SwiftUI
import Pow

struct NotchContentView: View {
    @ObservedObject var stateManager = NotchStateManager.shared
    @ObservedObject var trayManager = FileTrayManager.shared
    
    var body: some View {
        Group {
            switch stateManager.presentation {
            case .natural:
                CollapsedNotchView()
                    .frame(width: 120, height: 34)
            case .hovered:
                CollapsedNotchView()
                    .frame(width: 220, height: 42)
            case .expanded:
                expandedContent
            }
        }
        .animation(.easeInOut(duration: 0.2), value: stateManager.presentation)
    }

    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            HStack(spacing: 8) {
                // Tab Buttons (Nook / Tray)
                tabSelector
                
                Spacer()
                
                // Settings Gear Icon
                Button(action: {
                    HapticFeedback.lightTap()
                    SettingsWindowController.shared.showSettings()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                        .padding(6)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                // Quit Button
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 2)
            
            // Tab Content
            Group {
                if stateManager.selectedTab == .nook {
                    NookView()
                        .transition(.move(edge: .leading))
                } else {
                    TrayView()
                        .transition(.move(edge: .trailing))
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(width: 670, height: 168)
        }
    
    // MARK: - Tab Selector Pills
    private var tabSelector: some View {
        HStack(spacing: 4) {
            // Nook Tab
            tabButton(
                tab: .nook,
                title: "Nook",
                systemImage: "lamp.desk"
            )
            
            // Tray Tab
            tabButton(
                tab: .tray,
                title: "Tray",
                systemImage: "tray.and.arrow.down",
                badgeCount: trayManager.files.count
            )
        }
    }
    
    private func tabButton(tab: NotchTab, title: String, systemImage: String, badgeCount: Int = 0) -> some View {
        let isSelected = stateManager.selectedTab == tab
        
        return Button(action: {
            HapticFeedback.lightTap()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                stateManager.selectedTab = tab
            }
        }) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                
                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.55))
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(
                isSelected ?
                Color.white.opacity(0.18) :
                Color.clear
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
