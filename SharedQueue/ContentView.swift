//
//  ContentView.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import SwiftUI
import SwiftUIShakeGesture
import SharedQProtocol

struct ContentView: View {
    @AppStorage("completedOnboarding") var completedOnboarding = false
    @State var showingOnboarding = false
    @State var showingDevSettings = false
    @State var showingCreateView = false
    @EnvironmentObject var firManager: FIRManager
    @State var loading = false
    @State var groupBeingCreated: SQGroup?
    @State var showingCreatedView = false
    @State var showingSpotifySheet = false
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    if let currentUser = firManager.currentUser {
                        ForEach(currentUser.groups) { group in
                            NavigationLink {
                                ConfirmJoinView(group: group).navigationBarBackButtonHidden(true)
                            } label: {
                                HomeGroupCell(group: group)
                            }

                        }

                    }
                }.refreshable {
                    await firManager.refreshData()
                }
            }.fullScreenCover(isPresented: $showingOnboarding, onDismiss: {
                Task {
                    await firManager.refreshData()
                }
            }, content: {
                OnboardingAuth()
            }).onChange(of: completedOnboarding, initial: true) { oldValue, newValue in
                
                showingOnboarding = !completedOnboarding
                
            }.toolbar(content: {
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        if firManager.currentUser != nil {
                            showingCreateView.toggle()
                        }
                    
                    }, label: {
                        HStack {
                            Text("Groups").font(.largeTitle).fontWeight(.bold)
                            if firManager.currentUser != nil {
                                Image(systemName: "plus").foregroundStyle(.blue)
                            } else {
                                ProgressView()
                            }
                        }
                    }).buttonStyle(.plain)
                }
            }).onAppear {
                if firManager.authToken == nil && completedOnboarding {
                    UserDefaults.standard.set(false, forKey: "accountCreated")
                    UserDefaults.standard.set(false, forKey: "accountSetup")
                    completedOnboarding = false
                }
                if UserDefaults.standard.bool(forKey: "usesSpotify") {
                    showingSpotifySheet = true
                }
                
            }
        }.sheet(isPresented: $showingCreateView, onDismiss: {
            
            Task {
                if groupBeingCreated != nil {
                    loading = true
                    let recentSong = await musicService.getMostRecentSong()
                    groupBeingCreated?.currentlyPlaying = recentSong
    //                let recents = await musicService.getQueue()
    //                var queueItems = [SQQueueItem]()
    //                for recent in recents {
    //                    queueItems.append(SQQueueItem(song: recent, addedBy: "Payton"))
    //                }
    //                groupBeingCreated?.previewQueue = queueItems
                    _ = await firManager.updateGroup(groupBeingCreated!)
                    groupBeingCreated = firManager.currentUser?.groups.first(where: {$0.id == groupBeingCreated!.id})
                    loading = false
                    showingCreatedView = true
                }
            }
        } ,content: {
            CreateGroupView(groupBeingCreated: $groupBeingCreated).presentationDetents([.fraction(0.8), .large]).presentationCornerRadius(50)
        }).overlay {
            if loading {
                ZStack {
                    Rectangle().ignoresSafeArea().foregroundStyle(.black).opacity(0.8)
                    ProgressView()
                }
            }
        }.fullScreenCover(isPresented: $showingCreatedView, content: {
            GroupCreatedView(group: groupBeingCreated!)
        }).fullScreenCover(isPresented: $firManager.connectedToGroup) {
            GroupConnectedView()
        }.sheet(isPresented: $showingDevSettings, content: {
            DevSettings()
        }).onShake {
            showingDevSettings = true
        }.sheet(isPresented: $showingSpotifySheet, content: {
            SpotifyConnectionSheet().presentationDetents([.fraction(0.35)]).presentationCornerRadius(50).interactiveDismissDisabled()
        })
        

    }
}

struct DevSettings: View {
    @StateObject var firManager = FIRManager.shared
    @State var env: ServerID = .beta
    @State var serverVersion: String?
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Picker("Server env", selection: $env) {
                        Text("Dev").tag(ServerID.superDev)
                        Text("\"prod\"").tag(ServerID.beta)
                    }
                    if let serverVersion = serverVersion {
                        HStack {
                            Text("Server Version")
                            Spacer()
                            Text(serverVersion).foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            Text("Server Version")
                            Spacer()
                            ProgressView()
                        }
                    }
                }.navigationTitle("Dev Settings")
            }.onChange(of: env) { oldValue, newValue in
                firManager.env = newValue
                firManager.baseURL = "http://\(firManager.env.rawValue)"
                firManager.baseWSURL = "ws://\(firManager.env.rawValue)"
                firManager.syncManager.serverURL = URL(string: firManager.baseURL)!
                firManager.syncManager.websocketURL = URL(string: firManager.baseWSURL)!
                print(firManager.baseURL)
                Task {
                    self.serverVersion = await fetchServerVersion()
                }
            }.onAppear(perform: {
                env = firManager.env
                Task {
                    self.serverVersion = await fetchServerVersion()
                }
            })
        }
    }
    func fetchServerVersion() async -> String? {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "\(firManager.baseURL)/server-version")!)
            return String(data: data, encoding: .utf8)
        } catch {
            print("error getting server info: \(error)")
        }
        return nil
    }
}

