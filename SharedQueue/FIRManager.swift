//
//  FIRManager.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import Foundation
import FirebaseAuth
import Network
import Starscream

class FIRManager: ObservableObject {
    @Published var currentUser: SQUser?
    @Published var groups: [SQGroup] = []
    @Published var connectedGroup: SQGroup?
    @Published var connectedToGroup = false
    var setupQueue = false
    var env = ServerID.beta
    var baseURL: String
    var baseWSURL: String
    static var shared = FIRManager()
    var socket: WebSocket?
    init() {
        baseURL = "http://\(env.rawValue)"
        baseWSURL = "ws://\(env.rawValue)"
        Auth.auth().addStateDidChangeListener { auth, user in
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
                    //TODO add server endpoint: fetch-groups
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
        userRequest.httpBody = try! JSONEncoder().encode(UpdateGroupRequest(myUID: self.currentUser!.id, group: group))
        print("sending \(userRequest.httpBody) to server")
        do {
            let (data, _) = try await URLSession.shared.data(for: userRequest)
            if String(data: data, encoding: .utf8) == "Success!" {
                await self.refreshData()
                return true
            } else {
                print(String(data: data, encoding: .utf8))
            }
        } catch {
            print(error)
        }
        return false
    }
    func joinGroup(_ group: SQGroup) async {
        print("joinging group \(group.name)")
        await musicService.registerStateListeners()
        let socketURL = URL(string: "\(baseWSURL)/group/\(self.currentUser!.id)/\(group.id)")!
        socket = WebSocket(request: URLRequest(url: socketURL))
        socket!.delegate = self
        connectedGroup = group
        
        socket!.connect()
    }
    func addGroup(_ groupID: String, _ groupURLID: String) async -> Bool {
        var userRequest = URLRequest(url: URL(string: "\(baseURL)/add-group/\(groupID)/\(groupURLID)")!)
        print(userRequest.url)
        userRequest.httpMethod = "POST"
        userRequest.httpBody = try! JSONEncoder().encode(AddGroupRequest(myUID: self.currentUser!.id))
        do {
            let (data, _) = try await URLSession.shared.data(for: userRequest)
            print(String(data: data, encoding: .utf8))
            if String(data: data, encoding: .utf8) == "Success!" {
                await self.refreshData()
                return true
            } else {
                print(String(data: data, encoding: .utf8))
            }
        } catch {
            print(error)
        }
        return false
    }
    func pauseSong() async {
        if let socket = socket {
            
            let jsonData = try? JSONEncoder().encode(WSMessage(type: .pause, data: "hi!!!".data(using: .utf8)!, sentAt: Date()))
            if let jsonData = jsonData {
                print("sending to socket \(socket.request.url)", jsonData)
                
                socket.write(data: jsonData) {
                    self.connectedGroup?.playbackState?.state = .pause
                }
                
            } else {
                print("jsondata fucked")
                socket.disconnect()
            }
        }
        Task {
            await musicService.pauseSong()
        }
    }
    func playSong() async {
        if let socket = socket {
            let jsonData = try? JSONEncoder().encode(WSMessage(type: .play, data: "hi!!!".data(using: .utf8)!, sentAt: Date()))
            if let jsonData = jsonData {
                socket.write(data: jsonData) {
                    self.connectedGroup?.playbackState?.state = .play
                }
            } else {
                print("jsondata fucked")
                socket.disconnect()
            }
        }
        Task {
            await musicService.playSong(song: connectedGroup!.currentlyPlaying!)
            await musicService.playAt(timestamp: connectedGroup!.playbackState!.timestamp)
        }
    }
    func nextSong() async {
        if let socket = socket {
            let jsonData = try? JSONEncoder().encode(WSMessage(type: .nextSong, data: "hi!!!".data(using: .utf8)!, sentAt: Date()))
            if let jsonData = jsonData {
                socket.write(data: jsonData)
            } else {
                print("jsondata fucked")
                socket.disconnect()
            }
        }
    }
    func addToQueue(song: SQSong) async {
        if let socket = socket {
            let jsonData = try? JSONEncoder().encode(WSMessage(type: .addToQueue, data: try! JSONEncoder().encode(SQQueueItem(song: song, addedBy: currentUser!.username)), sentAt: Date()))
            if let jsonData = jsonData {
                socket.write(data: jsonData)
            } else {
                print("jsondata fucked")
                socket.disconnect()
            }
        }
    }
}

extension FIRManager: WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
        switch (event) {
            
        case .connected(_):
            print("Connected")
            connectedToGroup = true
            Task {
                print("lfdjljl;f")
                await musicService.playSong(song: (connectedGroup?.currentlyPlaying!)!)
                client.write(data: try! JSONEncoder().encode(WSMessage(type: .playbackStarted, data: try! JSONEncoder().encode(WSPlaybackStartedMessage(startedAt: Date())), sentAt: Date())))
            }
        case .disconnected(let str, let int):
            print("Disconnected \(str) \(int)")
            Task {
                await musicService.stopPlayback()
            }
            connectedToGroup = false
        case .text(let txt):
            print("text \(txt)")
            
        case .binary(let data):
            print("binary \(data)")
            let wsMessage = try! JSONDecoder().decode(WSMessage.self, from: data)
            switch wsMessage.type {
            case .groupUpdate:
                let groupJSON = try! JSONDecoder().decode(SQGroup.self, from: wsMessage.data)
                if groupJSON.playbackState?.state == .pause {
                    Task {
                        await musicService.pauseSong()
                    }
                }
                Task {
                    var queue = [SQSong]()
                    for item in groupJSON.previewQueue {
                        queue.append(item.song)
                    }
                    await musicService.addQueue(queue: queue)
                }
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                    self.connectedGroup = groupJSON
                }
            case .timestampUpdate:
                
                
                Task {
                    let timestampUpdateInfo = try! JSONDecoder().decode(WSTimestampUpdate.self, from: wsMessage.data)
                    var delay = Date().timeIntervalSince(timestampUpdateInfo.sentAt)
                    print(delay)
                    var timestampDelay = await musicService.getSongTimestamp() - (timestampUpdateInfo.timestamp + delay)
                    print(timestampDelay)
                    if !(timestampDelay <= 1 && timestampDelay >= -1) {
                        print(timestampUpdateInfo.timestamp)
                        await musicService.playAt(timestamp: timestampUpdateInfo.timestamp + delay)
                    }
                }
            case .nextSong:
                Task {
                    await musicService.playSong(song: connectedGroup!.currentlyPlaying!)
                    var delay = Date().timeIntervalSince(wsMessage.sentAt)
                    await musicService.playAt(timestamp: delay)
                }
            case .goBack:
                Task {
                    await musicService.prevSong()
                }
            case .play:
                Task {
                    await musicService.playSong(song: connectedGroup!.currentlyPlaying!)
                    await musicService.playAt(timestamp: connectedGroup!.playbackState!.timestamp)
                }
            case .pause:
                Task {
                    await musicService.pauseSong()
                }
            default:
                break;
            }
        case .pong(_):
            print("pong")
        case .ping(_):
            print("ping")
        case .error(let err):
            print("error: \(err)")
            connectedToGroup = false
        case .viabilityChanged(_):
            print("viability changed")
        case .reconnectSuggested(_):
            print("reconnect suggested")
        case .cancelled:
            print("cancelled")
            Task {
                await musicService.stopPlayback()
            }
            connectedToGroup = false
        case .peerClosed:
            print("peer closed :(")
            Task {
                await musicService.stopPlayback()
            }
            connectedToGroup = false
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

struct WSMessage: Codable {
    var type: WSMessageType
    var data: Data
    var sentAt: Date
}

enum WSMessageType: Codable {
    case groupUpdate
    case nextSong
    case goBack
    case play
    case pause
    case timestampUpdate
    case playbackStarted
    case seekTo
    case addToQueue
}
struct AddGroupRequest: Codable {
    var myUID: String
}

struct WSPlaybackStartedMessage: Codable {
    var startedAt: Date
}
struct WSTimestampUpdate: Codable {
    var timestamp: TimeInterval
    var sentAt: Date
}
