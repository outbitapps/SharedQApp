//
//  OnboardingFinal.swift
//  Mac
//
//  Created by Payton Curry on 4/7/24.
//

import SwiftUI

struct OnboardingFinal: View {
    @Environment(\.dismissWindow) var dismiss
    @AppStorage("completedOnboarding") var completedOnboarding = false
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack(alignment: .leading) {
            Text("Final Notes").font(.title).fontWeight(.semibold)
            Text("you're ready to use Shared Queue, a shared music queue which works regardless of what streaming service you use. but first, here's how Shared Queue works:")
            HowItWorksCard(systemImage: "person.3.fill", title: "Groups", content: "Queues are organized into \"Groups\", which are different groups which you can be apart of.").padding(.vertical, 5)
            HowItWorksCard(systemImage: "playpause.fill", title: "Playback Controls", content: "By default, anybody in a group can control playback controls (play/pause, forward/backward, etc.)").padding(.vertical, 5)
            HowItWorksCard(systemImage: "hand.raised.fill", title: "Who can Join", content: "By default, groups are set to private which means that only the group's creator can invite people. Public groups are discoverable and joinable by anybody, and are best suited for large communities.").padding(.vertical, 5)
            HowItWorksCard(systemImage: "speaker.wave.3", title: "Audio Playback", content: "As soon as you join a group, the audio from that group starts playing. Don't be startled, it's okay!").padding(.vertical, 5)
            Button {
                completedOnboarding = true
                dismiss(id: "onboarding")
            } label: {
                HStack {
                    Text("Let's do this!")
                    Image(systemName: "party.popper.fill")
                }.padding()
            }.keyboardShortcut(.defaultAction).frame(height: 70).padding()

        }.padding().frame(maxWidth: .infinity, maxHeight: .infinity).background {
            if colorScheme == .dark {
                Color.black.frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
            } else {
                Color.white.frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
            }
        }
    }
}

#Preview {
    OnboardingFinal()
}

struct HowItWorksCard: View {
    var systemImage: String
    var title: String
    var content: String
    var body: some View {
        HStack {
            Image(systemName: systemImage).font(.title3).frame(width: 50)
            VStack(alignment: .leading) {
                Text(title).font(.title3).bold()
                Text(content).font(.caption)
            }
        }.opacity(0.8)
    }
}