//
//  MacApp.swift
//  Mac
//
//  Created by Payton Curry on 4/7/24.
//

import SwiftUI
import Combine

var musicService = AppleMusicService()

class TransparentWindowView: NSView {
  override func viewDidMoveToWindow() {
      window?.backgroundColor = NSColor(red: 1, green: 1, blue: 1, alpha: 0.05)
    super.viewDidMoveToWindow()
  }
}

struct VisualEffect: NSViewRepresentable {
  func makeNSView(context: Self.Context) -> NSView { return TransparentWindowView() }
  func updateNSView(_ nsView: NSView, context: Context) { }
}

var enterFullscreenNotification = NotificationCenter.default.publisher(for: NSWindow.willEnterFullScreenNotification)
var exitFullscreenNotification = NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)
@main
struct MacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(FIRManager.shared)
        }.windowStyle(.titleBar).windowToolbarStyle(.expanded)
        WindowGroup("Setup", id: "onboarding") {
            OnboardingAuth().background(VisualEffect()).environmentObject(FIRManager.shared).onAppear(perform: {
                for window in NSApplication.shared.windows {
                    if window.title == "Setup" {
                        window.level = .floating
                    }
                }
            })
        }.windowStyle(.hiddenTitleBar)
        WindowGroup("Group", id: "groupconnectedview") {
            GroupConnectedView().environmentObject(FIRManager.shared)
        }
    }
}
