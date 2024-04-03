//
//  ConnectedAdminSettings.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/25/24.
//

import SwiftUI

struct ConnectedAdminSettings: View {
    @StateObject var firManager = FIRManager.shared
    @State var backgroundColor: Color = Color.secondary
    @State var bottomColor: Color = Color.secondary
    @Environment(\.dismiss) var dismiss
    @State var publicGroup = false
    @State var askToJoin = false
    @Binding var showingAdminSettings: Bool
    @State var copiedURL = false
    var body: some View {
        if let group = firManager.connectedGroup {
            ZStack {
                VStack(alignment: .leading) {
                    HStack {
                        Button(action: {
                            showingAdminSettings = false
                        }, label: {
                            ZStack {
                                Circle().foregroundStyle(.white).opacity(0.2)
                                Image(systemName: "chevron.left").foregroundStyle(.white)
                            }
                        }).frame(width: 35, height: 35)
                        VStack(alignment: .leading) {
                            Text("Admin Settings").font(.largeTitle).bold()
                            Text(group.name).font(.title2).bold()
                        }
                    }
                    ScrollView {
                        Section("ACCESS") {
                            VStack {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Public Group").font(.title2).fontWeight(.semibold)
                                        Text("In a public group, the group is visible to anyone and can be joined by anyone. Best for large communities (BETA - CURRENLY NOT FUNCTIONAL)").foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Toggle(isOn: $publicGroup, label: {
                                    }).labelsHidden()
                                }.padding().background(content: { Color.white.opacity(0.2) }).cornerRadius(15.0)
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Ask to Join").font(.title2).fontWeight(.semibold)
                                        Text("With Ask to Join, your permission is needed before anyone can join. Best for small groups. (BETA - CURRENLY NOT FUNCTIONAL)").foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Toggle(isOn: $askToJoin, label: {
                                    }).labelsHidden()
                                }.padding().background(content: { Color.white.opacity(0.2) }).cornerRadius(15.0)
                                HStack {
                                    Button(action: {
                                        if let groupURL = group.groupURL {
                                            UIPasteboard.general.url = groupURL
                                            copiedURL = true
                                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        }
                                    }, label: {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 15.0).foregroundStyle(backgroundColor.secondary).opacity(0.2).overlay {
                                                RoundedRectangle(cornerRadius: 15.0).stroke(backgroundColor.secondary, lineWidth: 1.5)
                                            }
                                            Text("\(copiedURL ? Image(systemName: "checkmark") : Image(systemName: "link")) Copy Link").foregroundStyle(backgroundColor).font(.title3).bold().symbolEffect(.bounce, value: copiedURL)
                                        }
                                    }).frame(height: 50).padding(5)
                                    Button(action:  {}, label: {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 15.0).foregroundStyle(backgroundColor.secondary).opacity(0.2).overlay {
                                                RoundedRectangle(cornerRadius: 15.0).stroke(backgroundColor.secondary, lineWidth: 1.5)
                                            }
                                            Text("\(Image(systemName: "qrcode")) QR Code").foregroundStyle(backgroundColor).font(.title3).bold()
                                        }
                                    }).frame(height: 50).padding(5)
                                }
                            }
                        }
                        Section("MEMBERS") {
                            VStack {
                                ForEach(firManager.connectedGroup!.members) { user in
                                    MemberManagementCell(user: user, backgroundColor: backgroundColor, bottomColor: bottomColor)
                                }
                            }
                        }
                    }.listStyle(.plain).listRowBackground(Color.clear).background(Color.clear)
                }.padding().foregroundStyle(Color.white.fromHex(firManager.connectedGroup!.currentlyPlaying!.colors[0])!.isDark ? .white : .black)
            }.onChange(of: firManager.connectedGroup?.currentlyPlaying?.title, initial: true) { _, _ in
                backgroundColor = Color.white.fromHex(firManager.connectedGroup!.currentlyPlaying!.colors[1]) ?? Color.secondary
                bottomColor = Color.white.fromHex(firManager.connectedGroup!.currentlyPlaying!.colors[0]) ?? Color.secondary
            }.onAppear {
                publicGroup = group.publicGroup
            }
        }
    }
}

struct MemberManagementCell: View {
    var user: SQUserPermissions
    var backgroundColor: Color
    var bottomColor: Color
    @StateObject var firManager = FIRManager.shared
    @State var canControlPlayback = false
    @State var loading = false
    init(user: SQUserPermissions, backgroundColor: Color, bottomColor: Color) {
        self.user = user
        self.backgroundColor = backgroundColor
        self.bottomColor = bottomColor
        self.canControlPlayback = user.canControlPlayback
    }
    var body: some View {
        ZStack {
            HStack {
                Image(.mediaItemPlaceholder).resizable().frame(width: 50, height: 50).cornerRadius(10.0)
                
                Menu {
                    Button(action: {
                        firManager.connectedGroup!.members.removeAll(where: {$0.user.id == user.user.id})
                        loading = true
                        Task {
                            await firManager.updateGroup(firManager.connectedGroup!)
                            loading = false
                        }
                    }, label: {
                        Text("Kick").foregroundStyle(.red)
                    })
                } label: {
                    Text("\(user.user.username) \(Image(systemName: "ellipsis"))").fontWeight(.medium).font(.title2)
                }

                Spacer()
                
                VStack {
                    
                    Text("Controls Playback").font(.caption2).foregroundStyle(.black)
                    Toggle("Controls Playback", isOn: $canControlPlayback).labelsHidden()
                }
            }.padding(10).background(content: { Color.white.opacity(0.2) }).cornerRadius(20.0).onChange(of: canControlPlayback, initial: false) { oldValue, newValue in
                firManager.connectedGroup!.members.first(where: {$0.user.id == user.user.id})?.canControlPlayback = newValue
                loading = true
                Task  {
                    await firManager.updateGroup(firManager.connectedGroup!)
                    loading = false
                }
            }.disabled(loading)
            if loading {
                RoundedRectangle(cornerRadius: 20.0).foregroundStyle(.black).opacity(0.7)
                ProgressView().preferredColorScheme(.dark)
            }
        }
    }
}
