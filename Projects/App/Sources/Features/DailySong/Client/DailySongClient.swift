import ComposableArchitecture
import Foundation

// REQ-101 · DEC-004 — 오늘의 한 곡. 백엔드가 정해지기 전까지 원본(UI-6c) 예시를 돌려주는 목업이다.
// 미결정 — 많이 고른 곡으로 다음 날 「오늘의 플리」를 만드는 규칙(곡 수 · 시각)

struct DailySongClient {
  var fetch: @Sendable () async throws -> DailyQuestion
  /// 답하거나 바꾼다 — 서버가 다시 센 결과를 돌려준다
  var answer: @Sendable (_ questionID: String, _ pick: DailyQuestion.Pick) async throws -> DailyQuestion
}

extension DailySongClient: DependencyKey {
  static let liveValue = DailySongClient(
    fetch: {
      @Dependency(\.date.now)
      var now
      return .mock(now: now)
    },
    answer: { _, pick in
      @Dependency(\.date.now)
      var now
      var question = DailyQuestion.mock(now: now)
      question.myAnswer = pick
      question.answerCount += 1
      if let index = question.top.firstIndex(where: { $0.title == pick.title && $0.artist == pick.artist }) {
        let song = question.top[index]
        question.top[index] = .init(title: song.title, artist: song.artist, count: song.count + 1)
      }
      return question
    }
  )

  static let previewValue = liveValue

  static let testValue = DailySongClient(
    fetch: unimplemented("DailySongClient.fetch", placeholder: .mock(now: Date(timeIntervalSince1970: 0))),
    answer: unimplemented("DailySongClient.answer", placeholder: .mock(now: Date(timeIntervalSince1970: 0)))
  )
}

extension DependencyValues {
  var dailySongClient: DailySongClient {
    get { self[DailySongClient.self] }
    set { self[DailySongClient.self] = newValue }
  }
}

extension DailyQuestion {
  /// 원본(UI-6c) 예시
  static func mock(now: Date) -> DailyQuestion {
    DailyQuestion(
      id: "rainy-day",
      question: "비 오는 날,\n꼭 듣는 노래는?",
      date: now,
      endsAt: DailySongText.nextMidnight(after: now),
      answerCount: 2481,
      top: [
        TopSong(title: "비와 당신", artist: "이무진", count: 812),
        TopSong(title: "비의 랩소디", artist: "임재현", count: 604),
        TopSong(title: "비가 내리는 날에는", artist: "윤하", count: 521),
      ],
      answers: [
        Answer(id: "a1", user: "minnie._.", songTitle: "비의 랩소디", comment: "빗소리랑 피아노가 섞이면 그냥 영화 한 장면"),
        Answer(id: "a2", user: "younha_holic", songTitle: "비가 내리는 날에는", comment: "이건 비 오는 날의 국룰이죠"),
        Answer(id: "a3", user: "woogi", songTitle: "비와 당신", comment: "버스 창가에 앉아서 들으면 끝"),
      ]
    )
  }
}
