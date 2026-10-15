import Foundation

// REQ-079 · UI-13b — 친구들이 지금 듣는 음악. 듣는 곡 · 반응 수는 서버 값(DEC-004)

enum FriendReaction: String, CaseIterable, Equatable, Sendable {
  case fire = "🔥"
  case love = "😍"
  case headphones = "🎧"
  case clap = "👏"
}

struct FriendListening: Equatable, Identifiable, Sendable {
  let id: String
  /// 「지수」 — 「나」는 isMe
  let name: String
  var isMe = false
  let title: String
  let artist: String
  /// 지금 듣는 중 — 멈췄으면 「최근 들은 곡」
  let isPlaying: Bool
  /// 「방금」 · 「3분 전」
  let timeText: String
  var reactions: [FriendReaction: Int] = [:]
  /// 내가 누른 반응 — 줄마다 하나
  var myReaction: FriendReaction?

  /// 「민수님이 지금 듣는 중 · 방금」 — 원본 「민수이」는 조사가 틀려 13a와 같은 「님이」로 쓴다
  var meta: String {
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
}

struct FriendWeeklySong: Equatable, Identifiable, Sendable {
  var id: String {
    "\(self.title)|\(self.artist)"
  }

  let title: String
  let artist: String
  /// 들은 친구 수
  let friendCount: Int
}

struct FriendFeed: Equatable, Sendable {
  /// 위쪽 줄 — 「나」가 맨 앞
  var rail: [FriendListening]
  /// 나와 같은 곡을 듣는 친구
  let sameSong: FriendListening?
  var feed: [FriendListening]
  let weekly: [FriendWeeklySong]
}
