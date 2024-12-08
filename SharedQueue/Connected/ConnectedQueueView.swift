//
//  GroupConnectedView.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import SwiftUI

struct ConnectedQueueView: View {
    @StateObject var firManager = FIRManager.shared
    @State var backgroundColor: Color = Color.secondary
    @State var bottomColor: Color = Color.secondary
    @Environment(\.dismiss) var dismiss
    @Binding var showingQueue: Bool
    @State var showingAddSheet = false
    var body: some View {
        if let connectedGroup = firManager.connectedGroup {
            ZStack {
                VStack(alignment: .leading) {
                    Text("CURRENTLY PLAYING").bold().opacity(0.3)
                    HStack {
                        AsyncImage(url: connectedGroup.currentlyPlaying?.albumArt) { img in
                            img.resizable().frame(width: 70, height: 70).cornerRadius(10.0)
                        } placeholder: {
                            Image(.mediaItemPlaceholder).resizable().frame(width: 70, height: 70).cornerRadius(10.0)
                        }
                        VStack(alignment: .leading) {
                            Text(connectedGroup.currentlyPlaying?.title ?? "Nothing Playing").fontWeight(.medium)
                            Text(connectedGroup.currentlyPlaying?.artist ?? "").opacity(0.6)
                        }
                    }.onTapGesture {
                        showingQueue = false
                    }
                    Divider().overlay(backgroundColor).padding(5)
                    ZStack {
                        ScrollView {
                            VStack(alignment: .leading) {
                                ForEach(Array(connectedGroup.previewQueue.enumerated()), id: \.element.id) { index, item in
                                    VStack {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 15.0).foregroundStyle(.white).opacity(index % 2 == 0 ? 0.4 : 0.2)
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
                                        Divider()
                                    }
                                }
                                HStack {
                                    Spacer()
                                    Text("That's all!").font(.title2).fontWeight(.bold).opacity(0.5)
                                    Spacer()
                                }
                                Divider().overlay(bottomColor).padding(5)
                                VStack(alignment: .leading) {
                                    Text("Members (\(connectedGroup.members.count + 1)):").font(.title2).fontWeight(.semibold)
                                    ForEach(connectedGroup.members) { user in
                                        HStack {
                                            Image(.mediaItemPlaceholder).resizable().frame(width: 50, height: 50).cornerRadius(10.0)
                                            Text(user.user.username).fontWeight(.medium).font(.title2)
                                            if user.isOwner {
                                                Image(systemName: "crown.fill").foregroundStyle(.yellow)
                                            }
                                            Spacer()
                                            if connectedGroup.connectedMembers.contains(where: { $0.id == user.id }) {
                                                HStack {
                                                    Circle().frame(width: 20, height: 20)
                                                    Text("Listening")
                                                }.foregroundStyle(.green)
                                            }
                                        }.opacity(connectedGroup.connectedMembers.contains(where: { $0.id == user.id }) ? 1.0 : 0.5)
                                    }
                                }
                            }
                        }
                    }
                    Spacer()
                    Button(action: {
                        showingAddSheet = true
                    }, label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15.0).foregroundStyle(bottomColor.secondary).opacity(0.2).overlay {
                                RoundedRectangle(cornerRadius: 15.0).stroke(bottomColor.secondary, lineWidth: 1.5)
                            }
                            Text("\(Image(systemName: "plus.circle")) Add to Queue").foregroundStyle(bottomColor).font(.title3).bold()
                        }
                    }).frame(height: 50).padding(5)
                }.padding().foregroundStyle(bottomColor.isDark ? .white : .black)
            }.onChange(of: connectedGroup.currentlyPlaying?.title, initial: true) { _, _ in
                if let currentlyPlaying = connectedGroup.currentlyPlaying {
                    backgroundColor = Color.white.fromHex(currentlyPlaying.colors[1]) ?? Color.secondary
                    bottomColor = Color.white.fromHex(currentlyPlaying.colors[0]) ?? Color.secondary
                }
            }.sheet(isPresented: $showingAddSheet) {
                ConnectedAddToQueueView()
            }
        } else {
            ProgressView()
        }
    }
}
