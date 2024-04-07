//
//  GroupCreatedView.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import SwiftUI
import SharedQProtocol

struct GroupCreatedView: View {
    var group: SQGroup
    @State var backgroundColor: Color = Color.secondary
    @State var bottomColor: Color = Color.secondary
    @Environment(\.dismiss) var dismiss
    @State var copiedURL = false
    @State var isColorDark = false
    var body: some View {
        ZStack {
            if let currentSong = group.currentlyPlaying {
                LinearGradient(colors: currentSong.colors.toColor(), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            }
            VStack {
                Text("Your Group").font(.title2).fontWeight(.semibold)
                Text(group.name).font(.largeTitle).bold()
                Text("has been successfully created!").font(.title2).fontWeight(.semibold)
                Text("we automatically added your most recently played song to the start of the queue. feel free to change the queue however you’d like!").foregroundStyle(.secondary)
                Spacer()
                Text("Want to invite some people?").font(.title2).fontWeight(.semibold)
                HStack {
                    Button(action: {
                        if let groupURL = group.groupURL {
                            UIPasteboard.general.url = groupURL
                            copiedURL = true
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                    }, label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15.0).foregroundStyle(backgroundColor.secondary).opacity(0.2).overlay {
                                RoundedRectangle(cornerRadius: 15.0).stroke(backgroundColor.secondary, lineWidth: 1.5)
                            }
                            Text("\(copiedURL ? Image(systemName: "checkmark") : Image(systemName: "link")) Copy Link").foregroundStyle(backgroundColor).font(.title3).bold().symbolEffect(.bounce, value: copiedURL)
                        }
                    }).frame(height: 50).padding(5)
                    Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15.0).foregroundStyle(backgroundColor.secondary).opacity(0.2).overlay {
                                RoundedRectangle(cornerRadius: 15.0).stroke(backgroundColor.secondary, lineWidth: 1.5)
                            }
                            Text("\(Image(systemName: "qrcode")) QR Code").foregroundStyle(backgroundColor).font(.title3).bold()
                        }
                    }).frame(height: 50).padding(5)
                    
                }
                Spacer()
                AsyncImage(url: group.currentlyPlaying?.albumArt) { img in
                    img.resizable().aspectRatio(contentMode: .fit).cornerRadius(15.0).padding(20)
                } placeholder: {
                    Image(.mediaItemPlaceholder).resizable().aspectRatio(contentMode: .fit).cornerRadius(15.0).padding(20)
                }
                Text(group.currentlyPlaying?.title ?? "No sound found!").font(.title2).fontWeight(.semibold)
                Text(group.currentlyPlaying?.artist ?? "").font(.title3).fontWeight(.semibold).opacity(0.8)
                Spacer()
                Button(action: {
                    dismiss()
                }, label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15.0).foregroundStyle(bottomColor.secondary).opacity(0.5).overlay {
                            RoundedRectangle(cornerRadius: 15.0).stroke(bottomColor.secondary, lineWidth: 1.5)
                        }
                        Text("Start Listening").foregroundStyle(bottomColor).font(.title3).bold()
                    }
                }).frame(height: 70).padding(5)

            }.padding().foregroundStyle(isColorDark ? .white : .black)
        }.onAppear
        {
            if let currentlyPlaying = group.currentlyPlaying {
                backgroundColor = Color.white.fromHex(currentlyPlaying.colors[1]) ?? Color.secondary
                bottomColor = Color.white.fromHex(currentlyPlaying.colors[0]) ?? Color.secondary
            } else {
                backgroundColor = Color.secondary
                bottomColor = Color.white
            }
            isColorDark = bottomColor.isDark
        }
    }
}

extension [String] {
    func toColor() -> [SwiftUI.Color] {
        var colors: [SwiftUI.Color] = []
        for hex in self {
            colors.append(SwiftUI.Color.white.fromHex(hex)!)
        }
        return colors
    }
}

extension Color {
    var isDark: Bool {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        guard UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: nil) else {
            return false
        }
        
        let lum = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        return lum < 0.5
    }
}
