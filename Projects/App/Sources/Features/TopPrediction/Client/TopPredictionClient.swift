import ComposableArchitecture
import Foundation

// REQ-039 · DEC-004 — 예측 확정 · 비율은 서버가 정한다. 백엔드가 정해지기 전까지 원본(UI-8d) 예시를 돌려주는 목업이다.

struct TopPredictionClient {
  var fetch: @Sendable (_ relayID: String) async throws -> TopPrediction
  /// 예측을 확정한다 — 서버가 확정한 결과를 돌려준다
  var predict: @Sendable (_ relayID: String, _ optionID: TopPrediction.Option.ID) async throws -> TopPrediction
  /// 내 칭호(DEC-021)
  var titles: @Sendable () async throws -> TitleBoard
  /// 대표 칭호를 바꾼다 — 프로필 · 명함에 붙는다
  var setRepresentative: @Sendable (_ titleID: UserTitle.ID) async throws -> Void
}

extension TopPredictionClient: DependencyKey {
  static let liveValue = TopPredictionClient(
    fetch: { .mock(relayID: $0) },
    predict: { relayID, optionID in
      var prediction = TopPrediction.mock(relayID: relayID)
      prediction.lockedID = optionID
      return prediction
    },
    titles: { .mock },
    setRepresentative: { _ in }
  )

  static let previewValue = liveValue

  static let testValue = TopPredictionClient(
    fetch: unimplemented("TopPredictionClient.fetch", placeholder: .mock(relayID: "")),
    predict: unimplemented("TopPredictionClient.predict", placeholder: .mock(relayID: "")),
    titles: unimplemented("TopPredictionClient.titles", placeholder: .mock),
    setRepresentative: unimplemented("TopPredictionClient.setRepresentative")
  )
}

extension DependencyValues {
  var topPredictionClient: TopPredictionClient {
    get { self[TopPredictionClient.self] }
    set { self[TopPredictionClient.self] = newValue }
  }
}

extension TopPrediction {
  /// 원본(UI-8d) 예시
  static func mock(relayID: String) -> TopPrediction {
    TopPrediction(
      relayID: relayID,
      relayTitle: "첫 사랑이 생각나는 노래 모음",
      remaining: "1일 12시간",
      options: [
        Option(id: "bam", title: "밤양갱", percent: 38),
        Option(id: "tws", title: "첫 만남은 계획대로 되지 않아", percent: 27),
        Option(id: "easy", title: "EASY", percent: 21),
        Option(id: "love119", title: "Love 119", percent: 14),
      ],
      record: Record(predictions: 8, hits: 5, streak: 2)
    )
  }
}
