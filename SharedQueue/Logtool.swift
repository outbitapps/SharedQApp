//
//  LogUtils.swift
//  Playlistlist3
//
//  Created by Payton Curry on 11/29/23.
//

import Foundation

public class Logtool: ObservableObject {
    static var shared = Logtool()
    @Published var logs: [LogMsg] = []
    func log(_ msg: String, _ level: LogLevel = .debug) {
        print("new logmsg: \(msg)")
        Task {@MainActor in
            logs.append(LogMsg(message: msg, level: level, date: Date()))
        }
    }
    func logsToString() -> String {
        var msgs = ""
        for log in logs {
            var thisLine = ""
            thisLine.append("\(log.date.formatted(date: .abbreviated, time: .standard)) [\(log.level == .debug ? "DEBUG" : "ERROR")] \(log.message)")
            msgs.append("\(thisLine)\n")
        }
        return msgs
    }
}
struct LogMsg {
    
    var message: String
    var level: LogLevel
    var date: Date
}

enum LogLevel {
    case debug
    case error
    
}
