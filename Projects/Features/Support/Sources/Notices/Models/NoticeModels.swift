import Foundation

// REQ-110 · UI-7a — 공지 · 이벤트. 글 · 고정 · 읽음은 서버 값(DEC-004)

public struct Notice: Equatable, Identifiable, Sendable {
  public enum Kind: CaseIterable, Equatable, Sendable {
    case notice
    case event

    /// 세그먼트 · 상세 제목
    public var title: String {
      switch self {
      case .notice: "공지"
      case .event: "이벤트"
      }
    }
  }

  public enum EventStatus: Equatable, Sendable {
    case ongoing
    case ended

    public var title: String {
      switch self {
      case .ongoing: "진행 중"
      case .ended: "종료"
      }
    }
  }

  /// 이벤트 배너 — 작은 글 · 큰 글, 진행 중이면 상세 아래 버튼
  public struct Banner: Equatable, Sendable {
    /// 「위플리 인스타그램 OPEN!」
    public let kicker: String
    /// 「감성 가득한 일상 보러가기」
    public let head: String
    /// 「인스타그램에서 팔로우하기」 — 없으면 버튼 없음
    public var action: String?
    /// 미결정 — 버튼이 여는 곳(원본에는 동작이 없다)
    public var actionURL: URL?

    public init(kicker: String, head: String, action: String? = nil, actionURL: URL? = nil) {
      self.kicker = kicker
      self.head = head
      self.action = action
      self.actionURL = actionURL
    }
  }

  public let id: String
  public let kind: Kind
  public let title: String
  /// 「2026.10.08」 · 이벤트는 기간(「~ 2026.10.31」)
  public let dateText: String
  public let body: String
  /// 「중요」 — 맨 위에 고정
  public var isPinned = false
  public var eventStatus: EventStatus?
  /// 이벤트 이미지 — 아직 없어 자리만 둔다
  public var hasImage = false
  public var isUnread = false
  public var banner: Banner?

  /// 상세 아래 그라데이션 버튼 — 진행 중 이벤트에만
  public var eventAction: Banner? {
    guard self.eventStatus == .ongoing, let banner = self.banner, banner.action != nil else { return nil }
    return banner
  }

  public init(
    id: String,
    kind: Kind,
    title: String,
    dateText: String,
    body: String,
    isPinned: Bool = false,
    eventStatus: EventStatus? = nil,
    hasImage: Bool = false,
    isUnread: Bool = false,
    banner: Banner? = nil
  ) {
    self.id = id
    self.kind = kind
    self.title = title
    self.dateText = dateText
    self.body = body
    self.isPinned = isPinned
    self.eventStatus = eventStatus
    self.hasImage = hasImage
    self.isUnread = isUnread
    self.banner = banner
  }
}

public extension [Notice] {
  /// 탭에 보일 글 — 「중요」를 맨 위에 고정하고 나머지는 받은 순서(최신순)
  func list(for kind: Notice.Kind) -> [Notice] {
    let items = self.filter { $0.kind == kind }
    return items.filter(\.isPinned) + items.filter { !$0.isPinned }
  }
}
