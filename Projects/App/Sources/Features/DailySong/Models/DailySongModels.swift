import Foundation

// REQ-101 · UI-6c — 오늘의 한 곡. 질문 · 답변 수 · 많이 고른 곡은 서버 값(DEC-004). 날짜 경계는 Asia/Seoul

struct DailyQuestion: Equatable, Identifiable, Sendable {
  struct TopSong: Equatable, Identifiable, Sendable {
    var id: String {
      "\(self.title)|\(self.artist)"
    }

    let title: String
    let artist: String
    let count: Int
  }

  struct Answer: Equatable, Identifiable, Sendable {
    let id: String
    let user: String
    let songTitle: String
    /// 한마디
    let comment: String
  }

  struct Pick: Equatable, Sendable {
    let title: String
    let artist: String
  }

  let id: String
  /// 「비 오는 날,\n꼭 듣는 노래는?」
  let question: String
  /// 질문이 열린 날(Asia/Seoul)
  let date: Date
  /// 다음 질문이 열리는 시각 — Asia/Seoul 자정
  let endsAt: Date
  var answerCount: Int
  var top: [TopSong]
  let answers: [Answer]
  var myAnswer: Pick?

  /// 「62%」 — 서버 집계로 계산
  func percent(_ song: TopSong) -> Int {
    guard self.answerCount > 0 else { return 0 }
    return Int((Double(song.count) / Double(self.answerCount) * 100).rounded())
  }
}

enum DailySongText {
  static let seoul = TimeZone(identifier: "Asia/Seoul") ?? .current

  /// 「10월 16일의 질문」
  static func dateTitle(_ date: Date) -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = Self.seoul
    let parts = calendar.dateComponents([.month, .day], from: date)
    return "\(parts.month ?? 0)월 \(parts.day ?? 0)일의 질문"
  }

  /// 「23:12:04 남음」 — 두 자리씩
  static func remaining(from now: Date, to endsAt: Date) -> String {
    let seconds = max(0, Int(endsAt.timeIntervalSince(now)))
    return String(format: "%02d:%02d:%02d 남음", seconds / 3600, seconds % 3600 / 60, seconds % 60)
  }

  /// Asia/Seoul 기준 다음 자정
  static func nextMidnight(after date: Date) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = Self.seoul
    let start = calendar.startOfDay(for: date)
    return calendar.date(byAdding: .day, value: 1, to: start) ?? date
  }
}
