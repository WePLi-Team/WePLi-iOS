import Foundation

// REQ-079 · UI-13f — 지금 위플리. 전체 공개를 고른 사람들의 재생만 이름 없이 모은 서버 집계(DEC-004)

public enum LiveTrendSlot: CaseIterable, Equatable, Hashable, Sendable {
  case now
  case dawn
  case commute
  case lunch
  case night

  public var title: String {
    switch self {
    case .now: "지금"
    case .dawn: "새벽"
    case .commute: "출근길"
    case .lunch: "점심"
    case .night: "밤"
    }
  }

  /// 목록 위 설명
  public var subtitle: String {
    switch self {
    case .now: "지금 듣는 사람 수"
    case .dawn: "새벽 0–6시 평균"
    case .commute: "출근길 7–9시 평균"
    case .lunch: "점심 12–13시 평균"
    case .night: "밤 21–24시 평균"
    }
  }
}

public struct LiveTrendSong: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  public let artist: String
  public let listeners: Int
  public var isRising = false

  public init(id: String, title: String, artist: String, listeners: Int, isRising: Bool = false) {
    self.id = id
    self.title = title
    self.artist = artist
    self.listeners = listeners
    self.isRising = isRising
  }
}

public struct LiveTrend: Equatable, Sendable {
  public var listeners: Int
  /// 히어로 곡
  public let hero: LiveTrendSong
  public let rankings: [LiveTrendSlot: [LiveTrendSong]]

  public init(listeners: Int, hero: LiveTrendSong, rankings: [LiveTrendSlot: [LiveTrendSong]]) {
    self.listeners = listeners
    self.hero = hero
    self.rankings = rankings
  }
}
