//
//  SignInWithGoogleButton.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import SwiftUI

struct SignInWithGoogleButton: View {
    var onPress: () -> Void
    var body: some View {
        Button(action: {
            onPress()
        }, label: {
            ZStack {
                RoundedRectangle(cornerRadius: 15.0).foregroundStyle(.white)
                HStack {
                    SwiftUI.Image( .googleLogo).resizable().frame(width: 25, height: 25)
                    Text("Continue with Google").font(.title3).fontWeight(.medium).fontDesign(.rounded)
                }
            }.foregroundStyle(.black)
        })
    }
}

#Preview {
    OnboardingAuth()
}
