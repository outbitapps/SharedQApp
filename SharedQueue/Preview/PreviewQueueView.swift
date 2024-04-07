//
//  PreviewQueueView.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import SwiftUI
import Glur
import SharedQProtocol

struct PreviewQueueView: View {
    var group: SQGroup
    @EnvironmentObject var firManager: FIRManager
    @State var backgroundColor: Color = Color.secondary
    @State var bottomColor: Color = Color.secondary
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            if let currentSong = group.currentlyPlaying {
                LinearGradient(colors: currentSong.colors.toColor(), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            }
            VStack(alignment: .leading) {
                Text("CURRENTLY PLAYING").bold().opacity(0.3).padding()
                HStack {
                    AsyncImage(url: group.currentlyPlaying?.albumArt) { img in
                        img.resizable().frame(width: 70, height: 70).cornerRadius(10.0)
                    } placeholder: {
                        Image(.mediaItemPlaceholder).resizable().frame(width: 70, height: 70).cornerRadius(10.0)
                    }
                    VStack(alignment: .leading) {
                        Text(group.currentlyPlaying?.title ?? "Nothing Playing").fontWeight(.medium)
                        Text(group.currentlyPlaying?.artist ?? "").opacity(0.6)
                    }
                }.padding(.horizontal)
                Divider().overlay(backgroundColor).padding(5)
                ZStack {
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(group.previewQueue.indices) { index in
                                let item = group.previewQueue[index]
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15.0).foregroundStyle(.white).opacity(index % 2 == 0 ? 0.4: 0.2)
                                    HStack {
                                        AsyncImage(url: item.song.albumArt) { img in
                                            img.resizable().aspectRatio(contentMode: .fit).cornerRadius(10.0)
                                        } placeholder: {
                                            Image(.mediaItemPlaceholder).resizable().aspectRatio(contentMode: .fit).cornerRadius(10.0)
                                        }
                                        VStack(alignment: .leading) {
                                            Text(item.song.title).fontWeight(.medium)
                                            Text(item.song.artist).opacity(0.8)
                                        }
                                        Spacer()
                                        Text("Added by \(item.addedBy)").opacity(0.5).font(.caption)
                                    }.padding(5)
                                }.frame(height: 50)
                            }
                            HStack {
                                Spacer()
                                Text("That's all!").font(.title2).fontWeight(.bold).opacity(0.5)
                                Spacer()
                            }
                            Divider().overlay(bottomColor).padding(5)
                            VStack(alignment: .leading) {
                                Text("Members (\(group.members.count + 1)):").font(.title2).fontWeight(.semibold)
                                HStack {
                                    let user = group.owner
                                    HStack {
                                        
                                        Image(.mediaItemPlaceholder).resizable().frame(width: 50, height: 50).cornerRadius(10.0)
                                        Text(user.username).fontWeight(.medium).font(.title2)
                                        Image(systemName: "crown.fill").foregroundStyle(.yellow)
                                        Spacer()
                                        if group.connectedMembers.contains(user.id) {
                                            HStack {
                                                Circle().frame(width: 20, height: 20)
                                                Text("Listening")
                                            }.foregroundStyle(.green)
                                        }
                                    }.opacity(group.connectedMembers.contains(user.id) ? 1.0 : 0.5)
                                }
                                ForEach(group.members) { user in
                                    HStack {
                                        Image(.mediaItemPlaceholder).resizable().frame(width: 50, height: 50).cornerRadius(10.0)
                                        Text(user.user.username).fontWeight(.medium).font(.title2)
                                        Spacer()
                                        if group.connectedMembers.contains(user.user.id) {
                                            HStack {
                                                Circle().frame(width: 20, height: 20)
                                                Text("Listening")
                                            }.foregroundStyle(.green)
                                        }
                                    }.opacity(group.connectedMembers.contains(user.user.id) ? 1.0 : 0.5)
                                }
                            }
                        }
                        
                    }
                    Spacer()
                }.padding().foregroundStyle(Color.white.fromHex(group.currentlyPlaying!.colors[0])!.isDark ? .white : .black)
            }.onAppear
            {
                backgroundColor = Color.white.fromHex(group.currentlyPlaying!.colors[1]) ?? Color.secondary
                bottomColor = Color.white.fromHex(group.currentlyPlaying!.colors[0]) ?? Color.secondary
            }
        }
    }
}
