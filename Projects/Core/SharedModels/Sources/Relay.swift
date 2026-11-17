import Foundation

// DEC-033 · 여러 기능이 함께 쓰는 값 타입 — 기능 폴더에서 옮겨 왔다

public struct Relay: Equatable, Identifiable, Sendable {
  public enum VoteFormat: String, Equatable, Sendable {
    case card
    case worldCup
    case baton

    /// 목록 배지 문구 (원본: 카드 · 월드컵 · 바통)
    public var title: String {
      switch self {
      case .card: "카드"
      case .worldCup: "월드컵"
      case .baton: "바통"
      }
    }
  }

  public enum Status: Equatable, Sendable {
    case live(endsAt: Date)
    case completed
  }

  public let id: String
  public let title: String
  public let voteFormat: VoteFormat
  public let participantCount: Int
  public let status: Status
  /// 내가 곡을 추천했거나 투표한 릴레이
  public let isMine: Bool

  public var endsAt: Date? {
    if case let .live(endsAt) = self.status {
      return endsAt
    }
    return nil
  }

  public var isLive: Bool {
    self.endsAt != nil
  }

  /// 「3,012」 · 바통은 「친구 8」
  public var participantText: String {
    let count = self.participantCount.formatted(.number.grouping(.automatic))
    return self.voteFormat == .baton ? "친구 \(count)" : count
  }

  public init(id: String, title: String, voteFormat: VoteFormat, participantCount: Int, status: Status, isMine: Bool) {
    self.id = id
    self.title = title
    self.voteFormat = voteFormat
    self.participantCount = participantCount
    self.status = status
    self.isMine = isMine
  }
}
