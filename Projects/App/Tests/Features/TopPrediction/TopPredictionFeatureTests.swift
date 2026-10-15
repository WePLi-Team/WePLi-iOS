import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-039 · UI-8d

@MainActor
final class TopPredictionFeatureTests: XCTestCase {
  private func loaded() -> TopPredictionFeature.State {
    var state = TopPredictionFeature.State(relayID: "first-love")
    state.prediction = .mock(relayID: "first-love")
    return state
  }

  func testRecordText() {
    let text = TopPredictionRecordText(TopPrediction.Record(predictions: 8, hits: 5, streak: 2))
    XCTAssertEqual(text.map { $0.lead + $0.hits + $0.tail }, "지금까지 8번 예측해서 5번 맞혔어요 · 2번 연속 적중 중")
    let noStreak = TopPredictionRecordText(TopPrediction.Record(predictions: 3, hits: 1, streak: 1))
    XCTAssertEqual(noStreak?.tail, " 맞혔어요")
    XCTAssertNil(TopPredictionRecordText(TopPrediction.Record(predictions: 0, hits: 0, streak: 0)))
  }

  func testPredict_locksAndCannotChange() async {
    let store = TestStore(initialState: self.loaded()) { TopPredictionFeature() } withDependencies: {
      $0.topPredictionClient.predict = { relayID, id in
        var prediction = TopPrediction.mock(relayID: relayID)
        prediction.lockedID = id
        return prediction
      }
    }
    XCTAssertFalse(store.state.canPredict)
    await store.send(.optionTapped("easy")) { $0.selectedID = "easy" }
    await store.send(.optionTapped("tws")) { $0.selectedID = "tws" }
    await store.send(.predictTapped) {
      $0.isSubmitting = true
      $0.prediction?.lockedID = "tws"
    }
    await store.receive(\.predicted) { $0.isSubmitting = false }
    await store.receive(.delegate(.predicted(relayID: "first-love", optionID: "tws")))
    // 확정한 뒤에는 바꿀 수 없다
    await store.send(.optionTapped("bam"))
    await store.send(.predictTapped)
  }

  func testPredictFailure_unlocks() async {
    struct Failure: Error {}
    var state = self.loaded()
    state.selectedID = "bam"
    let store = TestStore(initialState: state) { TopPredictionFeature() } withDependencies: {
      $0.topPredictionClient.predict = { _, _ in throw Failure() }
    }
    await store.send(.predictTapped) {
      $0.isSubmitting = true
      $0.prediction?.lockedID = "bam"
    }
    await store.receive(.predictFailed) {
      $0.isSubmitting = false
      $0.prediction?.lockedID = nil
      $0.toast = "예측하지 못했어요. 다시 시도해 주세요"
    }
  }
}

extension MainTabFeatureTests {
  func testHomePredictionHeader_opensTopPrediction() async {
    var initial = MainTabFeature.State()
    initial.home.feed = .mock(now: Date(timeIntervalSince1970: 1800000000))
    let store = TestStore(initialState: initial) { MainTabFeature() }
    store.exhaustivity = .off
    await store.send(.home(.predictionHeaderTapped))
    await store.skipReceivedActions()
    guard case .topPrediction? = store.state.homePath.last else { return XCTFail("1위 예측이 열려야 한다") }
  }
}
