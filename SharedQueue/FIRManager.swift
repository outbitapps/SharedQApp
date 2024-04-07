//
//  FIRManager.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import FirebaseAuth
import Foundation
import Network
import SharedQSync
import Starscream
import SharedQProtocol

class FIRManager: ObservableObject {
    @Published var currentUser: SQUser?
    @Published var groups: [SQGroup] = []
    @Published var connectedGroup: SQGroup?
    @Published var connectedToGroup = false
    var syncManager: SharedQSyncManager
    var setupQueue = false
    var env = ServerID.beta
    var baseURL: String
    var baseWSURL: String
    static var shared = FIRManager()
    init() {
        baseURL = "http://\(env.rawValue)"
        baseWSURL = "ws://\(env.rawValue)"
        syncManager = SharedQSyncManager(serverURL: URL(string: baseURL)!, websocketURL: URL(string: baseWSURL)!)
        syncManager.delegate = self
        Auth.auth().addStateDidChangeListener { _, _ in
            Task {
                await self.refreshData()
            }
        }
    }

    func refreshData() async {
        print("refresh")
        DispatchQueue.main.async {
            self.groups = []
        }
        if Auth.auth().currentUser != nil {
            var userRequest = URLRequest(url: URL(string: "\(baseURL)/fetch-user")!)
            userRequest.httpMethod = "POST"
            userRequest.httpBody = try! JSONEncoder().encode(FetchUserRequest(uid: Auth.auth().currentUser!.uid))
            do {
                let (data, _) = try await URLSession.shared.data(for: userRequest)
                if let user = try? JSONDecoder().decode(SQUser.self, from: data) {
                    DispatchQueue.main.async {
                        self.currentUser = user
                        print(user.groups)
                    }
                    // TODO: add server endpoint: fetch-groups
                    for group in user.groups {
                        print(group)
                        var groupRequest = URLRequest(url: URL(string: "\(baseURL)/fetch-group")!)
                        groupRequest.httpMethod = "POST"
                        groupRequest.httpBody = try! JSONEncoder().encode(FetchGroupRequest(myUID: user.id, groupID: group))
                        let (groupData, _) = try await URLSession.shared.data(for: groupRequest)
//                        print(String(data: groupData, encoding: .utf8))
                        if let group = try? JSONDecoder().decode(SQGroup.self, from: groupData) {
                            DispatchQueue.main.async {
                                print(group.name)
                                self.groups.append(group)
                            }
                        }
                    }
                } else {
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
        var userRequest = URLRequest(url: URL(string: "\(baseURL)/create-group")!)
        userRequest.httpMethod = "POST"
        userRequest.httpBody = try! JSONEncoder().encode(group)
        do {
            let (data, _) = try await URLSession.shared.data(for: userRequest)
            if String(data: data, encoding: .utf8) == "Success!" {
                return true
            } else {
                print(String(data: data, encoding: .utf8))
            }
        } catch {
            print(error)
        }
        return false
    }

    func createUser(_ user: SQUser) async -> Bool {
        var userRequest = URLRequest(url: URL(string: "\(baseURL)/create-user")!)
        userRequest.httpMethod = "POST"
        userRequest.httpBody = try! JSONEncoder().encode(user)
        do {
            let (data, _) = try await URLSession.shared.data(for: userRequest)
            if String(data: data, encoding: .utf8) == "Success!" || String(data: data, encoding: .utf8) == "User already exists!" {
                return true
            } else {
                print("respose from create: \(String(data: data, encoding: .utf8))")
            }
        } catch {
            print(error)
        }
        return false
    }

    func updateGroup(_ group: SQGroup) async -> Bool {
        var userRequest = URLRequest(url: URL(string: "\(baseURL)/update-group")!)
        userRequest.httpMethod = "POST"
        userRequest.httpBody = try! JSONEncoder().encode(UpdateGroupRequest(myUID: currentUser!.id, group: group))
        print("sending \(userRequest.httpBody) to server")
        do {
            let (data, _) = try await URLSession.shared.data(for: userRequest)
            if String(data: data, encoding: .utf8) == "Success!" {
                await refreshData()
                return true
            } else {
                print(String(data: data, encoding: .utf8))
            }
        } catch {
            print(error)
        }
        return false
    }

    func addGroup(_ groupID: String, _ groupURLID: String) async -> Bool {
        var userRequest = URLRequest(url: URL(string: "\(baseURL)/add-group/\(groupID)/\(groupURLID)")!)
        print(userRequest.url)
        userRequest.httpMethod = "POST"
        userRequest.httpBody = try! JSONEncoder().encode(AddGroupRequest(myUID: currentUser!.id))
        do {
            let (data, _) = try await URLSession.shared.data(for: userRequest)
            print(String(data: data, encoding: .utf8))
            if String(data: data, encoding: .utf8) == "Success!" {
                await refreshData()
                return true
            } else {
                print(String(data: data, encoding: .utf8))
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

    func onGroupConnect() {
        connectedToGroup = true
        Task {
            await musicService.playSong(song: connectedGroup!.currentlyPlaying!)
        }
    }

    func onGroupUpdate(_ group: SQGroup, _ message: WSMessage) {
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
    }

    func onPause(_ message: WSMessage) {
        Task {
            await musicService.pauseSong()
        }
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

struct FetchUserRequest: Codable {
    var uid: String
}

struct FetchGroupRequest: Codable {
    var myUID: String
    var groupID: String
}

struct UpdateGroupRequest: Codable {
    var myUID: String
    var group: SQGroup
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

public struct AddGroupRequest: Codable {
    public var myUID: String
}
