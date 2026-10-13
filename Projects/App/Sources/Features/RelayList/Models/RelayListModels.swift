import Foundation

// REQ-030 · UI-10a

struct Relay: Equatable, Identifiable, Sendable {
  enum VoteFormat: String, Equatable, Sendable {
    case card
    case worldCup
    case baton

    /// 목록 배지 문구 (원본: 카드 · 월드컵 · 바통)
    var title: String {
      switch self {
      case .card: "카드"
      case .worldCup: "월드컵"
      case .baton: "바통"
      }
    }
  }

  enum Status: Equatable, Sendable {
    case live(endsAt: Date)
    case completed
  }

  let id: String
  let title: String
  let voteFormat: VoteFormat
  let participantCount: Int
  let status: Status
  /// 내가 곡을 추천했거나 투표한 릴레이
  let isMine: Bool

  var endsAt: Date? {
    if case let .live(endsAt) = self.status { return endsAt }
    return nil
  }

  var isLive: Bool {
    self.endsAt != nil
  }

  /// 「3,012」 · 바통은 「친구 8」
  var participantText: String {
    let count = self.participantCount.formatted(.number.grouping(.automatic))
    return self.voteFormat == .baton ? "친구 \(count)" : count
  }
}

enum RelayFilter: CaseIterable, Equatable, Sendable {
  case live
  case closingSoon
  case completed
  case mine

  var title: String {
    switch self {
    case .live: "진행 중"
    case .closingSoon: "곧 마감"
    case .completed: "완성"
    case .mine: "참여 중"
    }
  }
}

/// 필터 하나를 적용한 화면 내용
struct RelaySections: Equatable {
  /// 「진행 중」에서만: 마감이 가장 가까운 릴레이 하나
  var featured: Relay?
  var list: [Relay]

  var isEmpty: Bool {
    self.featured == nil && self.list.isEmpty
  }

  /// UI-10a 규칙
  /// - 진행 중: 가장 임박한 1개를 피처 카드로 올리고 목록에서 뺀다
  /// - 곧 마감: 진행 중을 마감 임박순으로 정렬해 상위 2개
  /// - 완성: 완성된 릴레이
  /// - 참여 중: 내가 참여한 릴레이
  static func make(filter: RelayFilter, relays: [Relay]) -> RelaySections {
    let live = relays.filter(\.isLive)
    let bySoonest = live.sorted { ($0.endsAt ?? .distantFuture) < ($1.endsAt ?? .distantFuture) }
    switch filter {
    case .live:
      guard let featured = bySoonest.first else { return RelaySections(list: []) }
      return RelaySections(featured: featured, list: live.filter { $0.id != featured.id })
    case .closingSoon:
      return RelaySections(list: Array(bySoonest.prefix(2)))
    case .completed:
      return RelaySections(list: relays.filter { !$0.isLive })
    case .mine:
      return RelaySections(list: relays.filter(\.isMine))
    }
  }
}

/// 남은 시간 표기 — 1일 이상 「N일 N시간」, 미만 「H:MM:SS」 (UI-9a · UI-10a)
enum RemainingTimeFormatter {
  static func string(from now: Date, to end: Date) -> String {
    var seconds = max(0, Int(end.timeIntervalSince(now)))
    let days = seconds / 86400
    seconds %= 86400
    let hours = seconds / 3600
    seconds %= 3600
    let minutes = seconds / 60
    seconds %= 60
    if days > 0 {
      return "\(days)일 \(hours)시간"
    }
    return String(format: "%d:%02d:%02d", hours, minutes, seconds)
  }
}
