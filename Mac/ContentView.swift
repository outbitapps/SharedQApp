//
//  ContentView.swift
//  Mac
//
//  Created by Payton Curry on 4/7/24.
//

import SwiftUI
import SharedQProtocol

struct ContentView: View {
    @AppStorage("completedOnboarding") var completedOnboarding = false
    @Environment(\.openWindow) var openWindow
    @EnvironmentObject var firManager: FIRManager
    var body: some View {
        if completedOnboarding {
            NavigationView {
                List {
                    ForEach(firManager.groups) { group in
                        VStack {
                            NavigationLink {
                                ConfirmJoinView(group: group)
                            } label: {
                                HomeGroupCell(group: group)
                            }

                            Divider()
                        }
                    }
                }.listStyle(.sidebar)
            }
        } else {
            VStack {
                ProgressView().onAppear(perform: {
                    openWindow(id: "onboarding")
                })
                Button(action: {
                    openWindow(id: "onboarding")
                }, label: {
                    Text("Setup window not showing?").foregroundStyle(.blue)
                }).buttonStyle(.plain)
            }
        }
    }
}

struct HomeGroupCell: View {
    var group: SQGroup
    @EnvironmentObject var firManager: FIRManager
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(group.name).font(.title2).fontWeight(.semibold)
                Text("^[\(group.members.count + 1) Members](inflect:true) ∙ \(group.connectedMembers.count) right now").foregroundStyle(.secondary)
                Text("Last used \(lastConnectedString())").foregroundStyle(.secondary)
                Text("\(group.publicGroup ? "Public" : "Private")").foregroundStyle(.secondary)
            }
            Spacer()
            if let currentSong = group.currentlyPlaying {
                AsyncImage(url: currentSong.albumArt) { img in
                    img.resizable().frame(width: 50, height: 50).cornerRadius(5.0)
                } placeholder: {
                    Image(.mediaItemPlaceholder).resizable().frame(width: 50, height: 50).cornerRadius(5.0)
                }

            }
        }
    }
    func lastConnectedString() -> String {
        var lastConnectedDate = group.members.first(where: {$0.user.id == firManager.currentUser!.id})?.lastConnected
        lastConnectedDate = Date().addingTimeInterval(-60*60*24*12)
        if let lastConnectedDate = lastConnectedDate {
            return lastConnectedDate.timeAgoDisplay()
        } else {
            return "Never"
        }
        
    }
}

#Preview {
    ContentView()
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
