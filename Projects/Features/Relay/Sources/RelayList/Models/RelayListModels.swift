import Foundation
import WePLiSharedModels

// REQ-030 · UI-10a

public enum RelayFilter: CaseIterable, Equatable, Sendable {
  case live
  case closingSoon
  case completed
  case mine

  public var title: String {
    switch self {
    case .live: "진행 중"
    case .closingSoon: "곧 마감"
    case .completed: "완성"
    case .mine: "참여 중"
    }
  }
}

/// 필터 하나를 적용한 화면 내용
public struct RelaySections: Equatable {
  /// 「진행 중」에서만: 마감이 가장 가까운 릴레이 하나
  public var featured: Relay?
  public var list: [Relay]

  public var isEmpty: Bool {
    self.featured == nil && self.list.isEmpty
  }

  /// UI-10a 규칙
  /// - 진행 중: 가장 임박한 1개를 피처 카드로 올리고 목록에서 뺀다
  /// - 곧 마감: 진행 중을 마감 임박순으로 정렬해 상위 2개
  /// - 완성: 완성된 릴레이
  /// - 참여 중: 내가 참여한 릴레이
  public static func make(filter: RelayFilter, relays: [Relay]) -> RelaySections {
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

  public init(featured: Relay? = nil, list: [Relay]) {
    self.featured = featured
    self.list = list
  }
}
