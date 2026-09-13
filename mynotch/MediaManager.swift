//
//  MediaManager.swift
//  mynotch
//
//  Uses the private MediaRemote framework to get system-wide now-playing info.
//  Works with Spotify, Apple Music, YouTube (Safari/Chrome), and any other media app.
//

import Foundation
import AppKit
import Combine
import SwiftUI

// MARK: - MediaRemote Private Framework

// These are the private MediaRemote functions we use via dlsym.
// They work for all media sources system-wide — no AppleScript needed.
private let mediaRemoteBundle = CFBundleCreate(kCFAllocatorDefault,
    NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

private typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
private typealias MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
private typealias MRMediaRemoteSendCommandFunction = @convention(c) (UInt32, UnsafeMutableRawPointer?) -> Bool
private typealias MRMediaRemoteRegisterForNowPlayingNotificationsFunction = @convention(c) (DispatchQueue) -> Void
private typealias MRMediaRemoteGetNowPlayingClientFunction = @convention(c) (DispatchQueue, @escaping (AnyObject?) -> Void) -> Void

private func MRFunction<T>(_ name: String) -> T? {
    guard let bundle = mediaRemoteBundle else { return nil }
    guard let ptr = CFBundleGetFunctionPointerForName(bundle, name as CFString) else { return nil }
    return unsafeBitCast(ptr, to: T.self)
}

// MediaRemote command constants
private let kMRPlay: UInt32 = 0
private let kMRPause: UInt32 = 1
private let kMRTogglePlayPause: UInt32 = 2
private let kMRStop: UInt32 = 3
private let kMRNextTrack: UInt32 = 4
private let kMRPreviousTrack: UInt32 = 5

// MediaRemote info dictionary keys
private let kMRMediaRemoteNowPlayingInfoTitle = "kMRMediaRemoteNowPlayingInfoTitle"
private let kMRMediaRemoteNowPlayingInfoArtist = "kMRMediaRemoteNowPlayingInfoArtist"
private let kMRMediaRemoteNowPlayingInfoAlbum = "kMRMediaRemoteNowPlayingInfoAlbum"
private let kMRMediaRemoteNowPlayingInfoDuration = "kMRMediaRemoteNowPlayingInfoDuration"
private let kMRMediaRemoteNowPlayingInfoElapsedTime = "kMRMediaRemoteNowPlayingInfoElapsedTime"
private let kMRMediaRemoteNowPlayingInfoArtworkData = "kMRMediaRemoteNowPlayingInfoArtworkData"
private let kMRMediaRemoteNowPlayingInfoTimestamp = "kMRMediaRemoteNowPlayingInfoTimestamp"

// Notification names
private let kMRMediaRemoteNowPlayingInfoDidChangeNotification = NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification")
private let kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification = NSNotification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification")

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

// MARK: - MediaManager

final class MediaManager: ObservableObject {
    static let shared = MediaManager()
    
    @Published var track: TrackInfo = .empty
    @Published var selectedSource: MediaSource = .auto
    @Published var availableSources: [MediaSource] = MediaSource.allCases
    @Published var nowPlayingAppName: String = ""
    
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    
    private init() {
        registerForNotifications()
        fetchNowPlaying()
        startPolling()
    }
    
    // MARK: - Registration
    
    private func registerForNotifications() {
        // Register for MediaRemote notifications
        if let registerFn: MRMediaRemoteRegisterForNowPlayingNotificationsFunction = MRFunction("MRMediaRemoteRegisterForNowPlayingNotifications") {
            registerFn(DispatchQueue.main)
        }
        
        // Observe now playing info changes
        let infoObserver = NotificationCenter.default.addObserver(
            forName: kMRMediaRemoteNowPlayingInfoDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.fetchNowPlaying()
        }
        observers.append(infoObserver)
        
        // Observe play state changes
        let playObserver = NotificationCenter.default.addObserver(
            forName: kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.fetchPlayingState()
        }
        observers.append(playObserver)
    }
    
    // MARK: - Polling (backup for elapsed time updates)
    
    func startPolling() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.track.isPlaying && self.track.currentTime < self.track.duration {
                self.track.currentTime += 1.0
            }
        }
    }
    
    // MARK: - Fetch Now Playing via MediaRemote
    
    private func fetchNowPlaying() {
        guard let getNowPlayingInfo: MRMediaRemoteGetNowPlayingInfoFunction = MRFunction("MRMediaRemoteGetNowPlayingInfo") else {
            print("[MediaManager] Could not load MRMediaRemoteGetNowPlayingInfo")
            return
        }
        
        getNowPlayingInfo(DispatchQueue.main) { [weak self] info in
            guard let self = self else { return }
            
            let title = info[kMRMediaRemoteNowPlayingInfoTitle] as? String ?? ""
            let artist = info[kMRMediaRemoteNowPlayingInfoArtist] as? String ?? ""
            let album = info[kMRMediaRemoteNowPlayingInfoAlbum] as? String ?? ""
            let duration = info[kMRMediaRemoteNowPlayingInfoDuration] as? Double ?? 0
            let elapsed = info[kMRMediaRemoteNowPlayingInfoElapsedTime] as? Double ?? 0
            
            var artwork: NSImage? = nil
            if let artworkData = info[kMRMediaRemoteNowPlayingInfoArtworkData] as? Data {
                artwork = NSImage(data: artworkData)
            }
            
            // Only update if we have real data
            if !title.isEmpty {
                self.track.title = title
                self.track.artist = artist.isEmpty ? "Unknown Artist" : artist
                self.track.album = album
                self.track.duration = max(duration, 1)
                self.track.currentTime = elapsed
                self.track.artworkImage = artwork
                self.track.source = self.detectSource()
            }
        }
        
        fetchPlayingState()
        fetchNowPlayingApp()
    }
    
    private func fetchPlayingState() {
        guard let getIsPlaying: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction = MRFunction("MRMediaRemoteGetNowPlayingApplicationIsPlaying") else {
            return
        }
        
        getIsPlaying(DispatchQueue.main) { [weak self] isPlaying in
            self?.track.isPlaying = isPlaying
        }
    }
    
    private func fetchNowPlayingApp() {
        guard let getClient: MRMediaRemoteGetNowPlayingClientFunction = MRFunction("MRMediaRemoteGetNowPlayingClient") else {
            return
        }
        
        getClient(DispatchQueue.main) { [weak self] client in
            if let client = client {
                // Try to get the app name from the client object
                let appName = (client as AnyObject).value(forKey: "displayName") as? String ?? ""
                self?.nowPlayingAppName = appName
            }
        }
    }
    
    private func detectSource() -> MediaSource {
        let appName = nowPlayingAppName.lowercased()
        if appName.contains("spotify") { return .spotify }
        if appName.contains("music") { return .appleMusic }
        if appName.contains("safari") || appName.contains("chrome") || appName.contains("firefox") { return .webMedia }
        return .auto
    }
    
    // MARK: - Playback Controls (via MediaRemote commands)
    
    func selectSource(_ source: MediaSource) {
        selectedSource = source
        HapticFeedback.lightTap()
        fetchNowPlaying()
    }
    
    func togglePlayPause() {
        HapticFeedback.lightTap()
        sendCommand(kMRTogglePlayPause)
        // Optimistically toggle
        track.isPlaying.toggle()
    }
    
    func nextTrack() {
        HapticFeedback.lightTap()
        sendCommand(kMRNextTrack)
        // Fetch updated info after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.fetchNowPlaying()
        }
    }
    
    func previousTrack() {
        HapticFeedback.lightTap()
        sendCommand(kMRPreviousTrack)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.fetchNowPlaying()
        }
    }
    
    func seek(to time: TimeInterval) {
        track.currentTime = min(max(0, time), track.duration)
    }
    
    private func sendCommand(_ command: UInt32) {
        guard let sendCmd: MRMediaRemoteSendCommandFunction = MRFunction("MRMediaRemoteSendCommand") else {
            print("[MediaManager] Could not load MRMediaRemoteSendCommand")
            return
        }
        _ = sendCmd(command, nil)
    }
    
    deinit {
        timer?.invalidate()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
