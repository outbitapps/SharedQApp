//
//  SpotifyService.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/27/24.
//

import Foundation
import UIKit
import SwiftVibrant
import SpotifyiOS
import SharedQProtocol
class SpotifyService: NSObject, MusicService {
    @Published var notConnectedToSpotify = true
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: SPTConfiguration(
            clientID: "c0e41c631040467aa1299f4fdeb23dc0",
            redirectURL: URL(string: "sq-sptauth://")!
          ), logLevel: .debug)
        appRemote.connectionParameters.accessToken = SpotifyAuthService.shared.spotify.authorizationManager.accessToken
      appRemote.delegate = self
      return appRemote
    }()
    override required init() {
        super.init()
        print("connecting to spotify...")
        
    }
    func connectToSpotify() {
        self.appRemote.authorizeAndPlayURI("", asRadio: false, additionalScopes: [
            "user-library-read",
            "user-read-playback-state",
            "user-modify-playback-state",
            "user-read-playback-position",
            "user-read-recently-played",
            "user-library-read"
        ])
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            self.appRemote.connect()
        })
    }
    func getMostRecentSong() async -> SQSong? {
        let (data, err) = await self.sendRequestToAPI(endpoint: "https://api.spotify.com/v1/me/player/recently-played?limit=1", body: nil, type: "GET")
        do {
            if let data = data {
                let response = try JSONDecoder().decode(RecentlyPlayedResponse.self, from: data)
                print(response.items[0].track.name)
                return await self.trackToSQSong(track: response.items[0].track)
            } else {
                print("error fetching song: \(err) \(String(data: data ?? Data(), encoding: .utf8))")
            }
           
        } catch {
            print("error decoding response: \(error)")
        }
        
        return nil
    }
    
    func recentlyPlayed() async -> [SQSong] {
        var songs = [SQSong]()
        let (data, err) = await self.sendRequestToAPI(endpoint: "https://api.spotify.com/v1/me/player/recently-played?limit=50", body: nil, type: "GET")
        do {
            if let data = data {
                let response = try JSONDecoder().decode(RecentlyPlayedResponse.self, from: data)
                for track in response.items {
                    songs.append(await self.trackToSQSong(track: track.track))
                }
            } else {
                print("error fetching song: \(err) \(String(data: data ?? Data(), encoding: .utf8))")
            }
           
        } catch {
            print("error decoding response: \(error)")
        }
        return songs
    }
    
    func playSong(song: SQSong) async {
        print("playing song")
        if let track = await self.sqSongToTrack(sqSong: song), let api = appRemote.playerAPI {
            print("trackid \(track.id)")
            DispatchQueue.main.async {
                api.play("spotify:track:\(track.id)", asRadio: false) { thing, err in
                    print("thingy", thing, err)
                }
            }
        }
    }
    
    func playAt(timestamp: TimeInterval) async {
        if let api = appRemote.playerAPI {
            DispatchQueue.main.async {
                api.seek(toPosition: Int(timestamp * 1000))
            }
        }
    }
    
    func getSongTimestamp() async -> TimeInterval {
        if let api = appRemote.playerAPI {
            let state = await withCheckedContinuation { continuation in
                DispatchQueue.main.async {
                    api.getPlayerState { res, err in
                        continuation.resume(returning: res as! SPTAppRemotePlayerState)
                    }
                }
            }
            return TimeInterval(state.playbackPosition / 1000)
        }
        return 0
    }
    
    func searchFor(_ query: String) async -> [SQSong] {
        let (data, err) = await self.sendRequestToAPI(endpoint: "https://api.spotify.com/v1/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAndPathAllowed)!)&type=track", body: nil, type: "GET")
        if let data = data  {
            do {
                let response = try JSONDecoder().decode(SearchResponse.self, from: data)
                var returnValue = [SQSong]()
                for track in response.tracks.items {
                    returnValue.append(await self.trackToSQSong(track: track))
                }
                return returnValue
            } catch {
                print("error converting: \(error)")
            }
        }
        return []
    }
    
    func stopPlayback() async {
        if let api = appRemote.playerAPI {
            DispatchQueue.main.async {
                api.pause()
            }
        }
    }
    
    func nextSong() async {
        if let api = appRemote.playerAPI {
            DispatchQueue.main.async {
                api.skip(toNext: nil)
            }
        }
    }
    
    func addQueue(queue: [SQSong]) async {
        
    }
    
    func pauseSong() async {
        if let api = appRemote.playerAPI {
            DispatchQueue.main.async {
                api.pause()
            }
        }
    }
    
    func prevSong() async {
        
    }
    
    func seekTo(timestamp: TimeInterval) async {
        
    }
    func trackToSQSong(track: Track) async -> SQSong {
        var artistName = ""
        for index in track.artists.indices {
            let artist = track.artists[index]
            if index == track.artists.count - 1 {
                artistName.append(artist.name)
            } else if track.artists.count > 1 {
                artistName.append("\(artist.name) & ")
            } else {
                artistName.append(artist.name)
            }
        }
        var sqSong = SQSong(title: track.name, artist: artistName, duration: TimeInterval(track.duration_ms / 1000))
        var highestResImage: ImageObject? = nil
        for image in track.album.images {
            if let highestRes = highestResImage {
                if image.width > highestRes.width && image.height > highestRes.height {
                    highestResImage = image
                }
            } else {
                highestResImage = image
            }
        }
        
        if let highestResImage = highestResImage {
            sqSong.albumArt = URL(string: highestResImage.url)
            if let url =  URL(string: highestResImage.url) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
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
        }
        return sqSong
    }
    func sqSongToTrack(sqSong: SQSong) async -> Track? {
        let (data, err) = await self.sendRequestToAPI(endpoint: "https://api.spotify.com/v1/search?q=\("\(sqSong.title) \(sqSong.artist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAndPathAllowed)!)&type=track", body: nil, type: "GET")
//        print(String(data: data!, encoding: .utf8))
        if let data = data  {
            do {
                let response = try JSONDecoder().decode(SearchResponse.self, from: data)
                return response.tracks.items[0]
            } catch {
                print("error converting: \(error)")
            }
        }
        return nil
    }
    func sendRequestToAPI(endpoint: String, body: Data?, type: String = "POST") async -> (Data?, Error?) {
        var theURL = URL(string: endpoint)!
        let spotify = SpotifyAuthService.shared.spotify
        var urlSesh = URLRequest(url: theURL)
        
        urlSesh.addValue("Bearer \(self.appRemote.connectionParameters.accessToken ?? "abc")", forHTTPHeaderField: "Authorization")
        urlSesh.addValue("application/json", forHTTPHeaderField: "Accept")
        urlSesh.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlSesh.allowsConstrainedNetworkAccess = true
        urlSesh.allowsCellularAccess = true
        urlSesh.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        if type != "GET" {
            urlSesh.httpBody = body ?? Data()
        }
        urlSesh.httpMethod = type
        do {
            let (data, _) = try await URLSession.shared.data(for: urlSesh)
            return (data, nil)
        } catch {
            print("error with api call: \(error)")
            return (nil, error)
        }
    }
    func registerStateListeners() async {
        if let api = appRemote.playerAPI {
            print("registering state change")
            api.subscribe { state, err in
                print("state: \(state)")
            }
        } else {
            print("api nil")
        }
    }
    
}

extension SpotifyService: SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        self.appRemote = appRemote
        self.notConnectedToSpotify = false
      print("connected to spotify app")
    }
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
      print("disconnected: \(error)")
        self.notConnectedToSpotify = true
        self.appRemote = appRemote
    }
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
      print("failed \(error)")
        self.notConnectedToSpotify = true
        self.appRemote = appRemote
    }
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
      print("player state changed")
        self.appRemote = appRemote
    }
    
   
    
}


struct RecentlyPlayedRequest: Codable {
    var limit = 1
}

struct SearchResponse: Codable {
    var tracks: TrackObject
}
struct RecentlyPlayedResponse: Codable {
    var href: String
    var items: [PlayHistoryObject]
}
struct TrackObject: Codable {
    var items: [Track]
}

struct PlayHistoryObject: Codable {
    var track: Track
}

struct Track: Codable {
    var album: Album
    var artists: [ArtistObject]
    var name: String
    var href: String
    var duration_ms: Int
    var id: String
}

struct ArtistObject: Codable {
    var name: String
}

struct Album: Codable {
    var images: [ImageObject]
}


struct ImageObject: Codable {
    var url: String
    var width: Int
    var height: Int
}
