//
//  FileTrayManager.swift
//  mynotch
//

import Foundation
import AppKit
import SwiftUI
import UniformTypeIdentifiers
import Combine

struct TrayFile: Identifiable, Equatable {
    let id: UUID
    let url: URL
    let name: String
    let fileSizeString: String
    let icon: NSImage
    
    static func == (lhs: TrayFile, rhs: TrayFile) -> Bool {
        lhs.id == rhs.id
    }
}

final class FileTrayManager: ObservableObject {
    static let shared = FileTrayManager()
    
    @Published var files: [TrayFile] = []
    @Published var isDropTargeted: Bool = false
    
    private init() {}
    
    func addFiles(urls: [URL]) {
        for url in urls {
            // Avoid duplicates by url
            if files.contains(where: { $0.url == url }) { continue }
            
            let name = url.lastPathComponent
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            
            var sizeString = ""
            if let resources = try? url.resourceValues(forKeys: [.fileSizeKey]), let size = resources.fileSize {
                sizeString = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            }
            
            let trayFile = TrayFile(id: UUID(), url: url, name: name, fileSizeString: sizeString, icon: icon)
            files.append(trayFile)
        }
        HapticFeedback.lightTap()
    }
    
    func removeFile(id: UUID) {
        files.removeAll(where: { $0.id == id })
        HapticFeedback.lightTap()
    }
    
    func clearAll() {
        files.removeAll()
        HapticFeedback.lightTap()
    }
    
    func airDropFile(_ file: TrayFile) {
        airDrop(urls: [file.url])
    }
    
    func airDropAll() {
        guard !files.isEmpty else { return }
        airDrop(urls: files.map { $0.url })
    }
    
    func airDrop(urls: [URL]) {
        HapticFeedback.stateChange()
        guard let sharingService = NSSharingService(named: .sendViaAirDrop) else {
            return
        }
        if sharingService.canPerform(withItems: urls) {
            sharingService.perform(withItems: urls)
        }
    }
}
