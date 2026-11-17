import Foundation

// REQ-081 · UI-4d

public struct AppNotification: Equatable, Identifiable, Sendable {
  public enum Group: Equatable, Sendable {
    case today
    case thisWeek

    public var title: String {
      switch self {
      case .today: "오늘"
      case .thisWeek: "이번 주"
      }
    }
  }

  public enum Kind: Equatable, Sendable {
    /// 마감 임박 — 릴레이 커버
    case relayClosingSoon
    /// 내 추천곡 순위 변동 — 곡 커버
    case rankChanged
    case relayCompleted
    case comment
    case like
    case follow

    /// 사람 알림은 원형 아바타, 곡 · 플리 알림은 사각 썸네일(모서리 8)
    public var showsAvatar: Bool {
      switch self {
      case .comment, .like, .follow: true
      case .relayClosingSoon, .rankChanged, .relayCompleted: false
      }
    }
  }

  public let id: String
  public let group: Group
  public let kind: Kind
  public let text: String
  /// 「방금」 · 「24분 전」
  public let timeText: String
  /// 「투표하기」 · 「듣기」 · 「맞팔로우」
  public let actionTitle: String?
  public var isRead: Bool
  /// 릴레이 알림이면 그 릴레이 — 누르면 해당 화면으로 간다
  public var relayID: String?

  public init(
    id: String,
    group: Group,
    kind: Kind,
    text: String,
    timeText: String,
    actionTitle: String?,
    isRead: Bool,
    relayID: String? = nil
  ) {
    self.id = id
    self.group = group
    self.kind = kind
    self.text = text
    self.timeText = timeText
    self.actionTitle = actionTitle
    self.isRead = isRead
    self.relayID = relayID
  }
}

public enum NotificationPermission: Equatable, Sendable {
  case notDetermined
  case denied
  case authorized

  public var showsPrompt: Bool {
    self != .authorized
  }
}
