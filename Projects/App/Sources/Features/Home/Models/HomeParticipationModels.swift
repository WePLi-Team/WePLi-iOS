import Foundation

// REQ-020 · UI-12a(DEC-008) — 홈 「내 참여 · 사람」 섹션. 순위 · 점수 · 비율 · 청취자 수는 서버 값(DEC-004)

/// 내 추천곡 · 지금 몇 위(8a)
struct HomeMyRecommendation: Equatable, Identifiable, Sendable {
  /// 곡 id
  let id: String
  let title: String
  let relayID: String
  let relayTitle: String
  /// 「2위까지 42점」 · 「1위 유지 중」
  let gapText: String
  let rank: Int
  let change: RankChange

  /// 「첫 사랑이 생각나는 노래 모음 · 2위까지 42점」
  var relayLine: String {
    "\(self.relayTitle) · \(self.gapText)"
  }
}

/// 지금 투표 중인 릴레이(9a) — 마감이 가까운 순
struct HomeVotingRelay: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  /// 「#첫사랑 #설렘 #2000년대」
  let tags: String
  let endsAt: Date
  let participantCount: Int
}

/// 1위 예측(8d) — 한 번 고르면 바꿀 수 없다
struct HomePrediction: Equatable, Sendable {
  struct Option: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    /// 고른 뒤에 보이는 예측 비율(%)
    var percent: Int
  }

  let relayID: String
  /// 「첫 사랑이 생각나는 노래 모음, 최종 1위는?」
  let question: String
  /// 「8번 중 5번 적중」 — 처음이면 nil
  let record: String?
  /// 「1일 12시간」
  let remaining: String
  var options: [Option]
  /// 고른 곡 — 잠그기 전까지 바꿀 수 있다(DEC-016)
  var pickedID: Option.ID?
  /// 「예측하기」로 잠갔다 — 비율 · 막대는 이때부터 보인다
  var isLocked = false

  /// 머리 설명 — 잠그기 전(처음 · 기록) · 잠근 뒤
  var subtitle: String {
    if self.isLocked {
      return "예측 완료 · 마감되면 결과를 알려드릴게요"
    }
    let lead = self.record ?? "처음이라면 지금 한 번 맞혀보세요"
    return "\(lead) · \(self.remaining) 남음"
  }
}

/// 친구가 지금 듣는 중(13)
struct HomeFriendListening: Equatable, Identifiable, Sendable {
  let id: String
  let name: String
  /// 듣는 곡 — 오프라인이면 「12분 전」
  let line: String
  let isLive: Bool
}

/// 지금 위플리에서 듣는 중(13 집계)
struct HomeLiveListening: Equatable, Sendable {
  struct Song: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let artist: String
    var listeners: Int
  }

  var total: Int
  var songs: [Song]
}

enum HomeText {
  /// 「1,284」
  static func count(_ value: Int) -> String {
    value.formatted(.number.grouping(.automatic).locale(Locale(identifier: "ko_KR")))
  }

  /// 투표 중 릴레이 남은 시간 — 「1일 2시간」 · 「5시간 12분」(원본 짧은 형식)
  static func shortRemaining(from now: Date, to endsAt: Date) -> String {
    let seconds = max(0, Int(endsAt.timeIntervalSince(now)))
    let days = seconds / 86400
    let hours = seconds % 86400 / 3600
    return days > 0 ? "\(days)일 \(hours)시간" : "\(hours)시간 \(seconds % 3600 / 60)분"
  }
}
