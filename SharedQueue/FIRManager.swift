//
//  FIRManager.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import Foundation
import Network
import SharedQSync
import SharedQProtocol

class FIRManager: ObservableObject {
    @Published var currentUser: SQUser?
    @Published var connectedGroup: SQGroup?
    @Published var connectedToGroup = false
    @Published var loaded = false
    var authToken: String?
    var syncManager: SharedQSyncManager
    var setupQueue = false
    var env = ServerID.superDev
    var baseURL: String
    var baseWSURL: String
    static var shared = FIRManager()
    init() {
        baseURL = "http://\(env.rawValue)"
        baseWSURL = "ws://\(env.rawValue)"
        syncManager = SharedQSyncManager(serverURL: URL(string: baseURL)!, websocketURL: URL(string: baseWSURL)!)
        syncManager.delegate = self
        authToken = UserDefaults.standard.string(forKey: "auth_token")
        Task {
            await self.refreshData()
        }
    }

    func refreshData() async {
        print("refresh")
        if let authToken = authToken {
            var userRequest = URLRequest(url: URL(string: "\(baseURL)/users/fetch-user")!)
            userRequest.httpMethod = "GET"
//            userRequest.httpBody = try! JSONEncoder().encode(FetchUserRequest(uid: Auth.auth().currentUser!.uid))
            userRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            print(userRequest.allHTTPHeaderFields)
            do {
                let (data, _) = try await URLSession.shared.data(for: userRequest)
                if let user = try? JSONDecoder().decode(SQUser.self, from: data) {
                    DispatchQueue.main.async {
                        self.currentUser = user
                        print(self.currentUser?.username)
                        self.loaded = true
                    }
                } else {
                    print(String(data: data, encoding: .utf8))
                    if String(data: data, encoding: .utf8) == "That user could not be found." {
                        UserDefaults.standard.set(false, forKey: "accountCreated")
                        UserDefaults.standard.set(false, forKey: "accountSetup")
                        UserDefaults.standard.set(false, forKey: "completedOnboarding")
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    

    func createGroup(_ group: SQGroup) async -> Bool {
        var userRequest = URLRequest(url: URL(string: "\(baseURL)/groups/create")!)
        userRequest.httpMethod = "POST"
        userRequest.setValue("Bearer \(authToken ?? "unauth'd")", forHTTPHeaderField: "Authorization")
        print(userRequest.allHTTPHeaderFields)
        userRequest.httpBody = try! JSONEncoder().encode(group)
        do {
            let (data, res) = try await URLSession.shared.data(for: userRequest)
            if let http = res.http {
                return 200...299 ~= http.statusCode
            }
        } catch {
            print(error)
        }
        return false
    }
    
    func signUp(username: String, email: String, password: String) async -> Bool {
        var userRequest = URLRequest(url: URL(string: "\(baseURL)/users/signup")!)
        userRequest.httpMethod = "POST"
        userRequest.httpBody = try? JSONEncoder().encode(UserSignup(email: email, username: username, password: password))
        do {
            let (data, _) = try await URLSession.shared.data(for: userRequest)
//            if String(data: data, encoding: .utf8) == "Success!" || String(data: data, encoding: .utf8) == "User already exists!" {
//                return true
//            } else {
//                print("respose from create: \(String(data: data, encoding: .utf8))")
//            }
            if let tokenResponse = try? JSONDecoder().decode(NewSession.self, from: data) {
                print(tokenResponse.token)
                UserDefaults.standard.setValue(tokenResponse.token, forKey: "auth_token")
                DispatchQueue.main.async {
                    self.currentUser = tokenResponse.user
                    self.authToken = tokenResponse.token
                }
                return true
            }
        } catch {
            print(error)
        }
        return false
    }

    func updateGroup(_ group: SQGroup) async -> Bool {
        var userRequest = URLRequest(url: URL(string: "\(baseURL)/groups/update")!)
        userRequest.httpMethod = "PUT"
        userRequest.httpBody = try! JSONEncoder().encode(group)
        userRequest.setValue("Bearer \(authToken ?? "unauth'd")", forHTTPHeaderField: "Authorization")
        print("sending \(userRequest.httpBody) to server")
        do {
            let (data, res) = try await URLSession.shared.data(for: userRequest)
            if let http = res.http {
                if 200...299 ~= http.statusCode {
                 await refreshData()
                    return true
                }
            }
        } catch {
            print(error)
        }
        return false
    }

    func addGroup(_ groupID: String, _ groupURLID: String) async -> Bool {
        var userRequest = URLRequest(url: URL(string: "\(baseURL)/groups/add-group/\(groupID)/\(groupURLID)")!)
        print(userRequest.url)
        if currentUser == nil {
            await refreshData()
        }
        userRequest.setValue("Bearer \(authToken ?? "unauth'd")", forHTTPHeaderField: "Authorization")
        userRequest.httpMethod = "PUT"
        userRequest.httpBody = try! JSONEncoder().encode(AddGroupRequest(myUID: currentUser!.id))
        do {
            let (data, res) = try await URLSession.shared.data(for: userRequest)
            print(String(data: data, encoding: .utf8))
            if let http = res.http {
                await refreshData()
                return 200...299 ~= http.statusCode
            }
        } catch {
            print(error)
        }
        return false
    }
}

extension FIRManager: SharedQSyncDelegate {
    func onDisconnect() {
        Task {
            await musicService.stopPlayback()
        }
        connectedToGroup = false
    }

    func onGroupConnect(_ group: SQGroup) {
        connectedToGroup = true
        self.connectedGroup = group
        Task {
            await musicService.playSong(song: connectedGroup!.currentlyPlaying!)
        }
    }

    func onGroupUpdate(_ group: SQGroup, _ message: WSMessage) {
        print("group update")
//        self.connectedGroup = group
        DispatchQueue.main.async {
            self.objectWillChange.send()
            self.connectedGroup = group
        }
        if group.playbackState!.state == .pause {
            Task {
                await musicService.pauseSong()
            }
        }
        Task {
            var queue = [SQSong]()
            for item in group.previewQueue {
                queue.append(item.song)
            }
            await musicService.addQueue(queue: queue)
        }
    }

    func onNextSong(_ message: WSMessage) {
        Task {
            await musicService.playSong(song: connectedGroup!.currentlyPlaying!)
            var delay = Date().timeIntervalSince(message.sentAt)
            await musicService.playAt(timestamp: delay)
        }
    }

    func onPrevSong(_ message: WSMessage) {
        Task {
            await musicService.prevSong()
        }
    }

    func onPlay(_ message: WSMessage) {
        Task {
            await musicService.playSong(song: connectedGroup!.currentlyPlaying!)
            await musicService.playAt(timestamp: connectedGroup!.playbackState!.timestamp)
        }
        self.connectedGroup!.playbackState?.state = .play
    }

    func onPause(_ message: WSMessage) {
        print("paused at \(message.sentAt)")
        Task {
            await musicService.pauseSong()
        }
        self.connectedGroup!.playbackState?.state = .pause
    }

    func onTimestampUpdate(_ timestamp: TimeInterval, _ message: WSMessage) {
        Task {
            var delay = Date().timeIntervalSince(message.sentAt)
            print(delay)
            var timestampDelay = await musicService.getSongTimestamp() - (timestamp + delay)
            print(timestampDelay)
            if !(timestampDelay <= 1 && timestampDelay >= -1) {
                print(timestamp)
                await musicService.playAt(timestamp: timestamp + delay)
            }
        }
    }

    func onSeekTo(_ timestamp: TimeInterval, _ message: WSMessage) {
        Task {
            await musicService.seekTo(timestamp: timestamp)
        }
    }
}

enum ServerID: String {
    case superDev = "192.168.68.121:8080"
    case beta = "sq.paytondev.cloud:8080"
}

extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}

extension Array where Element == UInt8 {
    var data: Data {
        return Data(self)
    }
}

extension URLResponse {
    /// Returns casted `HTTPURLResponse`
    var http: HTTPURLResponse? {
        return self as? HTTPURLResponse
    }
}
