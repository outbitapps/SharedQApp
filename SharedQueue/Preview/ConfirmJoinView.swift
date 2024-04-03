//
//  ConfirmJoinView.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import SwiftUI

struct ConfirmJoinView: View {
    var group: SQGroup
    @EnvironmentObject var firManager: FIRManager
    @State var backgroundColor: Color = Color.secondary
    @State var bottomColor: Color = Color.secondary
    @Environment(\.dismiss) var dismiss
    @State var showingQueueSheet = false
    var body: some View {
        ZStack {
            if let currentSong = group.currentlyPlaying {
                LinearGradient(colors: currentSong.colors.toColor(), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            } else {
                LinearGradient(colors: [bottomColor, backgroundColor], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            }
            VStack {
                Text(group.name).font(.largeTitle).bold()
                Text("is currently listening to").font(.title2).fontWeight(.semibold)
                AsyncImage(url: group.currentlyPlaying?.albumArt) { img in
                    img.resizable().aspectRatio(contentMode: .fit).cornerRadius(15.0).padding(.horizontal, 20)
                } placeholder: {
                    Image(.mediaItemPlaceholder).resizable().aspectRatio(contentMode: .fit).cornerRadius(15.0).padding(.horizontal, 20)
                }
                Text(group.currentlyPlaying?.title ?? "Nothing").font(.title2).fontWeight(.semibold)
                Text(group.currentlyPlaying?.artist ?? "Nobody").font(.title3).fontWeight(.semibold).opacity(0.8)
                Spacer()
                Text("Are you sure you want to join?").font(.title3).fontWeight(.semibold)
                Text("everybody currently in “\(group.name)” will be able to see that you joined, and will be able to see your profile. if you would like to know who is currently listening in this group, press “View Queue” (nobody will know that you’re viewing the queue). once you join, the music in the queue will start playing immediately.").foregroundStyle(.secondary)
                VStack {
                    HStack {
                        Button(action: {
                            Task {
                                await firManager.joinGroup(group)
                            }
                        }, label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15.0).foregroundStyle(bottomColor.secondary).opacity(0.2).overlay {
                                    RoundedRectangle(cornerRadius: 15.0).stroke(bottomColor.secondary, lineWidth: 1.5)
                                }
                                Text("Join").foregroundStyle(bottomColor).font(.title3).bold()
                            }
                        }).frame(height: 50).padding(5)
                        Button(action: {
                            showingQueueSheet = true
                        }, label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15.0).foregroundStyle(bottomColor.secondary).opacity(0.2).overlay {
                                    RoundedRectangle(cornerRadius: 15.0).stroke(bottomColor.secondary, lineWidth: 1.5)
                                }
                                Text("View Queue").foregroundStyle(bottomColor).font(.title3).bold()
                            }
                        }).frame(height: 50).padding(5)
                        
                    }
                    Button(action: {
                        dismiss()
                    }, label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15.0).foregroundStyle(bottomColor.secondary).opacity(0.2).overlay {
                                RoundedRectangle(cornerRadius: 15.0).stroke(bottomColor.secondary, lineWidth: 1.5)
                            }
                            Text("Cancel").foregroundStyle(bottomColor).font(.title3).bold()
                        }
                    }).frame(height: 50).padding(5)
                }

            }.padding().foregroundStyle(bottomColor.isDark ? .white : .black)
        }.onAppear
        {
            if let currentlyPlaying = group.currentlyPlaying {
                backgroundColor = Color.white.fromHex(currentlyPlaying.colors[1]) ?? Color.secondary
                bottomColor = Color.white.fromHex(currentlyPlaying.colors[0]) ?? Color.secondary
            } else {
                backgroundColor = Color.secondary
                bottomColor = Color.secondary.opacity(0.8)
            }
        }.sheet(isPresented: $showingQueueSheet, content: {
            PreviewQueueView(group: group)
        })
    }
}
