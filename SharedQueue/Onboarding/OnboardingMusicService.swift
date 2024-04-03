//
//  OnboardingMusicService.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import MusicKit
import SwiftUI

struct OnboardingMusicService: View {
    @EnvironmentObject var obPath: OnboardingPath
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.appGradient1, Color.appGradient2], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack {
                Text("Music Provider").font(.title).fontWeight(.semibold)
                Text("Shared Queue supports most streaming services. choose which one you'd like to use.")
                Spacer()
                ZStack {
                    Rectangle()
                    ScrollView {
                        MusicServiceCard(image: .appleMusicIcon, title: "Apple Music") {
                            Task {
                                await appleMusicAuth()
                            }
                        }.padding(.vertical, 15)
                        MusicServiceCard(image: .spotifyIcon, title: "Spotify") {
                                SpotifyAuthService.shared.openSpotifyAuth()
                            obPath.path.append("final-notes")
                        }
                    }
                }.cornerRadius(50).ignoresSafeArea().frame(height: 450)
            }
        }.preferredColorScheme(.dark).onAppear(perform: {
            print(obPath.path)
        })
    }

    func appleMusicAuth() async {
        var res = await MusicAuthorization.request()
        switch res {
            case .authorized:
                obPath.path.append("final-notes")
            default:
                break
        }
    }
}

struct MusicServiceCard: View {
    var image: ImageResource
    var title: String
    var onPress: () -> Void
    var body: some View {
        Button(action: {
            onPress()
        }, label: {
            ZStack {
                RoundedRectangle(cornerRadius: 35).opacity(0).overlay(
                    RoundedRectangle(cornerRadius: 35).stroke(Color.gray, lineWidth: 1.5)
                )
                HStack {
                    Image(image).resizable().frame(width: 70, height: 70).padding()
                    Text(title).font(.title2).fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right").padding()
                }
            }.foregroundStyle(.black)
        }).padding(.horizontal, 15)
    }
}

#Preview {
    OnboardingMusicService().environmentObject(OnboardingPath())
}
