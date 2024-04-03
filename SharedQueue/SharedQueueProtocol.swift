import Foundation

struct SQGroup: Identifiable, Codable {
    public var id: String
    public var name: String
    public var owner: SQUser
    public var defaultPermissions: SQDefaultPermissions
    public var members: [SQUserPermissions] = []
    public var connectedMembers: [String] = []
    public var publicGroup: Bool
    public var askToJoin: Bool
    public var wsURL: URL?
    public var currentlyPlaying: SQSong?
    public var previewQueue: [SQQueueItem] = []
    public var playbackState: SQPlaybackState?
    public var groupURL: URL?
    public var joinRequests: [String] = []
}
struct SQPlaybackState: Identifiable, Codable {
    var id: UUID = UUID()
    var state: PlayPauseState
    var timestamp: TimeInterval
}

enum PlayPauseState: Codable {
    case play
    case pause
}

public struct SQSong: Identifiable, Codable {
    public var id: String = UUID().uuidString
    public var title: String
    public var artist: String
    public var albumArt: URL? = nil
    public var colors: [String] = []
    public var textColor: String? = nil
    var duration: TimeInterval
}

public class SQDefaultPermissions: Codable, Identifiable {
    public var id: String
    public var membersCanControlPlayback: Bool
    public var membersCanAddToQueue: Bool

    public init(id: String = UUID().uuidString, membersCanControlPlayback: Bool = true, membersCanAddToQueue: Bool = true) {
        self.id = id
        self.membersCanControlPlayback = membersCanControlPlayback
        self.membersCanAddToQueue = membersCanAddToQueue
    }

    enum CodingKeys: String, CodingKey {
        case id
        case membersCanControlPlayback
        case membersCanAddToQueue
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.membersCanControlPlayback = try container.decode(Bool.self, forKey: .membersCanControlPlayback)
        self.membersCanAddToQueue = try container.decode(Bool.self, forKey: .membersCanAddToQueue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(membersCanControlPlayback, forKey: .membersCanControlPlayback)
        try container.encode(membersCanAddToQueue, forKey: .membersCanAddToQueue)
    }
}

public class SQUser: Identifiable, Codable {
    public var id: String
    public var username: String
    public var email: String?
    public var groups: [String]

    public init(id: String, username: String, email: String? = nil, groups: [String] = []) {
        self.id = id
        self.username = username
        self.email = email
        self.groups = groups
    }

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case groups
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.username = try container.decode(String.self, forKey: .username)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.groups = try container.decode([String].self, forKey: .groups)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encode(groups, forKey: .groups)
    }
}

// Repeat the same process for SQGroup, SQSong, SQDefaultPermissions, SQUserPermissions
public class SQQueueItem: Identifiable, Codable {
    public var id = UUID().uuidString
    public var song: SQSong
    public var addedBy: String

    public init(song: SQSong, addedBy: String) {
        self.song = song
        self.addedBy = addedBy
    }

    // CodingKeys enum to specify keys for encoding and decoding
    enum CodingKeys: String, CodingKey {
        case id
        case song
        case addedBy
    }

    // Decoding initializer
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.song = try container.decode(SQSong.self, forKey: .song)
        self.addedBy = try container.decode(String.self, forKey: .addedBy)
    }

    // Encoding function
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(song, forKey: .song)
        try container.encode(addedBy, forKey: .addedBy)
    }
}

// Repeat the same process for other classes (SQUser, SQGroup, SQSong, SQDefaultPermissions, SQUserPermissions)
public class SQUserPermissions: Codable, Identifiable {
    public var id: String
    public var user: SQUser
    public var canControlPlayback: Bool
    public var canAddToQueue: Bool
    public var lastConnected: Date?

    public init(id: String, user: SQUser, canControlPlayback: Bool = true, canAddToQueue: Bool = true, lastConnected: Date? = nil) {
        self.id = id
        self.user = user
        self.canControlPlayback = canControlPlayback
        self.canAddToQueue = canAddToQueue
        self.lastConnected = lastConnected
    }

    enum CodingKeys: String, CodingKey {
        case id
        case user
        case canControlPlayback
        case canAddToQueue
        case lastConnected
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.user = try container.decode(SQUser.self, forKey: .user)
        self.canControlPlayback = try container.decode(Bool.self, forKey: .canControlPlayback)
        self.canAddToQueue = try container.decode(Bool.self, forKey: .canAddToQueue)
        self.lastConnected = try container.decodeIfPresent(Date.self, forKey: .lastConnected)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(user, forKey: .user)
        try container.encode(canControlPlayback, forKey: .canControlPlayback)
        try container.encode(canAddToQueue, forKey: .canAddToQueue)
        try container.encodeIfPresent(lastConnected, forKey: .lastConnected)
    }
}

struct JoinGroupRequest: Codable {
    var myUID: String
    var groupID: String
}
