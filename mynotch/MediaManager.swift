//
//  MediaManager.swift
//  mynotch
//
//  Reads supported desktop players through their AppleScript interfaces.
//

import Foundation
import AppKit
import Combine
import SwiftUI

// MARK: - MediaSource

enum MediaSource: String, CaseIterable, Identifiable {
    case auto = "Auto Detect"
    case appleMusic = "Apple Music"
    case spotify = "Spotify"
    case webMedia = "YouTube / Web"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .auto: return "waveform"
        case .appleMusic: return "music.note"
        case .spotify: return "waveform"
        case .webMedia: return "globe"
        }
    }
}

// MARK: - TrackInfo

struct TrackInfo: Equatable {
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var currentTime: TimeInterval
    var isPlaying: Bool
    var source: MediaSource
    var artworkImage: NSImage?
    
    static let empty = TrackInfo(
        title: "Not Playing",
        artist: "—",
        album: "",
        duration: 1,
        currentTime: 0,
        isPlaying: false,
        source: .auto,
        artworkImage: nil
    )
}

private struct PlayerSnapshot {
    let source: MediaSource
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let currentTime: TimeInterval
    let isPlaying: Bool
}

// MARK: - MediaManager

final class MediaManager: ObservableObject {
    static let shared = MediaManager()
    
    @Published var track: TrackInfo = .empty
    @Published var selectedSource: MediaSource = .auto
    @Published var availableSources: [MediaSource] = MediaSource.allCases
    @Published var nowPlayingAppName: String = ""
    @Published private(set) var mediaStatus = "Waiting for a supported player"
    
    private var timer: Timer?
    private var reportedAutomationDenials: Set<MediaSource> = []
    private var requestedAutomationSources: Set<MediaSource> = []
    
    private init() {
        DispatchQueue.main.async { [weak self] in
            self?.requestAutomationAccessIfNeeded()
        }
        startPolling()
    }
    
    // MARK: - Polling (backup for elapsed time updates)
    