struct HomeGroupCell: View {
    var group: SQGroup
    @EnvironmentObject var firManager: FIRManager
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(group.name).font(.title2).fontWeight(.semibold)
                Text("^[\(group.members.count) Members](inflect:true) ∙ \(group.connectedMembers.count) right now").foregroundStyle(.secondary)
                Text("Last used \(lastConnectedString()) ∙ \(group.publicGroup ? "Public Group" : "Private Group")").foregroundStyle(.secondary)
            }
            Spacer()
            if let currentSong = group.currentlyPlaying {
                AsyncImage(url: currentSong.albumArt) { img in
                    img.resizable().frame(width: 50, height: 50).cornerRadius(5.0)
                } placeholder: {
                    Image(.mediaItemPlaceholder).resizable().frame(width: 50, height: 50).cornerRadius(5.0)
                }

            }
        }
    }
    func lastConnectedString() -> String {
        var lastConnectedDate = group.members.first(where: {$0.user.id == firManager.currentUser!.id})?.lastConnected
        lastConnectedDate = Date().addingTimeInterval(-60*60*24*12)
        if let lastConnectedDate = lastConnectedDate {
            return lastConnectedDate.timeAgoDisplay()
        } else {
            return "Never"
        }
        
    }
}

struct CreateGroupView: View {
    @EnvironmentObject var firManager: FIRManager
    @State var groupName = ""
    @State var publicGroup = false
    @State var membersControlPlayback = true
    @State var membersAddToQueue = true
    @State var askToJoin = true
    @Environment(\.dismiss) var dismiss
    @Binding var groupBeingCreated: SQGroup?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    VStack {
                        Text("Create a Group").font(.title).bold()
                        Text("a group is a shared queue. you can make any type of group you want! anywhere from a massive, public group with hundreds of people at a time to a smaller, private group with a couple friends or some family. you can customize it however you’d like!").font(.subheadline).padding(.horizontal)
                    }
                    Spacer()
                }
                TextField("group name", text: $groupName).textFieldStyle(CoolTextfieldStyle()).padding(.vertical)
                HStack {
                    VStack(alignment: .leading) {
                        Text("Public Group").font(.title2).fontWeight(.semibold)
                        Text("In a public group, the group is visible to anyone and can be joined by anyone. Best for large communities").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle(isOn: $publicGroup, label: {
                    }).labelsHidden()
                }
                Text("Default Permissions").font(.title2).fontWeight(.semibold)
                HStack {
                    Text("Members can control playback").font(.subheadline).fontWeight(.medium)
                    Spacer()
                    Toggle(isOn: $membersControlPlayback, label: {
                        
                    }).labelsHidden()
                }
                HStack {
                    Text("Members can add to queue").font(.subheadline).fontWeight(.medium)
                    Spacer()
                    Toggle(isOn: $membersAddToQueue, label: {
                        
                    }).labelsHidden()
                }
                HStack {
                    VStack(alignment: .leading) {
                        Text("Ask to Join").font(.subheadline).fontWeight(.medium)
                        Text("With Ask to Join, your permission is needed before anyone can join. Best for small groups.").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle(isOn: $askToJoin, label: {
                        
                    }).labelsHidden()
                }
                GradientButton {
                    Task {
                        await createGroup()
                    }
                } label: {
                    Text("Create \(Image(systemName: "chevron.right"))")
                }.frame(height: 50)
                HStack {
                    Spacer()
                    Text("these options can be changed at any time via Admin Settings.").font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer()
            }.padding()
        }
    }
    func createGroup() async {
        if !groupName.isEmpty {
            let group = SQGroup(id: UUID(), name: groupName, defaultPermissions: SQDefaultPermissions(id: UUID(), membersCanControlPlayback: membersControlPlayback, membersCanAddToQueue: membersAddToQueue), members: [SQGroupMember(id: UUID(), user: firManager.currentUser!, canControlPlayback: true, canAddToQueue: true, isOwner: true)], publicGroup: publicGroup, askToJoin: askToJoin, previewQueue: [])
            if await firManager.createGroup(group) {
                groupBeingCreated = group
                dismiss()
            }
        }
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
