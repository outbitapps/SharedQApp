//
//  MusicService.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import Foundation
import SharedQProtocol

protocol MusicService {
    func getMostRecentSong() async -> SQSong?
    func recentlyPlayed() async -> [SQSong]
    func playSong(song: SQSong) async
    func playAt(timestamp: TimeInterval) async
    func getSongTimestamp() async -> TimeInterval 
    func stopPlayback() async   
    func nextSong() async
    func addQueue(queue: [SQSong]) async
    func pauseSong() async
    func prevSong() async
    func seekTo(timestamp: TimeInterval) async
    func searchFor(_ query: String) async -> [SQSong]
    func registerStateListeners() async
}
