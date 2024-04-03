//
//  SpotifyConnectionSheet.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/27/24.
//

import SwiftUI

struct SpotifyConnectionSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var loading = false
    var body: some View {
        VStack {
            Text("Connect to Spotify App").font(.title).fontWeight(.semibold)
            Text("open the Spotify app and start playing a song (any song, it doesn't matter!) once you've done so, press \"Connect\"")
            GradientButton {
                if let sptService = musicService as? SpotifyService {
                    loading = true
                    sptService.connectToSpotify()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: {
                        loading = false
                        dismiss()
                    })
                }
                
            } label: {
                HStack {
                    Text("Connect")
                    Image(systemName: "chevron.right")
                }
            }.frame(height: 70).opacity(loading ? 0.5 : 1.0).overlay {
                if loading {
                    ProgressView()
                }
            }
            
            Button(action: {
                let url = URL(string: "spotify://")!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }, label: {
                Text("Open Spotify").bold()
            }).padding()

        }.padding()
    }
}

#Preview {
    VStack {
        
    }.sheet(isPresented: .constant(true), content: {
        SpotifyConnectionSheet().presentationDetents([.fraction(0.5)]).presentationCornerRadius(50).interactiveDismissDisabled()
    })
}
