//
//  SPTManager.swift
//  Git for Playlists
//
//  Created by Payton Curry on 9/30/23.
//

import Foundation
import SpotifyWebAPI
import Combine
import UIKit
import SpotifyiOS
class SpotifyAuthService: ObservableObject {
    var authManager = AuthorizationCodeFlowManager(clientId: "c0e41c631040467aa1299f4fdeb23dc0", clientSecret: "8685667f69dd4e2ea849e646f1f752a5")
    var spotify = SpotifyAPI(authorizationManager: AuthorizationCodeFlowManager(clientId: "c0e41c631040467aa1299f4fdeb23dc0", clientSecret: "8685667f69dd4e2ea849e646f1f752a5"))
    var cancellables: Set<AnyCancellable> = []
    static var shared = SpotifyAuthService()
    @Published var ready = false
    var signedIn: Bool
    init() {
        
        if UserDefaults.standard.value(forKey: "authManager") != nil {
            let data = UserDefaults.standard.value(forKey: "authManager")
            var authMan: AuthorizationCodeFlowManager
            do {
                authMan = try JSONDecoder().decode(AuthorizationCodeFlowManager.self, from: data as! Data)
            } catch {
                authMan = AuthorizationCodeFlowManager(clientId: "c0e41c631040467aa1299f4fdeb23dc0", clientSecret: "8685667f69dd4e2ea849e646f1f752a5")
            }
            self.signedIn = false
            spotify.authorizationManager = authMan
            spotify.authorizationManager.refreshTokens(onlyIfExpired: true).sink { comp in
                switch comp {
                case let .failure(err):
                    Logtool.shared.log("[MusicController] error refreshing spotify tokens: \(err)", .error)
                case .finished:
                    Logtool.shared.log("[MusicController] successfully refreshed spotify tokens")
                }
            } receiveValue: { _ in
                self.signedIn = self.spotify.authorizationManager.isAuthorized()
                self.ready = true
                print("set auth status sptmanager bool signedin \(self.signedIn)")
            }.store(in: &cancellables)
            UserDefaults.standard.set(spotify.authorizationManager.isAuthorized(), forKey: "usesSpotify")
            
        } else {
            self.signedIn = false
        }
        
    }
    func openSpotifyAuth() {
        let codeVerifier = String.randomURLSafe(length: 128)
        let codeChallenge = String.makeCodeChallenge(codeVerifier: codeVerifier)
        let state = String.randomURLSafe(length: 128)

        //        let authURL = spotify.authorizationManager.makeAuthorizationURL(redirectURI: URL(string: "https://pll.paytondev.cloud")!, codeChallenge: codeChallenge, state: state, scopes: [
        //            .playlistReadCollaborative,
        //            .playlistReadPrivate,
        //        ])
        let authURL = spotify.authorizationManager.makeAuthorizationURL(redirectURI: URL(string: "sq-sptauth://")!, showDialog: false, state: state, scopes: [
            .userLibraryRead,
            .userReadPlaybackState,
            .userModifyPlaybackState,
            .appRemoteControl,
            .streaming,
            .userReadRecentlyPlayed
        ])
        UserDefaults.standard.setValue(codeVerifier, forKey: "latestSpotifyVerifier")
        UserDefaults.standard.setValue(codeChallenge, forKey: "latestSpotifyChallenge")
        UserDefaults.standard.setValue(state, forKey: "latestSpotifyState")
        UIApplication.shared.open(authURL ?? URL(string: "https://spotify.com/404")!)
    }
}

struct SPTPlaylistResponse: Codable {
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [SPTSimplifiedPlaylistObject]
}

struct SPTSimplifiedPlaylistObject: Codable {
    var description: String?
    var href: String
    var id: String
    var images: [SPTImageObject]
    var name: String
    var owner: SPTOwnerObject
    var snapshot_id: String
    var tracks: SPTTracksRefObject
    var type: String
    var uri: String
}

struct SPTOwnerObject: Codable {
    var external_urls: SPTExternalURLSObject
    var followers: SPTFollowersObject?
    var href: String
    var id: String
    var type: String
    var uri: String
    var display_name: String?
}

struct SPTFollowersObject: Codable {
    var href: String?
    var total: Int
}

struct SPTExternalURLSObject: Codable {
    var spotify: String
}

struct SPTSavedTracksResponse: Codable {
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [SPTSavedTrackObject]
}

struct SPTSavedTrackObject: Codable {
    var added_at: String
    var track: SPTTrackObject
}

struct SPTImageObject: Codable {
    var url: String
    var height: Int?
    var width: Int?
}

struct SPTTracksRefObject: Codable {
    var href: String
    var total: Int
}

struct SPTPLTracksResponse: Codable {
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [SPTSavedTrackObject]
}

struct SPTPlaylistTrackObject: Codable {
    var added_at: String?
    var added_by: SPTOwnerObject?
    var is_local: Bool?
    var track: SPTTrackObject
}

struct SPTTrackObject: Codable {
    var album: SPTAlbumObject
    var artists: [SPTArtistObject]
    var available_markets: [String]
    var href: String
    var id: String
    var name: String
}

struct SPTAlbumObject: Codable {
    var images: [SPTImageObject]
}

struct SPTArtistObject: Codable {
    var external_urls: SPTExternalURLSObject
    var name: String
}
