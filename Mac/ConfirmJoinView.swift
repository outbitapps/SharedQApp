//
//  ConfirmJoinView.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import SharedQProtocol
import SwiftUI


struct ConfirmJoinView: View {
    var group: SQGroup
    @State var backgroundColor: Color = Color.secondary
    @State var bottomColor: Color = Color.secondary
    @Environment(\.dismiss) var dismiss
    @State var showingQueueSheet = false
    @Environment(\.openWindow) var openWindow
    var body: some View {
        ZStack {
            if let currentSong = group.currentlyPlaying {
                LinearGradient(colors: currentSong.colors.toColor(), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            } else {
                LinearGradient(colors: [bottomColor, backgroundColor], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            }
            ScrollView {
                VStack {
                    Text(group.name).font(.largeTitle).bold()
                    Text("is currently listening to").font(.title2).fontWeight(.semibold)
                    AsyncImage(url: group.currentlyPlaying?.albumArt) { img in
                        img.resizable().aspectRatio(contentMode: .fit).cornerRadius(15.0).frame(width: 200, height: 200)
                    } placeholder: {
                        Image(.mediaItemPlaceholder).resizable().aspectRatio(contentMode: .fit).cornerRadius(15.0).frame(width: 200, height: 200)
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
                                    FIRManager.shared.syncManager.connectToGroup(group: group, user: FIRManager.shared.currentUser!)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                                        openWindow(id: "groupconnectedview")
                                    })
                                }
                            }, label: {
                                ZStack {
                                    Text("Join").foregroundStyle(bottomColor).font(.title3).bold()
                                }
                            }).frame(height: 50).padding(2)
                            Button(action: {
                                showingQueueSheet = true
                            }, label: {
                                ZStack {
                                    Text("View Queue").foregroundStyle(bottomColor).font(.title3).bold()
                                }
                            }).frame(height: 50).padding(2)
                        }
                        Button(action: {
                            dismiss()
                        }, label: {
                            ZStack {
                                Text("Cancel").foregroundStyle(bottomColor).font(.title3).bold()
                            }
                        }).frame(height: 50).padding(2)
                    }

                }.padding().foregroundStyle(bottomColor.isDark ? .white : .black)
            }
        }.onAppear {
            if let currentlyPlaying = group.currentlyPlaying {
                backgroundColor = Color.white.fromHex(currentlyPlaying.colors[1]) ?? Color.secondary
                bottomColor = Color.white.fromHex(currentlyPlaying.colors[0]) ?? Color.secondary
            } else {
                backgroundColor = Color.secondary
                bottomColor = Color.secondary.opacity(0.8)
            }
        }.sheet(isPresented: $showingQueueSheet, content: {
//            PreviewQueueView(group: group)
        })
    }
}

extension [String] {
    func toColor() -> [SwiftUI.Color] {
        var colors: [SwiftUI.Color] = []
        for hex in self {
            colors.append(SwiftUI.Color.white.fromHex(hex)!)
        }
        return colors
    }
}

extension Color {
    var isDark: Bool {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        var ciColor = CIColor(color: NSColor(self))
        red = ciColor?.red ?? 0.0
        green = ciColor?.green ?? 0.0
        blue = ciColor?.blue ?? 0.0
        
        let lum = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        return lum < 0.5
    }
}
