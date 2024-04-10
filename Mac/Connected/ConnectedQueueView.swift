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
    var presentationMode: Bool = false
    var body: some View {
            ZStack {
                VStack(alignment: .leading) {
                    if !presentationMode {
                        Text("CURRENTLY PLAYING").bold().opacity(0.3)
                        HStack {
                            AsyncImage(url: firManager.connectedGroup!.currentlyPlaying?.albumArt) { img in
                                img.resizable().frame(width: 70, height: 70).cornerRadius(10.0)
                            } placeholder: {
                                Image(.mediaItemPlaceholder).resizable().frame(width: 70, height: 70).cornerRadius(10.0)
                            }
                            VStack(alignment: .leading) {
                                Text(firManager.connectedGroup!.currentlyPlaying?.title ?? "Nothing Playing").fontWeight(.medium)
                                Text(firManager.connectedGroup!.currentlyPlaying?.artist ?? "").opacity(0.6)
                            }
                        }.onTapGesture {
                            showingQueue = false
                        }
                    } else {
                        Text("Up next").bold().font(.largeTitle)
                    }
                    Divider().overlay(backgroundColor).padding(5)
                    ZStack {
                        ScrollView {
                            VStack(alignment: .leading) {
                                ForEach(Array(firManager.connectedGroup!.previewQueue.enumerated()), id: \.element.id) { index, item in
//                                    let item = firManager.connectedGroup!.previewQueue[index]
                                    VStack {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 15.0).foregroundStyle(.white).opacity(index % 2 == 0 ? 0.4: 0.2)
                                            HStack {
                                                AsyncImage(url: item.song.albumArt) { img in
                                                    img.resizable().aspectRatio(contentMode: .fit).cornerRadius(10.0)
                                                } placeholder: {
                                                    Image(.mediaItemPlaceholder).resizable().aspectRatio(contentMode: .fit).cornerRadius(10.0)
                                                }
                                                VStack(alignment: .leading) {
                                                    Text(item.song.title).fontWeight(.medium).if(presentationMode) { view in
                                                        view.fontWeight(.bold)
                                                    }
                                                    Text(item.song.artist).opacity(0.8)
                                                }.if(presentationMode) { view in
                                                    view.font(.largeTitle).fontWeight(.medium)
                                                }
                                                Spacer()
                                                Text("Added by \(item.addedBy)").opacity(0.5).font(presentationMode ? .title : .caption)
                                            }.padding(5)
                                        }.frame(height: presentationMode ? 80 : 50)
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
                                    Text("Members (\(firManager.connectedGroup!.members.count + 1)):").font(.title2).fontWeight(.semibold)
                                    HStack {
                                        let user = firManager.connectedGroup!.owner
                                        HStack {
                                            
                                            Image(.mediaItemPlaceholder).resizable().frame(width: 50, height: 50).cornerRadius(10.0)
                                            Text(user.username).fontWeight(.medium).font(.title2)
                                            Image(systemName: "crown.fill").foregroundStyle(.yellow)
                                            Spacer()
                                            if firManager.connectedGroup!.connectedMembers.contains(user.id) {
                                                HStack {
                                                    Circle().frame(width: 20, height: 20)
                                                    Text("Listening")
                                                }.foregroundStyle(.green)
                                            }
                                        }.opacity(firManager.connectedGroup!.connectedMembers.contains(user.id) ? 1.0 : 0.5)
                                    }
                                    ForEach(firManager.connectedGroup!.members) { user in
                                        HStack {
                                            Image(.mediaItemPlaceholder).resizable().frame(width: 50, height: 50).cornerRadius(10.0)
                                            Text(user.user.username).fontWeight(.medium).font(.title2)
                                            Spacer()
                                            if firManager.connectedGroup!.connectedMembers.contains(user.user.id) {
                                                HStack {
                                                    Circle().frame(width: 20, height: 20)
                                                    Text("Listening")
                                                }.foregroundStyle(.green)
                                            }
                                        }.opacity(firManager.connectedGroup!.connectedMembers.contains(user.user.id) ? 1.0 : 0.5)
                                    }
                                    
                                    
                                }
                            }
                        }
                        
                    }
                    Spacer()
                    if !presentationMode {
                        Button(action: {
                            showingAddSheet = true
                        }, label: {
                            ZStack {
                                Text("\(Image(systemName: "plus.circle")) Add to Queue")
                            }
                        }).frame(height: 50).padding(5)
                    }
                }.padding().foregroundStyle(Color.white.fromHex(firManager.connectedGroup!.currentlyPlaying!.colors[0])!.isDark ? .white : .black)
            }.onChange(of: firManager.connectedGroup?.currentlyPlaying?.title, initial: true) { oldValue, newValue in
                backgroundColor = Color.white.fromHex(firManager.connectedGroup!.currentlyPlaying!.colors[1]) ?? Color.secondary
                bottomColor = Color.white.fromHex(firManager.connectedGroup!.currentlyPlaying!.colors[0]) ?? Color.secondary
            }.sheet(isPresented: $showingAddSheet) {
                ConnectedAddToQueueView()
            }
        }
    }

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
