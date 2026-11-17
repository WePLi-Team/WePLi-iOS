import Foundation

// REQ-038 · UI-8a — 내 추천곡 크레딧 · 역전 알림. 순위 · 점수는 서버 기준(DEC-004)

public struct StandingSong: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  public let artist: String
  /// 추천한 사람 — 내가 추천했으면 「김동 (나)」
  public let recommender: String
  public var score: Int
  /// 오늘 시작 순위 — 변동 = 시작 순위 − 지금 순위
  public let startRank: Int
  public let isMine: Bool

  public init(
    id: String,
    title: String,
    artist: String,
    recommender: String,
    score: Int,
    startRank: Int,
    isMine: Bool
  ) {
    self.id = id
    self.title = title
    self.artist = artist
    self.recommender = recommender
    self.score = score
    self.startRank = startRank
    self.isMine = isMine
  }
}

/// 서버가 내려준 실시간 순위 — 점수 높은 순
public struct RelayStanding: Equatable, Sendable {
  public let relayID: String
  public let title: String
  public let endsAt: Date
  public var songs: [StandingSong]

  public func rank(of id: StandingSong.ID) -> Int? {
    self.songs.firstIndex { $0.id == id }.map { $0 + 1 }
  }

  /// 히어로에 보일 내 곡 — 여러 곡이면 순위가 가장 높은 곡(원본에 규칙 없음)
  public var heroSong: StandingSong? {
    self.songs.first { $0.isMine }
  }

  public init(relayID: String, title: String, endsAt: Date, songs: [StandingSong]) {
    self.relayID = relayID
    self.title = title
    self.endsAt = endsAt
    self.songs = songs
  }
}

/// 순위 변동 — 「▲2」 · 「▼1」 · 「–」
public enum RankChange: Equatable {
  case up(Int)
  case down(Int)
  case same

  public init(startRank: Int, rank: Int) {
    let delta = startRank - rank
    self = delta > 0 ? .up(delta) : delta < 0 ? .down(-delta) : .same
  }

  public var text: String {
    switch self {
    case let .up(value): "▲\(value)"
    case let .down(value): "▼\(value)"
    case .same: "–"
    }
  }
}

public enum StandingText {
  /// 「2,120」
  public static func score(_ value: Int) -> String {
    value.formatted(.number.grouping(.automatic).locale(Locale(identifier: "en_US")))
  }

  /// 「1위까지 200점」 · 「1위 유지 중」
  public static func gap(_ standing: RelayStanding, song: StandingSong) -> String {
    guard let rank = standing.rank(of: song.id), rank > 1 else { return "1위 유지 중" }
    let above = standing.songs[rank - 2]
    return "\(rank - 1)위까지 \(self.score(above.score - song.score))점"
  }

  /// 「▲1 · 오늘」 · 「변동 없음」
  public static func move(_ change: RankChange) -> String {
    change == .same ? "변동 없음" : "\(change.text) · 오늘"
  }

  /// 「실시간 순위 · 1일 12시간 남음」
  public static func remaining(until endsAt: Date, now: Date) -> String {
    let seconds = max(0, Int(endsAt.timeIntervalSince(now)))
    let days = seconds / 86400
    let hours = seconds % 86400 / 3600
    let time = days > 0 ? "\(days)일 \(hours)시간" : "\(hours)시간 \(seconds % 3600 / 60)분"
    return "실시간 순위 · \(time) 남음"
  }
}

/// 위에서 내려오는 역전 알림(3.2초)
public struct ReversalBanner: Equatable, Sendable {
  public let rank: Int
  public let songTitle: String

  public var title: String {
    self.rank == 1 ? "1위 탈환!" : "역전!"
  }

  public var body: String {
    "내가 추천한 ‘\(self.songTitle)’가 \(self.rank)위로 올랐어요"
  }

  public init(rank: Int, songTitle: String) {
    self.rank = rank
    self.songTitle = songTitle
  }
}
