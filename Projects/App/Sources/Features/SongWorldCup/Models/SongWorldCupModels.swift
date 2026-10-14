import Foundation

// REQ-034 · UI-8b — 곡 월드컵: 상위 8곡을 1:1로 8강 → 4강 → 결승(7경기)

struct WorldCupSong: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  let artist: String
  /// 추천한 사람
  let recommender: String
}

enum WorldCupSide: Equatable, Sendable {
  case top
  case bottom
}

/// 대진 — 순위대로 (1v2)(3v4)… 짝을 짓고, 이긴 순서대로 다음 라운드 짝을 짓는다(원본 스크립트)
struct WorldCupBracket: Equatable, Sendable {
  /// 이번 라운드에 남은 곡(인덱스)
  private(set) var round: [Int]
  /// 이번 라운드 몇 번째 대결인지
  private(set) var match = 0
  private(set) var winners: [Int] = []
  private(set) var champion: Int?
  /// 전체 경기 수(곡 수 − 1)
  let totalMatches: Int

  /// 2의 거듭제곱으로 맞춘다 — 8곡보다 적으면 4 · 2곡으로(원본에 규칙 없음)
  init(songCount: Int) {
    let size = [8, 4, 2].first { $0 <= songCount } ?? 0
    self.round = Array(0 ..< size)
    self.totalMatches = max(size - 1, 0)
  }

  var isFinished: Bool {
    self.champion != nil
  }

  var matchesInRound: Int {
    self.round.count / 2
  }

  /// 지금 대결의 위 · 아래 곡
  var pair: (top: Int, bottom: Int)? {
    guard !self.isFinished, self.round.count >= 2 else { return nil }
    return (self.round[self.match * 2], self.round[self.match * 2 + 1])
  }

  /// 「8강 1 / 4」 · 「4강 2 / 2」 · 「결승 1 / 1」
  var roundLabel: String {
    let name = self.round.count == 2 ? "결승" : "\(self.round.count)강"
    return "\(name) \(self.match + 1) / \(self.matchesInRound)"
  }

  /// 끝낸 경기 수 — 진행 막대(끝낸 경기 / 7)
  var completedMatches: Int {
    let finishedRounds = self.totalMatches + 1 - self.round.count
    return finishedRounds + self.match
  }

  var progress: Double {
    self.totalMatches == 0 ? 0 : Double(self.completedMatches) / Double(self.totalMatches)
  }

  mutating func pick(_ side: WorldCupSide) {
    guard let pair = self.pair else { return }
    self.winners.append(side == .top ? pair.top : pair.bottom)
    if self.match + 1 < self.matchesInRound {
      self.match += 1
    } else if self.winners.count == 1 {
      self.champion = self.winners[0]
    } else {
      self.round = self.winners
      self.winners = []
      self.match = 0
    }
  }
}

/// 서버가 모은 다른 사람들의 결과
struct WorldCupCrowd: Equatable, Sendable {
  let topSongID: String
  let topSongTitle: String
  /// 1위 곡을 우승곡으로 고른 비율(%)
  let topPercent: Int
  /// 내 우승곡이 다른 사람들 사이에서 몇 위인지. 모르면 「상위권」
  let myChampionRank: Int?

  /// 「밤양갱 · 32% — 나와 같은 선택이에요!」 · 「밤양갱 · 32% (내 우승곡은 다른 사람들의 3위)」
  func summary(championID: String) -> String {
    let head = "\(self.topSongTitle) · \(self.topPercent)%"
    if championID == self.topSongID {
      return "\(head) — 나와 같은 선택이에요!"
    }
    let rank = self.myChampionRank.map { "\($0)위" } ?? "상위권"
    return "\(head) (내 우승곡은 다른 사람들의 \(rank))"
  }
}
