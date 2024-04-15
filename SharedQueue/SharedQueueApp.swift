//
//  SharedQueueApp.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import SwiftUI
import GoogleSignIn
import Combine
import SpotifyiOS

var musicService: any MusicService = AppleMusicService()
@main
struct SharedQueueApp: App {
    
    @ObservedObject var firManager: FIRManager
    @State private var cancellables: Set<AnyCancellable> = []
    
    init() {
        firManager = FIRManager.shared
        if UserDefaults.standard.bool(forKey: "usesSpotify") {
            print("uses spotify")
            musicService = SpotifyService()
        } else {
            musicService = AppleMusicService()
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView().onOpenURL(perform: { url in
                if !GIDSignIn.sharedInstance.handle(url) {
                    //its a SharedQ or spt URL.
                    
                    if !url.absoluteString.contains("code") && url.absoluteString.contains("spt") {
                        if let sptService = musicService as? SpotifyService {
                            let params = sptService.appRemote.authorizationParameters(from: url)
                            sptService.appRemote = {
                                let appRemote = SPTAppRemote(configuration: SPTConfiguration(
                                    clientID: "c0e41c631040467aa1299f4fdeb23dc0",
                                    redirectURL: URL(string: "sq-sptauth://")!
                                  ), logLevel: .debug)
                                appRemote.connectionParameters.accessToken = params?[SPTAppRemoteAccessTokenKey]
                              appRemote.delegate = sptService
                              return appRemote
                            }()
                            
                        }
                        
                    } else if url.absoluteString.contains("code") && url.absoluteString.contains("spt") {
                        Task { @MainActor in
                            var sptmngr = SpotifyAuthService.shared
                            sptmngr.spotify.authorizationManager.requestAccessAndRefreshTokens(redirectURIWithQuery: URL(string: url.absoluteString)!, state: UserDefaults.standard.string(forKey: "latestSpotifyState")!).sink(receiveCompletion: { completion in
                                if case let .failure(error) = completion {
                                    UserDefaults.standard.set(false, forKey: "usesSpotify")
                                    print("couldn't retrieve access and refresh tokens:\n\(error)")
                                }
                            })
                            .store(in: &cancellables)
                        }
                    } else if url.pathComponents.count >= 3 {
                        print(url, url.pathComponents)
                        let groupID = url.pathComponents[1]
                        let groupURLID = url.pathComponents[2]
                        Task {
                            print("sending request")
                            _ = await firManager.addGroup(groupID, groupURLID)
                        }
                    }
                }
            }).environmentObject(firManager).environmentObject(SpotifyAuthService()).onReceive(SpotifyAuthService.shared.spotify.authorizationManagerDidChange, perform: { _ in
                print("authman changed")
                UserDefaults.standard.setValue(try! JSONEncoder().encode(SpotifyAuthService.shared.spotify.authorizationManager), forKey: "authManager")
                
                
                musicService = SpotifyService()
                UserDefaults.standard.set(true, forKey: "usesSpotify")
            })
        }
    }
}

extension View {
    func getRootViewController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .init()
        }

        guard let root = screen.windows.first?.rootViewController else {
            return .init()
        }
        

        return root
    }
}
