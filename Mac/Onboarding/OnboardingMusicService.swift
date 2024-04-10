//
//  OnboardingMusicService.swift
//  Mac
//
//  Created by Payton Curry on 4/7/24.
//

import SwiftUI
import MusicKit

struct OnboardingMusicService: View {
    @EnvironmentObject var obPath: OBPath
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack {
            Text("Music Service").font(.title).fontWeight(.semibold)
            Text("Shared Queue supports most streaming services. choose which one you’d like to use").foregroundStyle(.secondary)
            List {
                MusicServiceCard(
                    image: .appleMusicIcon,
                    title: "Apple Music") {
                        Task {
                            await appleMusicAuth()
                        }
                    }
                MusicServiceCard(image: .spotifyIcon, title: "Spotify (Coming Soon)") {
                    
                }.disabled(true)
            }.listStyle(.automatic)
        }.padding().frame(maxWidth: .infinity, maxHeight: .infinity).background {
            if colorScheme == .dark {
                Color.black.frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
            } else {
                Color.white.frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
            }
        }
    }
    func appleMusicAuth() async {
        var res = await MusicAuthorization.request()
        print(res)
        switch res {
            case .authorized:
                obPath.path.append("final-notes")
            default:
                break
        }
    }
}

#Preview {
    OnboardingMusicService()
}

struct MusicServiceCard: View {
    var image: ImageResource
    var title: String
    var onPress: () -> Void
    var body: some View {
            HStack {
                    Image(image).resizable().frame(width: 70, height: 70).padding()
                    Text(title).font(.title2).fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right").padding()
            }.onTapGesture {
                onPress()
            }
    }
}
