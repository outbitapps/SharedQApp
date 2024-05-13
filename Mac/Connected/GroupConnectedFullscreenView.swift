//
//  GroupConnectedFullscreenView.swift
//  Mac
//
//  Created by Payton Curry on 4/7/24.
//

import SwiftUI
import MusicKit
import SharedQProtocol
import FluidGradient

struct GroupConnectedFullscreenView: View {
    @StateObject var firManager = FIRManager.shared
    @State var backgroundColor: Color = Color.secondary
    @State var bottomColor: Color = Color.secondary
    @Environment(\.dismiss) var dismiss
    @State var showingQueue = false
    @State var count = 0
    @State var showingAdminSettings = false
    @State var playbackTime = 0.0
    var playbackTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var checkPlaybackTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    @ObservedObject var applePlaybackState = ApplicationMusicPlayer.shared.state
    @State var colors = [Color.white, Color.secondary]
    @Binding var fullscreenMode: Bool
    var body: some View {
        if let group = firManager.connectedGroup, let playbackState = group.playbackState {
            let myPermissions = group.members.first(where: {$0.user.id == firManager.currentUser!.id}) ?? SQGroupMember(id: UUID(), user: firManager.currentUser!, canControlPlayback: false, canAddToQueue: false, isOwner: false)
            ZStack {
                if let currentSong = firManager.connectedGroup!.currentlyPlaying {
//                    LinearGradient(colors: currentSong.colors.toColor(), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                    FluidGradient(blobs: colors, speed: 0.3)
                }
                HStack {
                    playbackInfo()
                    Divider()
                    ConnectedQueueView(showingQueue: .constant(true), presentationMode: true)
                }
            }.onChange(of: showingQueue) { oldValue, newValue in
                count += 1
            }.onChange(of: showingAdminSettings, { oldValue, newValue in
                count += 1
            }).onChange(of: firManager.connectedGroup?.currentlyPlaying?.title, initial: true) { oldValue, newValue in
                backgroundColor = Color.white.fromHex(firManager.connectedGroup!.currentlyPlaying!.colors[1]) ?? Color.secondary
                bottomColor = Color.white.fromHex(firManager.connectedGroup!.currentlyPlaying!.colors[0]) ?? Color.secondary
                colors = []
                for color in firManager.connectedGroup!.currentlyPlaying!.colors {
                    colors.append(Color.white.fromHex(color)!)
                    colors.append(Color.white.fromHex(color)!)
                }
            }.onAppear {
                for window in NSApplication.shared.windows {
                    if window.title == "Group" {
                        window.title = firManager.connectedGroup?.name ?? "Group"
                    }
                }
                
            }.onReceive(playbackTimer, perform: { _ in
                if let playbackState = group.playbackState {
                    if playbackState.state != .pause {
                        playbackTime += 1
                    }
                }
            }).onReceive(checkPlaybackTimer) { _ in
                Task {
                    playbackTime = await musicService.getSongTimestamp()
                }
            }.onReceive(exitFullscreenNotification) { _ in
                fullscreenMode = false
            }
        } else {
            ProgressView()
        }
    }
    @ViewBuilder func playbackInfo() -> some View {
        if let group = firManager.connectedGroup {
            VStack(alignment: .center) {
                Text("\(group.connectedMembers.count) listening ∙ \(group.publicGroup ? "Public Group" : "Private Group")").fontWeight(.medium).font(.title).padding(.top, 20)
                Spacer()
                AsyncImage(url: group.currentlyPlaying?.albumArt) { img in
                    img.resizable().aspectRatio(contentMode: .fit).cornerRadius(15.0).padding(.horizontal, 50)
                } placeholder: {
                    Image(.mediaItemPlaceholder).resizable().cornerRadius(15.0).padding(.horizontal, 50)

                }
                HStack {
                    VStack(alignment: .leading) {
                        Text(group.currentlyPlaying?.title ?? "Nothing playing").font(.system(size: 30)).bold()
                        Text(group.currentlyPlaying?.artist ?? "Nobody").font(.largeTitle).opacity(0.8)
                    }
                    Spacer()
                }.padding(.horizontal, 10)
                Slider(value: $playbackTime, in: 0...group.currentlyPlaying!.duration) { editing in
                    print(editing)
                }
                Spacer()
            }.padding(20).foregroundStyle(Color.white.fromHex(firManager.connectedGroup!.currentlyPlaying!.colors[0])!.isDark ? .white : .black)
        }
    }
    @ViewBuilder func queueInfo() -> some View {
        
    }
}


