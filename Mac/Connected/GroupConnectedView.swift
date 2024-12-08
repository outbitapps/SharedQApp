//
//  GroupConnectedView.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import SwiftUI
import MusicKit
import SharedQProtocol
import FluidGradient
struct GroupConnectedView: View {
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
    @State var fullscreenMode = false
    var body: some View {
        if !fullscreenMode {
            if let group = firManager.connectedGroup, let playbackState = group.playbackState {
                let myPermissions = group.members.first(where: {$0.user.id == firManager.currentUser!.id}) ?? SQGroupMember(id: UUID(), user: firManager.currentUser!, canControlPlayback: false, canAddToQueue: false, isOwner: false)
                ZStack {
                    if let currentSong = firManager.connectedGroup!.currentlyPlaying {
    //                    LinearGradient(colors: currentSong.colors.toColor(), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                        FluidGradient(blobs: colors, speed: 0.3)
                    }
                    VStack(alignment: .center) {
                        Text("\(group.connectedMembers.count) listening ∙ \(group.publicGroup ? "Public Group" : "Private Group")").fontWeight(.medium).padding(.top, 20)
                        Spacer()
                        AsyncImage(url: group.currentlyPlaying?.albumArt) { img in
                            img.resizable().aspectRatio(contentMode: .fit).cornerRadius(15.0).frame(width: 200, height: 200)
                        } placeholder: {
                            Image(.mediaItemPlaceholder).resizable().cornerRadius(15.0).frame(width: 200, height: 200)

                        }
                        HStack {
                            VStack(alignment: .leading) {
                                Text(group.currentlyPlaying?.title ?? "Nothing playing").font(.title2).bold()
                                Text(group.currentlyPlaying?.artist ?? "Nobody").font(.title2).opacity(0.8)
                            }
                            Spacer()
                        }.padding(.horizontal, 10)
                        Slider(value: $playbackTime, in: 0...group.currentlyPlaying!.duration) { editing in
                            print(editing)
                        }
                        PlaybackControls(group: group).disabled(!myPermissions.canControlPlayback)
                        Spacer()
                        groupControls(myPermissions: myPermissions)
                    }.padding(20).foregroundStyle(Color.white.fromHex(firManager.connectedGroup!.currentlyPlaying!.colors[0])!.isDark ? .white : .black).scaleEffect(x: showingQueue || showingAdminSettings ? 0.8 : 1.0, y: showingQueue || showingAdminSettings ? 0.8 : 1.0).blur(radius: showingQueue || showingAdminSettings ? 50 : 0).animation(.spring, value: showingQueue).animation(.spring, value: showingAdminSettings).overlay {
                        if showingQueue {
                            Rectangle().ignoresSafeArea().opacity(0)
                        }
                    }
                    if showingQueue {
                        queueView()

                    }
                    if showingAdminSettings {
                        adminView()
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
                }.onReceive(enterFullscreenNotification) { _ in
                    fullscreenMode = true
                }
            } else {
                ProgressView()
            }
        } else {
            GroupConnectedFullscreenView(fullscreenMode: $fullscreenMode)
        }
    }
    @ViewBuilder func groupControls(myPermissions: SQGroupMember) -> some View {
        HStack {
            Button(action: {
                Task {
                    await firManager.syncManager.disconnect()
                }
            }, label: {
                ZStack {
                    Text("Leave").foregroundStyle(Color.red)
                }
            }).frame(height: 50).padding(5).keyboardShortcut(.cancelAction)
            Button(action: {
                showingQueue = true
            }, label: {
                ZStack {
                    Text("Queue")
                }
            }).frame(height: 50).padding(5)
            
        }
        if myPermissions.isOwner {
            Button(action: {
                showingAdminSettings = true
            }, label: {
                ZStack {
                    Text("Admin Settings").fontWeight(.medium)
                }
            }).frame(height: 50).padding(5)
        } else {
            Text("remember: playback controls sync between everyone! if you skip a song, that song is skipped for everybody.").font(.caption).foregroundStyle(.secondary)
        }
    }
    @ViewBuilder func queueView() -> some View {
        ConnectedQueueView(showingQueue: $showingQueue).keyframeAnimator(initialValue: ShowingQueueAnimationValues.EnterQueue, trigger: count) { view, val in
            view.scaleEffect(x: val.scaleX, y: val.scaleY).blur(radius: val.blurRadius).opacity(val.opacity)
        } keyframes: { val in
            KeyframeTrack(\.scaleX) {
                
                SpringKeyframe(1.0, duration: 0.8, spring: .bouncy(extraBounce: 0.05))
            }
            KeyframeTrack(\.scaleY) {
                SpringKeyframe(1.0, duration: 0.8, spring: .bouncy(extraBounce: 0.05))
            }
            KeyframeTrack(\.blurRadius) {
                SpringKeyframe(0.0, duration: 0.8, spring: .bouncy(extraBounce: 0.05))
            }
            KeyframeTrack(\.opacity) {
                SpringKeyframe(1.0, duration: 0.8, spring: .bouncy(extraBounce: 0.05))
            }
        }
    }
    @ViewBuilder func adminView() -> some View {
        ConnectedAdminSettings(showingAdminSettings: $showingAdminSettings).keyframeAnimator(initialValue: ShowingQueueAnimationValues.EnterQueue, trigger: count) { view, val in
            view.scaleEffect(x: val.scaleX, y: val.scaleY).blur(radius: val.blurRadius).opacity(val.opacity)
        } keyframes: { val in
            KeyframeTrack(\.scaleX) {
                
                SpringKeyframe(1.0, duration: 0.8, spring: .bouncy(extraBounce: 0.05))
            }
            KeyframeTrack(\.scaleY) {
                SpringKeyframe(1.0, duration: 0.8, spring: .bouncy(extraBounce: 0.05))
            }
            KeyframeTrack(\.blurRadius) {
                SpringKeyframe(0.0, duration: 0.8, spring: .bouncy(extraBounce: 0.05))
            }
            KeyframeTrack(\.opacity) {
                SpringKeyframe(1.0, duration: 0.8, spring: .bouncy(extraBounce: 0.05))
            }
        }
    }
}

struct PlaybackControls: View {
    @StateObject var firManager: FIRManager = FIRManager.shared
    var group: SQGroup
    var body: some View {
        HStack {
            Button(action: {
                
            }, label: {
                Image(systemName: "backward.fill")
            }).buttonStyle(.plain).padding()
            
            Button(action: {
                print("thtgtngtgrjgrju")
                Task {
                    if let playbackState = group.playbackState {
                        if playbackState.state == .play {
                            print("pausing")
                            try? await firManager.syncManager.pauseSong()
                        } else {
                            print("laying")
                            try? await firManager.syncManager.playSong()
                        }
                    } else {
                        print("playback state nil :((")
                    }
                }
            }, label: {
                let playbackState = group.playbackState ?? SQPlaybackState(id: UUID(), state: .play, timestamp: TimeInterval(0))
                Image(systemName: playbackState.state == PlayPauseState.play ? "pause.fill" : "play.fill").font(.system(size: 60)).symbolEffect(.bounce, value: playbackState.state)
            }).buttonStyle(.plain).padding()
            
            Button {
                Task {
                    try? await firManager.syncManager.nextSong()
                }
            } label: {
                Image(systemName: "forward.fill")
            }.buttonStyle(.plain).padding()

        }.font(.system(size: 50)).padding(30)
    }
}

struct ShowingQueueAnimationValues {
    var scaleX = 2.5
    var scaleY = 2.5
    var blurRadius = 12.0
    var opacity = 0.5
    static let EnterQueue = ShowingQueueAnimationValues()
    static let ExitQueue = ShowingQueueAnimationValues(scaleX: 1.0, scaleY: 1.0, blurRadius: 0.0, opacity: 0.0)
}

extension MusicPlayer.State: Equatable {
    public static func == (lhs: MusicPlayer.State, rhs: MusicPlayer.State) -> Bool {
        return (lhs.playbackStatus) == (rhs.playbackStatus)
    }
}
