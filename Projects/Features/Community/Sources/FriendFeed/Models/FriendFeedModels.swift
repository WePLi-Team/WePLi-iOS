import Foundation

// REQ-079 · UI-13b — 친구들이 지금 듣는 음악. 듣는 곡 · 반응 수는 서버 값(DEC-004)

public enum FriendReaction: String, CaseIterable, Equatable, Sendable {
  case fire = "🔥"
  case love = "😍"
  case headphones = "🎧"
  case clap = "👏"
}

public struct FriendListening: Equatable, Identifiable, Sendable {
  public let id: String
  /// 「지수」 — 「나」는 isMe
  public let name: String
  public var isMe = false
  public let title: String
  public let artist: String
  /// 지금 듣는 중 — 멈췄으면 「최근 들은 곡」
  public let isPlaying: Bool
  /// 「방금」 · 「3분 전」
  public let timeText: String
  public var reactions: [FriendReaction: Int] = [:]
  /// 내가 누른 반응 — 줄마다 하나
  public var myReaction: FriendReaction?

  /// 「민수님이 지금 듣는 중 · 방금」 — 원본 「민수이」는 조사가 틀려 13a와 같은 「님이」로 쓴다
  public var meta: String {
    "\(self.name)님이 \(self.isPlaying ? "지금 듣는 중" : "최근 들은 곡") · \(self.timeText)"
  }

  /// 같은 반응을 다시 누르면 끄고, 다른 반응을 누르면 바꾼다
  mutating func toggle(_ reaction: FriendReaction) {
    if let mine = self.myReaction {
      self.reactions[mine] = max(0, (self.reactions[mine] ?? 0) - 1)
    }
    if self.myReaction == reaction {
      self.myReaction = nil
      return
    }
    self.myReaction = reaction
    self.reactions[reaction, default: 0] += 1
  }

  public init(
    id: String,
    name: String,
    isMe: Bool = false,
    title: String,
    artist: String,
    isPlaying: Bool,
    timeText: String,
    reactions: [FriendReaction: Int] = [:],
    myReaction: FriendReaction? = nil
  ) {
    self.id = id
    self.name = name
    self.isMe = isMe
    self.title = title
    self.artist = artist
    self.isPlaying = isPlaying
    self.timeText = timeText
    self.reactions = reactions
    self.myReaction = myReaction
  }
}

public struct FriendWeeklySong: Equatable, Identifiable, Sendable {
  public var id: String {
    "\(self.title)|\(self.artist)"
  }

  public let title: String
  public let artist: String
  /// 들은 친구 수
  public let friendCount: Int

  public init(title: String, artist: String, friendCount: Int) {
    self.title = title
    self.artist = artist
    self.friendCount = friendCount
  }
}

public struct FriendFeed: Equatable, Sendable {
  /// 위쪽 줄 — 「나」가 맨 앞
  public var rail: [FriendListening]
  /// 나와 같은 곡을 듣는 친구
  public let sameSong: FriendListening?
  public var feed: [FriendListening]
  public let weekly: [FriendWeeklySong]

  public init(
    rail: [FriendListening],
    sameSong: FriendListening?,
    feed: [FriendListening],
    weekly: [FriendWeeklySong]
  ) {
    self.rail = rail
    self.sameSong = sameSong
    self.feed = feed
    self.weekly = weekly
  }
}
