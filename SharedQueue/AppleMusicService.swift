//
//  AppleMusicService.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import Foundation
import MusadoraKit
import FirebaseStorage
import SwiftUI
import SwiftVibrant
import MusicKit
import SharedQProtocol
class AppleMusicService: MusicService {
    func registerStateListeners() async {
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                switch ApplicationMusicPlayer.shared.state.playbackStatus {
                case .stopped:
                    if let group = FIRManager.shared.connectedGroup {
                        if group.playbackState?.state == .play {
                            Task {
                                try? await FIRManager.shared.syncManager.pauseSong()
                                
                            }
                        }
                    }
                case .playing:
                    if let group = FIRManager.shared.connectedGroup {
                        if group.playbackState?.state == .pause {
                            Task {
                                try? await FIRManager.shared.syncManager.playSong()
                            }
                        }
                    }
                case .paused:
                    if let group = FIRManager.shared.connectedGroup {
                        if group.playbackState?.state == .play {
                            Task {
                                try? await FIRManager.shared.syncManager.pauseSong()
                            }
                        }
                    }
                case .interrupted:
                    if let group = FIRManager.shared.connectedGroup {
                        if group.playbackState?.state == .play {
                            Task {
                                try? await FIRManager.shared.syncManager.pauseSong()
                            }
                        }
                    }
                case .seekingForward:
                    break;
                case .seekingBackward:
                    break;
                }
            }
        }
    }
    
    func getMostRecentSong() async -> SQSong? {
        let songs = try? await MLibrary.recentlyPlayedSongs(offset: 0)
        if let songs = songs, !songs.isEmpty {
            var song = songs[0]
            var sqSong = await songToSQSong(song)
            return sqSong
        }
        return nil
    }
    func recentlyPlayed() async -> [SQSong] {
        do {
            let recents = try await MLibrary.recentlyPlayedSongs(offset: 0)
            var returnVal = [SQSong]()
            for song in recents {
                print(song.title)
                if let sqSong = await songToSQSong(song) {
                    returnVal.append(sqSong)
                }
            }
            return returnVal
        } catch {
            
        }
        return []
    }
    func songToSQSong(_ song: Song) async -> SQSong? {
        var sqSong = SQSong(title: song.title, artist: song.artistName, duration: song.duration!)
        var songsFromStore = try? await MCatalog.searchSongs(for: "\(song.title) \(song.artistName) \(song.albumTitle ?? "")")
        if let songsFromStore = songsFromStore, !songsFromStore.isEmpty {
            let songFromStore = songsFromStore[0]
            let artwork = songFromStore.artwork
            sqSong.albumArt = artwork?.url(width: 512, height: 512)
            do {
                let (data, _) = try await URLSession.shared.data(from: sqSong.albumArt!)
                print(data)
                let uiImage = UIImage(data: data)
                if let uiImage = uiImage {
                    let palette = Vibrant.from(uiImage).getPalette()
                    print(palette)
                    let vibrant = palette.Vibrant!.uiColor.toHex()!
                    let darkVibrant = palette.DarkVibrant!.uiColor.toHex()!
                    
                    sqSong.colors = [vibrant, darkVibrant]
                }
            } catch {
                
            }
        }
        return sqSong
    }
    func sqSongToSong(_ song: SQSong) async -> Song? {
        do {
            
            var appleMusicSong = try await MLibrary.searchSongs(for: "\(song.title) \(song.artist)")
            if appleMusicSong.isEmpty {
                appleMusicSong = try await MCatalog.searchSongs(for: "\(song.title) \(song.artist)")
            }
            return appleMusicSong[0]
        } catch {
            print(error)
        }
        return nil
    }
    func playSong(song: SQSong) async {
        do {
            let appleMusicSong = await sqSongToSong(song)
//            try await ApplicationMusicPlayer.shared.prepareToPlay()
            try await ApplicationMusicPlayer.shared.play(song: appleMusicSong!)
            
        } catch {
            print("error playing song: \(error)")
        }
    }
    func playAt(timestamp: TimeInterval) async {
        ApplicationMusicPlayer.shared.playbackTime = timestamp
    }
    func getSongTimestamp() async -> TimeInterval {
            return ApplicationMusicPlayer.shared.playbackTime
    }
    func stopPlayback() async {
        ApplicationMusicPlayer.shared.stop()
    }
    func addQueue(queue: [SQSong]) async {
//        var queue1 = queue
//        for index in queue1.indices {
//            if index == 0 {
//                continue
//            }
//            queue1[index - 1] = queue1[index]
//        }
//        var queue2 = queue1.reversed()
//        ApplicationMusicPlayer.shared.state.repeatMode = .none
//        ApplicationMusicPlayer.shared.queue = []
//        var amSongs: [Song] = []
//        for song in queue2 {
//            let amSong = await sqSongToSong(song)
//            amSongs.append(amSong!)
//        }
//        try! await ApplicationMusicPlayer.shared.queue.insert(amSongs.first, position: .afterCurrentEntry)
//        ApplicationMusicPlayer.shared.state.repeatMode = .one
    }
    func nextSong() async {
        try! await ApplicationMusicPlayer.shared.skipToNextEntry()
    }
    func pauseSong() async {
        print("pausing")
        ApplicationMusicPlayer.shared.pause()
    }
    func prevSong() async {
        try! await ApplicationMusicPlayer.shared.skipToPreviousEntry()
    }
    func seekTo(timestamp: TimeInterval) async {
        ApplicationMusicPlayer.shared.playbackTime = timestamp
    }
    func searchFor(_ query: String) async -> [SQSong] {
        do {
            let appleMusicSongs = try await MCatalog.searchSongs(for: query)
            var returnValue = [SQSong]()
            for song in appleMusicSongs {
                if let sqSong = await self.songToSQSong(song) {
                    returnValue.append(sqSong)
                }
            }
            return returnValue
        } catch {
            print(error)
        }
        return []
    }
}

extension SwiftUI.Color {
    func fromHex(_ hex: String) -> SwiftUI.Color? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return nil
        }

        return SwiftUI.Color(red: r, green: g, blue: b, opacity: a)
    
    }
}
extension SwiftUI.Color {
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}

extension UIColor {
    func toHex() -> String? {
        let uic = self
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