    func startPolling() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.fetchNowPlaying()
        }
    }
    
    // MARK: - Fetch Now Playing
    
    private func fetchNowPlaying() {
        let sources = runningPlayerSources
        if sources == [.webMedia] {
            track = .empty
            nowPlayingAppName = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Browser"
            selectedSource = .webMedia
            mediaStatus = "Browser detected; macOS does not provide universal tab metadata or controls"
            return
        }
        requestAutomationAccessIfNeeded()
        let snapshots = sources.compactMap(fetchPlayerSnapshot)
        guard let snapshot = snapshots.first(where: \.isPlaying)
                ?? snapshots.first(where: { $0.source == track.source })
                ?? snapshots.first else {
            if sources.isEmpty {
                track = .empty
                nowPlayingAppName = ""
                selectedSource = .auto
                mediaStatus = "No supported player is running"
            } else if !sources.contains(track.source) {
                track = .empty
                nowPlayingAppName = ""
                selectedSource = .auto
                mediaStatus = "Player automation permission is required"
            }

            return
        }
        apply(snapshot)
    }

    private func requestAutomationAccessIfNeeded() {
        guard let source = runningPlayerSources.first,
              source == .spotify || source == .appleMusic,
              requestedAutomationSources.insert(source).inserted else {
            return
        }

        let application = source == .spotify ? "Spotify" : "Music"
        let script = """
        tell application "\(application)" to return name
        """
        var error: NSDictionary?
        _ = NSAppleScript(source: script)?.executeAndReturnError(&error)
        if let error, Self.isAutomationDenied(error) {
            mediaStatus = "Allow mynotch to control \(source.rawValue) in System Settings"
            showAutomationAlert(for: source)
        }
    }

    private func showAutomationAlert(for source: MediaSource) {
        let alert = NSAlert()
        alert.messageText = "Media control permission required"
        alert.informativeText = "Allow mynotch to control \(source.rawValue) in System Settings > Privacy & Security > Automation, then relaunch mynotch."
        alert.addButton(withTitle: "Open Automation Settings")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn {
            openAutomationSettings()
        }
    }

    private var runningPlayerSources: [MediaSource] {
        let runningBundleIDs = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        var sources: [MediaSource] = []
        if runningBundleIDs.contains("com.spotify.client") {
            sources.append(.spotify)
        }
        if runningBundleIDs.contains("com.apple.Music") {
            sources.append(.appleMusic)
        }
        if isFrontmostBrowser {
            sources.append(.webMedia)
        }
        guard let frontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return sources
        }
        if frontmostBundleID == "com.spotify.client", sources.contains(.spotify) {
            return [.spotify] + sources.filter { $0 != .spotify }
        }
        if frontmostBundleID == "com.apple.Music", sources.contains(.appleMusic) {
            return [.appleMusic] + sources.filter { $0 != .appleMusic }
        }
        if isFrontmostBrowser {
            return [.webMedia]
        }
        return sources
    }

    private var isFrontmostBrowser: Bool {
        guard let application = NSWorkspace.shared.frontmostApplication else {
            return false
        }
        let bundleID = application.bundleIdentifier?.lowercased() ?? ""
        let name = application.localizedName?.lowercased() ?? ""
        let knownBrowserIDs = [
            "com.apple.safari", "com.google.chrome", "org.mozilla.firefox",
            "com.brave.browser", "com.microsoft.edgemac", "com.operasoftware.operagx",
            "com.vivaldi.vivaldi", "company.thebrowser.browser", "company.thebrowser.dia",
            "com.kagi.orion"
        ]
        return knownBrowserIDs.contains(bundleID)
            || name.contains("browser")
            || name == "dia"
            || name == "arc"
    }

    private func fetchPlayerSnapshot(source: MediaSource) -> PlayerSnapshot? {
        let application: String
        switch source {
        case .spotify:
            application = "Spotify"
        case .appleMusic:
            application = "Music"
        case .webMedia:
            return nil
        default:
            return nil
        }

        let script = """
        tell application "\(application)"
            set stateText to (player state) as text
            if stateText is "stopped" then return "|||||stopped"
            return (name of current track) & tab & (artist of current track) & tab & (album of current track) & tab & (duration of current track) & tab & (player position) & tab & stateText
        end tell
        """
        var error: NSDictionary?
        guard let result = NSAppleScript(source: script)?
            .executeAndReturnError(&error).stringValue else {
            if let error {
                if Self.isAutomationDenied(error) {
                    mediaStatus = "Allow mynotch to control \(source.rawValue) in System Settings"
                    if reportedAutomationDenials.insert(source).inserted {
                        print("[MediaManager] \(source.rawValue) automation is not authorized. Enable it in System Settings > Privacy & Security > Automation.")
                    }
                } else {
                    mediaStatus = "\(source.rawValue) automation failed"
                    print("[MediaManager] \(source.rawValue) read failed: \(error)")
                }
            }
            return nil
        }

        let fields = result.components(separatedBy: "\t")
        guard fields.count >= 6,
              let duration = Double(fields[3]),
              let currentTime = Double(fields[4]),
              !fields[0].isEmpty else {
            mediaStatus = "\(source.rawValue) has no active track"
            return nil
        }

        let isPlaying = fields[5].lowercased() == "playing"
        return PlayerSnapshot(
            source: source,
            title: fields[0],
            artist: fields[1],
            album: fields[2],
            duration: source == .spotify ? duration / 1000 : duration,
            currentTime: currentTime,
            isPlaying: isPlaying
        )
    }

    private func apply(_ snapshot: PlayerSnapshot) {
        let duration = max(snapshot.duration, 1)
        track = TrackInfo(
            title: snapshot.title,
            artist: snapshot.artist.isEmpty ? "Unknown Artist" : snapshot.artist,
            album: snapshot.album,
            duration: duration,
            currentTime: min(max(snapshot.currentTime, 0), duration),
            isPlaying: snapshot.isPlaying,
            source: snapshot.source,
            artworkImage: track.source == snapshot.source ? track.artworkImage : nil
        )
        switch snapshot.source {
        case .spotify:
            nowPlayingAppName = "Spotify"
        case .appleMusic:
            nowPlayingAppName = "Apple Music"
        case .webMedia:
            nowPlayingAppName = snapshot.title
        case .auto:
            nowPlayingAppName = ""
        }
        selectedSource = snapshot.source
        reportedAutomationDenials.remove(snapshot.source)
        mediaStatus = snapshot.source == .webMedia
            ? "Browser detected; media metadata and controls are unavailable"
            : (snapshot.isPlaying ? "Playing in \(nowPlayingAppName)" : "Paused in \(nowPlayingAppName)")
    }
    
    // MARK: - Playback Controls

    func selectSource(_ source: MediaSource) {
        selectedSource = source
        HapticFeedback.lightTap()
        fetchNowPlaying()
    }

    func togglePlayPause() {
        HapticFeedback.lightTap()
        if let source = activeScriptableSource {
            runPlayerCommand("""
            tell application "\(source == .spotify ? "Spotify" : "Music")" to playpause
            """)
            refreshAfterCommand()
            return
        }
        refreshAfterCommand()
    }

    func nextTrack() {
        HapticFeedback.lightTap()
        if let source = activeScriptableSource {
            runPlayerCommand("""
            tell application "\(source == .spotify ? "Spotify" : "Music")" to next track
            """)
            refreshAfterCommand()
            return
        }
        refreshAfterCommand()
    }

    func previousTrack() {
        HapticFeedback.lightTap()
        if let source = activeScriptableSource {
            runPlayerCommand("""
            tell application "\(source == .spotify ? "Spotify" : "Music")" to previous track
            """)
            refreshAfterCommand()
            return
        }
        refreshAfterCommand()
    }

    func seek(to time: TimeInterval) {
        let targetTime = min(max(0, time), track.duration)
        if let source = activeScriptableSource {
            let application = source == .spotify ? "Spotify" : "Music"
            runPlayerCommand("""
            tell application "\(application)" to set player position to \(targetTime)
            """)
            track.currentTime = targetTime
            refreshAfterCommand()
            return
        }
    track.currentTime = targetTime
    }

    private var activeScriptableSource: MediaSource? {
        switch track.source {
        case .spotify, .appleMusic:
            return runningPlayerSources.contains(track.source) ? track.source : nil
        default:
            return nil
        }
    }

    private func runPlayerCommand(_ source: String) {
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error {
            if Self.isAutomationDenied(error) {
                mediaStatus = "Allow player automation in System Settings"
            } else {
                print("[MediaManager] Player command failed: \(error)")
            }
        }
    }

    func openAutomationSettings() {
        guard let settingsURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.systempreferences"),
              NSWorkspace.shared.open(settingsURL) else {
            mediaStatus = "Open System Settings > Privacy & Security > Automation"
            return
        }
    }

    private static func isAutomationDenied(_ error: NSDictionary) -> Bool {
        (error[NSAppleScript.errorNumber] as? NSNumber)?.intValue == -1743
            || (error[NSAppleScript.errorNumber] as? Int) == -1743
    }

    private func refreshAfterCommand() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.fetchNowPlaying()
        }
    }

    deinit {
        timer?.invalidate()
    }
}
