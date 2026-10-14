import Foundation

// REQ-031 · UI-3c

struct RankedSong: Equatable, Identifiable, Sendable {
  var id: String {
    "\(self.rank)|\(self.title)"
  }

  let rank: Int
  let title: String
  let artist: String

  /// 1–3위는 라벤더 · 굵게
  var isTop: Bool {
    self.rank <= 3
  }
}

struct RelayDetail: Equatable, Identifiable, Sendable {
  enum Status: Equatable, Sendable {
    /// 아직 등록된 곡이 없음
    case empty(endsAt: Date)
    case live(endsAt: Date)
    case completed
  }

  let id: String
  let title: String
  /// 「2024.05.03」
  let openedOn: String
  var status: Status
  let participantCount: Int
  let totalSongCount: Int
  let ranking: [RankedSong]
  /// 투표 방식 — 투표 버튼이 카드 넘기기(UI-3b) · 곡 월드컵(UI-8b) 중 어디로 갈지 정한다
  var voteFormat: Relay.VoteFormat = .card

  var endsAt: Date? {
    switch self.status {
    case let .empty(endsAt), let .live(endsAt): endsAt
    case .completed: nil
    }
  }
}

/// 화면에 보이는 상태 — 남은 시간이 0이 되면 완성으로 보여 준다(UI-3c 노트 03).
enum RelayDisplayState: Equatable {
  case empty
  case live
  case completed

  init(_ detail: RelayDetail, now: Date) {
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
enum CountdownFormatter {
  static func string(from now: Date, to end: Date) -> String {
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
