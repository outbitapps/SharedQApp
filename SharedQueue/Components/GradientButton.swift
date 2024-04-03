//
//  GradientButton.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import SwiftUI

struct GradientButton<Content: View>: View {
    var onPress: () -> Void
    var label: () -> Content
    var body: some View {
        Button(action: {
            onPress()
        }, label: {
            ZStack {
                RoundedRectangle(cornerRadius: 25.0).foregroundStyle(.linearGradient(colors: [Color.appGradient1, Color.appGradient2], startPoint: .leading, endPoint: .trailing))
                label().foregroundStyle(.white)
            }
        })
    }
}

#Preview {
    GradientButton(onPress: {}, label: {
        Text("Continue")
    }).frame(height: 70)
}
