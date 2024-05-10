//
//  OnboardingContainer.swift
//  SharedQueue
//
//  Created by Payton Curry on 4/16/24.
//

import SwiftUI
import UIPilot

struct OnboardingContainer: View {
    @StateObject var pilot = UIPilot(initial: OnboardingPages.auth)
    var body: some View {
        UIPilotHost(pilot) { route in
            switch route {
            case .auth: OnboardingAuth()
            case .musicService: OnboardingMusicService()
            case .finalNotes: OnboardingFinal()
            }
        }.ignoresSafeArea()
    }
}

#Preview {
    OnboardingContainer()
}
