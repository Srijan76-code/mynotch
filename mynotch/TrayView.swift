//
//  TrayView.swift
//  mynotch
//

import SwiftUI
import UniformTypeIdentifiers

struct TrayView: View {
    @ObservedObject var trayManager = FileTrayManager.shared
    @State private var isTargeted = false
    @State private var isAirDropTargeted = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Main File Tray Area
            VStack(spacing: 8) {
                if trayManager.files.isEmpty {
                    // Empty state dropzone
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isTargeted ? Color.blue : Color.white.opacity(0.15),
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isTargeted ? Color.blue.opacity(0.08) : Color.white.opacity(0.03))
                            )
                        
                        HStack(spacing: 12) {
                            Image(systemName: "tray.and.arrow.down")
                                .font(.system(size: 20))
                                .foregroundColor(isTargeted ? .blue : .white.opacity(0.6))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Drop files here to park them")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Drag them out later or share anytime")
                                    .font(.system(size: 10, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                    .frame(height: 76)
                } else {
                    // Filled state: Scrollable horizontal list of parked files
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(trayManager.files) { file in
                                TrayFileChip(file: file) {
                                    trayManager.removeFile(id: file.id)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .frame(height: 52)
                    
                    // Action footer: Clear all & count
                    HStack {
                        Text("\(trayManager.files.count) \(trayManager.files.count == 1 ? "file" : "files") in tray")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Spacer()
                        
                        Button("Clear All") {
                            trayManager.clearAll()
                        }
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                handleFileDrop(providers: providers, isDirectAirDrop: false)
            }
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: 74)
            
            // Dedicated AirDrop Target Zone & Action
            VStack(spacing: 6) {
                Button(action: {
                    trayManager.airDropAll()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isAirDropTargeted ? Color.blue.opacity(0.3) : Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(isAirDropTargeted ? Color.blue : Color.white.opacity(0.12), lineWidth: 1)
                            )
                        
                        VStack(spacing: 4) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(isAirDropTargeted ? .blue : .white)
                            
                            Text("AirDrop")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 90, height: 68)
                }
                .buttonStyle(.plain)
                .onDrop(of: [.fileURL], isTargeted: $isAirDropTargeted) { providers in
                    handleFileDrop(providers: providers, isDirectAirDrop: true)
                }
                
                Text(isAirDropTargeted ? "Release to AirDrop" : "Drop to AirDrop")
                    .font(.system(size: 8.5, weight: .medium, design: .rounded))
                    .foregroundColor(isAirDropTargeted ? .blue : .white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    private func handleFileDrop(providers: [NSItemProvider], isDirectAirDrop: Bool) -> Bool {
        var urlsToProcess: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    DispatchQueue.main.async {
                        urlsToProcess.append(url)
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if isDirectAirDrop {
                trayManager.airDrop(urls: urlsToProcess)
            } else {
                trayManager.addFiles(urls: urlsToProcess)
            }
        }
        return true
    }
}

// MARK: - File Chip in Tray
struct TrayFileChip: View {
    let file: TrayFile
    let onDelete: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: file.icon)
                .resizable()
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(file.name)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(maxWidth: 90, alignment: .leading)
                
                Text(file.fileSizeString)
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            // Delete button on hover
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(isHovered ? 0.12 : 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        // Allow dragging files out of the tray into any application or Finder!
        .onDrag {
            NSItemProvider(contentsOf: file.url) ?? NSItemProvider()
        }
    }
}
