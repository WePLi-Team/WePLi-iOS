import ComposableArchitecture
import Foundation

// REQ-039 · DEC-004 — 예측 확정 · 비율은 서버가 정한다. 백엔드가 정해지기 전까지 원본(UI-8d) 예시를 돌려주는 목업이다.

public struct TopPredictionClient {
  public var fetch: @Sendable (_ relayID: String) async throws -> TopPrediction
  /// 예측을 확정한다 — 서버가 확정한 결과를 돌려준다
  public var predict: @Sendable (_ relayID: String, _ optionID: TopPrediction.Option.ID) async throws -> TopPrediction
  /// 내 칭호(DEC-021)
  public var titles: @Sendable () async throws -> TitleBoard
  /// 대표 칭호를 바꾼다 — 프로필 · 명함에 붙는다
  public var setRepresentative: @Sendable (_ titleID: UserTitle.ID) async throws -> Void

  public init(
    fetch: @escaping @Sendable (_ relayID: String) async throws -> TopPrediction,
    predict: @escaping @Sendable (_ relayID: String, _ optionID: TopPrediction.Option.ID) async throws -> TopPrediction,
    titles: @escaping @Sendable () async throws -> TitleBoard,
    setRepresentative: @escaping @Sendable (_ titleID: UserTitle.ID) async throws -> Void
  ) {
    self.fetch = fetch
    self.predict = predict
    self.titles = titles
    self.setRepresentative = setRepresentative
  }
}

extension TopPredictionClient: DependencyKey {
  public static let mockValue = TopPredictionClient(
    fetch: { .mock(relayID: $0) },
    predict: { relayID, optionID in
      var prediction = TopPrediction.mock(relayID: relayID)
      prediction.lockedID = optionID
      return prediction
    },
    titles: { .mock },
    setRepresentative: { _ in }
  )

  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  public static let liveValue = mockValue
  public static let previewValue = mockValue

  public static let testValue = TopPredictionClient(
    fetch: unimplemented("TopPredictionClient.fetch", placeholder: .mock(relayID: "")),
    predict: unimplemented("TopPredictionClient.predict", placeholder: .mock(relayID: "")),
    titles: unimplemented("TopPredictionClient.titles", placeholder: .mock),
    setRepresentative: unimplemented("TopPredictionClient.setRepresentative")
  )
}

public extension DependencyValues {
  var topPredictionClient: TopPredictionClient {
    get { self[TopPredictionClient.self] }
    set { self[TopPredictionClient.self] = newValue }
  }
}

public extension TopPrediction {
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
