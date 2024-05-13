//
//  ContentView.swift
//  Mac
//
//  Created by Payton Curry on 4/7/24.
//

import SwiftUI
import SharedQProtocol

struct ContentView: View {
    @AppStorage("completedOnboarding") var completedOnboarding = false
    @Environment(\.openWindow) var openWindow
    @EnvironmentObject var firManager: FIRManager
    @State var showCreateView = false
    var body: some View {
        if completedOnboarding {
            NavigationView {
                List {
                    if let currentUser = firManager.currentUser {
                        ForEach(currentUser.groups) { group in
                            VStack {
                                NavigationLink {
                                    ConfirmJoinView(group: group)
                                } label: {
                                    HomeGroupCell(group: group)
                                }

                                Divider()
                            }
                        }
                    }
                }.listStyle(.sidebar).toolbar(content: {
                    ToolbarItem(placement: .automatic) {
                        Button(action: {
                            showCreateView.toggle()
                        }, label: {
                            Image(systemName: "plus")
                        }).popover(isPresented: $showCreateView, content: {
                            CreateGroupView(groupBeingCreated: .constant(nil)).frame(width: 300)
                        })

                    }
                })
            }
        } else {
            VStack {
                ProgressView().onAppear(perform: {
                    openWindow(id: "onboarding")
                })
                Button(action: {
                    openWindow(id: "onboarding")
                }, label: {
                    Text("Setup window not showing?").foregroundStyle(.blue)
                }).buttonStyle(.plain)
            }
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
                    VStack {
                        Text("Create a Group").font(.title).bold()
                        Text("a group is a shared queue. you can make any type of group you want! anywhere from a massive, public group with hundreds of people at a time to a smaller, private group with a couple friends or some family. you can customize it however you’d like!").font(.subheadline).padding(.horizontal)
                    }
                }
                TextField("group name", text: $groupName).padding(.vertical)
                HStack {
                    VStack(alignment: .leading) {
                        Text("Public Group").font(.title2).fontWeight(.semibold)
                        Text("In a public group, the group is visible to anyone and can be joined by anyone. Best for large communities").font(.caption).foregroundStyle(.secondary)
                    }
                    Toggle(isOn: $publicGroup, label: {
                    }).labelsHidden()
                }
                Text("Default Permissions").font(.title2).fontWeight(.semibold)
                HStack {
                    Text("Members can control playback").font(.subheadline).fontWeight(.medium)
                    Toggle(isOn: $membersControlPlayback, label: {
                        
                    }).labelsHidden()
                }
                HStack {
                    Text("Members can add to queue").font(.subheadline).fontWeight(.medium)
                    Toggle(isOn: $membersAddToQueue, label: {
                        
                    }).labelsHidden()
                }
                HStack {
                    VStack(alignment: .leading) {
                        Text("Ask to Join").font(.subheadline).fontWeight(.medium)
                        Text("With Ask to Join, your permission is needed before anyone can join. Best for small groups.").font(.caption).foregroundStyle(.secondary)
                    }
                    Toggle(isOn: $askToJoin, label: {
                        
                    }).labelsHidden()
                }
                Button {
                    Task {
                        await createGroup()
                    }
                } label: {
                    Text("Create \(Image(systemName: "chevron.right"))")
                }.frame(height: 50)
                HStack {
                    Text("these options can be changed at any time via Admin Settings.").font(.caption2).foregroundStyle(.secondary)
                }
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

struct HomeGroupCell: View {
    var group: SQGroup
    @EnvironmentObject var firManager: FIRManager
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(group.name).font(.title2).fontWeight(.semibold)
                Text("^[\(group.members.count + 1) Members](inflect:true) ∙ \(group.connectedMembers.count) right now").foregroundStyle(.secondary)
                Text("Last used \(lastConnectedString())").foregroundStyle(.secondary)
                Text("\(group.publicGroup ? "Public" : "Private")").foregroundStyle(.secondary)
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

#Preview {
    ContentView()
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
