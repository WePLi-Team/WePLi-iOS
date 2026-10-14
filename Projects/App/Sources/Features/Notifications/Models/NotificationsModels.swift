import Foundation

// REQ-081 · UI-4d

struct AppNotification: Equatable, Identifiable, Sendable {
  enum Group: Equatable, Sendable {
    case today
    case thisWeek

    var title: String {
      switch self {
      case .today: "오늘"
      case .thisWeek: "이번 주"
      }
    }
  }

  enum Kind: Equatable, Sendable {
    /// 마감 임박 — 릴레이 커버
    case relayClosingSoon
    /// 내 추천곡 순위 변동 — 곡 커버
    case rankChanged
    case relayCompleted
    case comment
    case like
    case follow

    /// 사람 알림은 원형 아바타, 곡 · 플리 알림은 사각 썸네일(모서리 8)
    var showsAvatar: Bool {
      switch self {
      case .comment, .like, .follow: true
      case .relayClosingSoon, .rankChanged, .relayCompleted: false
      }
    }
  }

  let id: String
  let group: Group
  let kind: Kind
  let text: String
  /// 「방금」 · 「24분 전」
  let timeText: String
  /// 「투표하기」 · 「듣기」 · 「맞팔로우」
  let actionTitle: String?
  var isRead: Bool
}

enum NotificationPermission: Equatable, Sendable {
  case notDetermined
  case denied
  case authorized

  var showsPrompt: Bool {
    self != .authorized
  }
}
