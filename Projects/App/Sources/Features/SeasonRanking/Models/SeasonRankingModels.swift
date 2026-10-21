import Foundation

// UI-8f · DEC-022 — 시즌 랭킹. 기간 · 점수 · 순위는 서버 값(DEC-004). 시즌 시작 · 끝 날짜도 서버가 정한다.

enum SeasonRankingTab: CaseIterable, Equatable, Sendable {
  case curator
  case host

  var title: String {
    switch self {
    case .curator: "큐레이터"
    case .host: "호스트"
    }
  }
}

struct SeasonRanking: Equatable, Sendable {
  struct Standing: Equatable, Sendable {
    let rank: Int
    /// 순위 변동 — 오르면 양수
    let change: Int
    /// TOP 100까지 남은 점수 — 이미 안이면 nil
    let pointsToTop100: Int?
    let score: Int
  }

  struct Entry: Equatable, Identifiable, Sendable {
    var id: Int {
      self.rank
    }

    let rank: Int
    let name: String
    /// 대표 칭호(8d)
    let title: String?
    let score: Int
  }

  /// 「시즌 3 · 가을」
  let seasonName: String
  let endsAt: Date
  let me: Standing
  /// 1위부터 TOP 10 — 앞 3명은 시상대, 나머지는 목록
  let entries: [Entry]
  /// 내 바로 위 · 나 · 바로 아래(DEC-030)
  let nearby: [Entry]
  var hosts: [SeasonHost]

  var podium: [Entry] {
    Array(self.entries.prefix(3))
  }

  /// 4–10위
  var list: [Entry] {
    Array(self.entries.dropFirst(3))
  }

  /// TOP 10 뒤에 이어 보일 내 주변 — TOP 10과 겹치는 순위는 뺀다
  var nearbyList: [Entry] {
    let last = self.entries.last?.rank ?? 0
    return self.nearby.filter { $0.rank > last }
  }

  /// 내 주변이 TOP 10에 바로 이어지면 줄임표를 두지 않는다
  var showsGap: Bool {
    guard let first = self.nearbyList.first?.rank else { return false }
    return first > (self.entries.last?.rank ?? 0) + 1
  }

  func isMe(_ entry: Entry) -> Bool {
    entry.rank == self.me.rank
  }
}

struct SeasonHost: Equatable, Identifiable, Sendable {
  let id: String
  let name: String
  /// 「릴레이 12개 · 참여 3.2만 명」
  let stats: String
  /// 최근 연 릴레이 제목
  let recentRelay: String
  var isFollowing: Bool
}

enum SeasonText {
  /// 보상 줄 — DEC-022
  static let rewards = "TOP 10 한정 명함 테마 · TOP 100 시즌 프로필 테두리 · 시즌이 끝나도 계속 쓸 수 있어요"
  /// 점수 얻는 법 — DEC-022
  static let howToScore = "추천곡 최종 순위 최대 100점 · 1위 예측 적중 30점 · 내가 연 릴레이 참여자 1명당 1점 · 투표 1번 1점(하루 20점까지)"

  private static var seoul: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    return calendar
  }

  /// 「D-23 · 10월 31일 종료」 — Asia/Seoul 날짜 기준(DEC-004)
  static func deadline(_ endsAt: Date, now: Date) -> String {
    let calendar = self.seoul
    let start = calendar.startOfDay(for: now)
    let end = calendar.startOfDay(for: endsAt)
    let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
    let parts = calendar.dateComponents([.month, .day], from: endsAt)
    let dday = days > 0 ? "D-\(days)" : "D-DAY"
    return "\(dday) · \(parts.month ?? 0)월 \(parts.day ?? 0)일 종료"
  }

  /// 「2,340」
  static func score(_ value: Int) -> String {
    value.formatted(.number.grouping(.automatic).locale(Locale(identifier: "ko_KR")))
  }

  /// 「어제보다 ▲12」 · 「어제보다 ▼3」 — 어제 같은 시각 대비(DEC-030), 변동 없으면 nil
  static func change(_ value: Int) -> String? {
    if value > 0 {
      return "어제보다 ▲\(value)"
    }
    return value < 0 ? "어제보다 ▼\(-value)" : nil
  }
}
