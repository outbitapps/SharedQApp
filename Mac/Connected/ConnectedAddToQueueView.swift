//
//  ConnectedAddToQueueView.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/27/24.
//

import SwiftUI
import SharedQProtocol

struct ConnectedAddToQueueView: View {
    @State var searchQuery = ""
    @State var results: [SQSong] = []
    @State var recentlyPlayed: [SQSong] = []
    @State var loading = false
    @State var loadingRecentlyPlayed = false
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack {
            TextField("Search for a song...", text: $searchQuery, onCommit: {
                withAnimation {
                    loading = true
                }
                Task {
                    results = await musicService.searchFor(searchQuery)
                    loading = false
                }
            }).textFieldStyle(.roundedBorder).padding()
            Spacer()
            List {
                Section("Search") {
                    if loading {
                        ProgressView()
                    } else {
                        ForEach(results) { result in
                            songCell(result)
                        }
                    }
                }
                Section("Recently Played") {
                    if loadingRecentlyPlayed {
                        ProgressView()
                    } else {
                        ForEach(recentlyPlayed) { song in
                            songCell(song)
                        }
                    }
                }
            }.onAppear {
                loadingRecentlyPlayed = true
                Task {
                    recentlyPlayed = await musicService.recentlyPlayed()
                    loadingRecentlyPlayed = false
                }
            }
        }
    }
    @ViewBuilder func songCell(_ result: SQSong) -> some View {
        Button(action: {
            Task {
                try? await FIRManager.shared.syncManager.addToQueue(song: result, user: FIRManager.shared.currentUser!)
//                await UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
            }
        }, label: {
            HStack {
                AsyncImage(url: result.albumArt) { img in
                    img.resizable().aspectRatio(contentMode: .fit).frame(width: 50, height: 50).cornerRadius(10.0)
                } placeholder: {
                    Image(.mediaItemPlaceholder).resizable().aspectRatio(contentMode: .fit).frame(width: 50, height: 50).cornerRadius(10.0)
                }
                VStack(alignment: .leading) {
                    Text(result.title).fontWeight(.medium)
                    Text(result.artist).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "plus.circle")
            }.padding()
        }).buttonStyle(.plain)
    }
}

#Preview {
    ConnectedAddToQueueView()
}

