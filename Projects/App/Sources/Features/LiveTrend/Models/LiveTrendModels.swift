import Foundation

// REQ-079 · UI-13f — 지금 위플리. 전체 공개를 고른 사람들의 재생만 이름 없이 모은 서버 집계(DEC-004)

enum LiveTrendSlot: CaseIterable, Equatable, Hashable, Sendable {
  case now
  case dawn
  case commute
  case lunch
  case night

  var title: String {
    switch self {
    case .now: "지금"
    case .dawn: "새벽"
    case .commute: "출근길"
    case .lunch: "점심"
    case .night: "밤"
    }
  }

  /// 목록 위 설명
  var subtitle: String {
    switch self {
    case .now: "지금 듣는 사람 수"
    case .dawn: "새벽 0–6시 평균"
    case .commute: "출근길 7–9시 평균"
    case .lunch: "점심 12–13시 평균"
    case .night: "밤 21–24시 평균"
    }
  }
}

struct LiveTrendSong: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  let artist: String
  let listeners: Int
  var isRising = false
}

struct LiveTrend: Equatable, Sendable {
  var listeners: Int
  /// 히어로 곡
  let hero: LiveTrendSong
  let rankings: [LiveTrendSlot: [LiveTrendSong]]
}
