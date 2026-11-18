import Foundation
import WePLiRelayFeatures

// REQ-020 · UI-12a(DEC-008) — 홈 「내 참여 · 사람」 섹션. 순위 · 점수 · 비율 · 청취자 수는 서버 값(DEC-004)

/// 내 추천곡 · 지금 몇 위(8a)
public struct HomeMyRecommendation: Equatable, Identifiable, Sendable {
  /// 곡 id
  public let id: String
  public let title: String
  public let relayID: String
  public let relayTitle: String
  /// 「2위까지 42점」 · 「1위 유지 중」
  public let gapText: String
  public let rank: Int
  public let change: RankChange

  /// 「첫 사랑이 생각나는 노래 모음 · 2위까지 42점」
  public var relayLine: String {
    "\(self.relayTitle) · \(self.gapText)"
  }

  public init(
    id: String,
    title: String,
    relayID: String,
    relayTitle: String,
    gapText: String,
    rank: Int,
    change: RankChange
  ) {
    self.id = id
    self.title = title
    self.relayID = relayID
    self.relayTitle = relayTitle
    self.gapText = gapText
    self.rank = rank
    self.change = change
  }
}

/// 지금 투표 중인 릴레이(9a) — 마감이 가까운 순
public struct HomeVotingRelay: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  /// 「#첫사랑 #설렘 #2000년대」
  public let tags: String
  public let endsAt: Date
  public let participantCount: Int

  public init(id: String, title: String, tags: String, endsAt: Date, participantCount: Int) {
    self.id = id
    self.title = title
    self.tags = tags
    self.endsAt = endsAt
    self.participantCount = participantCount
  }
}

/// 1위 예측(8d) — 한 번 고르면 바꿀 수 없다
public struct HomePrediction: Equatable, Sendable {
  public struct Option: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    /// 고른 뒤에 보이는 예측 비율(%)
    public var percent: Int

    public init(id: String, title: String, percent: Int) {
      self.id = id
      self.title = title
      self.percent = percent
    }
  }

  public let relayID: String
  /// 「첫 사랑이 생각나는 노래 모음, 최종 1위는?」
  public let question: String
  /// 「8번 중 5번 적중」 — 처음이면 nil
  public let record: String?
  /// 「1일 12시간」
  public let remaining: String
  public var options: [Option]
  /// 고른 곡 — 잠그기 전까지 바꿀 수 있다(DEC-016)
  public var pickedID: Option.ID?
  /// 「예측하기」로 잠갔다 — 비율 · 막대는 이때부터 보인다
  public var isLocked = false

  /// 머리 설명 — 잠그기 전(처음 · 기록) · 잠근 뒤
  public var subtitle: String {
    if self.isLocked {
      return "예측 완료 · 마감되면 결과를 알려드릴게요"
    }
    let lead = self.record ?? "처음이라면 지금 한 번 맞혀보세요"
    return "\(lead) · \(self.remaining) 남음"
  }

  public init(
    relayID: String,
    question: String,
    record: String?,
    remaining: String,
    options: [Option],
    pickedID: Option.ID? = nil,
    isLocked: Bool = false
  ) {
    self.relayID = relayID
    self.question = question
    self.record = record
    self.remaining = remaining
    self.options = options
    self.pickedID = pickedID
    self.isLocked = isLocked
  }
}

/// 친구가 지금 듣는 중(13)
public struct HomeFriendListening: Equatable, Identifiable, Sendable {
  public let id: String
  public let name: String
  /// 듣는 곡 — 오프라인이면 「12분 전」
  public let line: String
  public let isLive: Bool

  public init(id: String, name: String, line: String, isLive: Bool) {
    self.id = id
    self.name = name
    self.line = line
    self.isLive = isLive
  }
}

/// 지금 위플리에서 듣는 중(13 집계)
public struct HomeLiveListening: Equatable, Sendable {
  public struct Song: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let artist: String
    public var listeners: Int

    public init(id: String, title: String, artist: String, listeners: Int) {
      self.id = id
      self.title = title
      self.artist = artist
      self.listeners = listeners
    }
  }

  public var total: Int
  public var songs: [Song]

  public init(total: Int, songs: [Song]) {
    self.total = total
    self.songs = songs
  }
}

public enum HomeText {
  /// 「1,284」
  public static func count(_ value: Int) -> String {
    value.formatted(.number.grouping(.automatic).locale(Locale(identifier: "ko_KR")))
  }

  /// 투표 중 릴레이 남은 시간 — 「1일 2시간」 · 「5시간 12분」(원본 짧은 형식)
  public static func shortRemaining(from now: Date, to endsAt: Date) -> String {
    let seconds = max(0, Int(endsAt.timeIntervalSince(now)))
    let days = seconds / 86400
    let hours = seconds % 86400 / 3600
    return days > 0 ? "\(days)일 \(hours)시간" : "\(hours)시간 \(seconds % 3600 / 60)분"
  }
}
