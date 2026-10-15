import Foundation

// REQ-110 · UI-7a — 공지 · 이벤트. 글 · 고정 · 읽음은 서버 값(DEC-004)

struct Notice: Equatable, Identifiable, Sendable {
  enum Kind: CaseIterable, Equatable, Sendable {
    case notice
    case event

    /// 세그먼트 · 상세 제목
    var title: String {
      switch self {
      case .notice: "공지"
      case .event: "이벤트"
      }
    }
  }

  enum EventStatus: Equatable, Sendable {
    case ongoing
    case ended

    var title: String {
      switch self {
      case .ongoing: "진행 중"
      case .ended: "종료"
      }
    }
  }

  let id: String
  let kind: Kind
  let title: String
  /// 「2026.10.08」 · 이벤트는 기간(「~ 2026.10.31」)
  let dateText: String
  let body: String
  /// 「중요」 — 맨 위에 고정
  var isPinned = false
  var eventStatus: EventStatus?
  /// 이벤트 이미지 — 아직 없어 자리만 둔다
  var hasImage = false
  var isUnread = false
}

extension [Notice] {
  /// 탭에 보일 글 — 「중요」를 맨 위에 고정하고 나머지는 받은 순서(최신순)
  func list(for kind: Notice.Kind) -> [Notice] {
    let items = self.filter { $0.kind == kind }
    return items.filter(\.isPinned) + items.filter { !$0.isPinned }
  }
}
