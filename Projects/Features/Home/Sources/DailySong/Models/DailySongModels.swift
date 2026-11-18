import Foundation

// REQ-101 · UI-6c — 오늘의 한 곡. 질문 · 답변 수 · 많이 고른 곡은 서버 값(DEC-004). 날짜 경계는 Asia/Seoul

public struct DailyQuestion: Equatable, Identifiable, Sendable {
  public struct TopSong: Equatable, Identifiable, Sendable {
    public var id: String {
      "\(self.title)|\(self.artist)"
    }

    public let title: String
    public let artist: String
    public let count: Int

    public init(title: String, artist: String, count: Int) {
      self.title = title
      self.artist = artist
      self.count = count
    }
  }

  public struct Answer: Equatable, Identifiable, Sendable {
    public let id: String
    public let user: String
    public let songTitle: String
    /// 한마디
    public let comment: String

    public init(id: String, user: String, songTitle: String, comment: String) {
      self.id = id
      self.user = user
      self.songTitle = songTitle
      self.comment = comment
    }
  }

  public struct Pick: Equatable, Sendable {
    public let title: String
    public let artist: String

    public init(title: String, artist: String) {
      self.title = title
      self.artist = artist
    }
  }

  public let id: String
  /// 「비 오는 날,\n꼭 듣는 노래는?」
  public let question: String
  /// 질문이 열린 날(Asia/Seoul)
  public let date: Date
  /// 다음 질문이 열리는 시각 — Asia/Seoul 자정
  public let endsAt: Date
  public var answerCount: Int
  public var top: [TopSong]
  public let answers: [Answer]
  public var myAnswer: Pick?

  /// 「62%」 — 서버 집계로 계산
  public func percent(_ song: TopSong) -> Int {
    guard self.answerCount > 0 else { return 0 }
    return Int((Double(song.count) / Double(self.answerCount) * 100).rounded())
  }

  public init(
    id: String,
    question: String,
    date: Date,
    endsAt: Date,
    answerCount: Int,
    top: [TopSong],
    answers: [Answer],
    myAnswer: Pick? = nil
  ) {
    self.id = id
    self.question = question
    self.date = date
    self.endsAt = endsAt
    self.answerCount = answerCount
    self.top = top
    self.answers = answers
    self.myAnswer = myAnswer
  }
}

public enum DailySongText {
  public static let seoul = TimeZone(identifier: "Asia/Seoul") ?? .current

  /// 「10월 16일의 질문」
  public static func dateTitle(_ date: Date) -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = Self.seoul
    let parts = calendar.dateComponents([.month, .day], from: date)
    return "\(parts.month ?? 0)월 \(parts.day ?? 0)일의 질문"
  }

  /// 「23:12:04 남음」 — 두 자리씩
  public static func remaining(from now: Date, to endsAt: Date) -> String {
    let seconds = max(0, Int(endsAt.timeIntervalSince(now)))
    return String(format: "%02d:%02d:%02d 남음", seconds / 3600, seconds % 3600 / 60, seconds % 60)
  }

  /// Asia/Seoul 기준 다음 자정
  public static func nextMidnight(after date: Date) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = Self.seoul
    let start = calendar.startOfDay(for: date)
    return calendar.date(byAdding: .day, value: 1, to: start) ?? date
  }
}
