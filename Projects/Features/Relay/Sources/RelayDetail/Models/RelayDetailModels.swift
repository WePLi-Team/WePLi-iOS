import Foundation
import WePLiSharedModels

// REQ-031 · UI-3c

public struct RankedSong: Equatable, Identifiable, Sendable {
  public var id: String {
    "\(self.rank)|\(self.title)"
  }

  public let rank: Int
  public let title: String
  public let artist: String

  /// 1–3위는 라벤더 · 굵게
  public var isTop: Bool {
    self.rank <= 3
  }

  public init(rank: Int, title: String, artist: String) {
    self.rank = rank
    self.title = title
    self.artist = artist
  }
}

public struct RelayDetail: Equatable, Identifiable, Sendable {
  public enum Status: Equatable, Sendable {
    /// 아직 등록된 곡이 없음
    case empty(endsAt: Date)
    case live(endsAt: Date)
    case completed
  }

  public let id: String
  public let title: String
  /// 「2024.05.03」
  public let openedOn: String
  public var status: Status
  public let participantCount: Int
  public let totalSongCount: Int
  public let ranking: [RankedSong]
  /// 투표 방식 — 투표 버튼이 카드 넘기기(UI-3b) · 곡 월드컵(UI-8b) 중 어디로 갈지 정한다
  public var voteFormat: Relay.VoteFormat = .card

  public var endsAt: Date? {
    switch self.status {
    case let .empty(endsAt), let .live(endsAt): endsAt
    case .completed: nil
    }
  }

  public init(
    id: String,
    title: String,
    openedOn: String,
    status: Status,
    participantCount: Int,
    totalSongCount: Int,
    ranking: [RankedSong],
    voteFormat: Relay.VoteFormat = .card
  ) {
    self.id = id
    self.title = title
    self.openedOn = openedOn
    self.status = status
    self.participantCount = participantCount
    self.totalSongCount = totalSongCount
    self.ranking = ranking
    self.voteFormat = voteFormat
  }
}

/// 화면에 보이는 상태 — 남은 시간이 0이 되면 완성으로 보여 준다(UI-3c 노트 03).
public enum RelayDisplayState: Equatable {
  case empty
  case live
  case completed

  public init(_ detail: RelayDetail, now: Date) {
    switch detail.status {
    case .completed:
      self = .completed
    case let .empty(endsAt):
      self = now >= endsAt ? .completed : .empty
    case let .live(endsAt):
      self = now >= endsAt ? .completed : .live
    }
  }
}

/// 3c 타이머 표기 — 「1일 12시간 10분 15초」
public enum CountdownFormatter {
  public static func string(from now: Date, to end: Date) -> String {
    var seconds = max(0, Int(end.timeIntervalSince(now)))
    let days = seconds / 86400
    seconds %= 86400
    let hours = seconds / 3600
    seconds %= 3600
    let minutes = seconds / 60
    seconds %= 60
    return "\(days)일 \(hours)시간 \(minutes)분 \(seconds)초"
  }
}
