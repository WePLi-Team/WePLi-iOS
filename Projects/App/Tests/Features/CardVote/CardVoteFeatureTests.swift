import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-033 · UI-3b · DEC-004

@MainActor
final class CardVoteFeatureTests: XCTestCase {
  private func loaded() -> CardVoteFeature.State {
    var state = CardVoteFeature.State(relayID: "r", topic: "첫 사랑이 생각나는 노래 모음")
    state.candidates = VoteCandidate.mockTopTen
    return state
  }

  // MARK: 스와이프 규칙

  func testSwipe_votesOnlyBeyondThreshold() {
    XCTAssertEqual(CardSwipe.choice(forReleasedOffset: 91), .fits)
    XCTAssertEqual(CardSwipe.choice(forReleasedOffset: -91), .doesNotFit)
    XCTAssertNil(CardSwipe.choice(forReleasedOffset: 90))
    XCTAssertNil(CardSwipe.choice(forReleasedOffset: -40))
  }

  func testSwipe_rotationAndStampOpacity() {
    XCTAssertEqual(CardSwipe.rotation(for: 90), 5)
    XCTAssertEqual(CardSwipe.stampOpacity(for: 45, toward: .fits), 0.5)
    XCTAssertEqual(CardSwipe.stampOpacity(for: 45, toward: .doesNotFit), 0)
    XCTAssertEqual(CardSwipe.stampOpacity(for: -200, toward: .doesNotFit), 1)
  }

  // MARK: 리듀서

  func testOnAppear_loadsTopTen() async {
    let store = TestStore(initialState: CardVoteFeature.State(relayID: "r", topic: "t")) {
      CardVoteFeature()
    } withDependencies: {
      $0.cardVoteClient.fetchCandidates = { _ in VoteCandidate.mockTopTen + VoteCandidate.mockTopTen }
    }

    await store.send(.onAppear)
    await store.receive(.candidatesLoaded(VoteCandidate.mockTopTen)) {
      $0.candidates = VoteCandidate.mockTopTen
    }
  }

  func testVote_advancesCountsFitsAndSubmits() async {
    let submitted = LockIsolated<[String]>([])
    let store = TestStore(initialState: self.loaded()) {
      CardVoteFeature()
    } withDependencies: {
      $0.cardVoteClient.submit = { _, id, choice in submitted.withValue { $0.append("\(id):\(choice)") } }
    }

    await store.send(.voted(.fits)) {
      $0.index = 1
      $0.fitsCount = 1
    }
    await store.send(.voted(.doesNotFit)) {
      $0.index = 2
    }
    await store.finish()
    XCTAssertEqual(submitted.value, ["v1:fits", "v2:doesNotFit"])
  }

  func testTenVotes_finishAndRestart() async {
    let store = TestStore(initialState: self.loaded()) {
      CardVoteFeature()
    } withDependencies: {
      $0.cardVoteClient.submit = { _, _, _ in }
    }
    store.exhaustivity = .off

    for _ in 0 ..< 10 {
      await store.send(.voted(.fits))
    }
    XCTAssertTrue(store.state.isDone)
    XCTAssertEqual(store.state.fitsCount, 10)
    // 완료 뒤에는 더 투표되지 않는다
    await store.send(.voted(.fits))
    XCTAssertEqual(store.state.index, 10)

    await store.send(.restartButtonTapped) {
      $0.index = 0
      $0.fitsCount = 0
    }
  }

  func testSubmissionFailure_showsToast() async {
    let store = TestStore(initialState: self.loaded()) {
      CardVoteFeature()
    } withDependencies: {
      $0.cardVoteClient.submit = { _, _, _ in throw URLError(.notConnectedToInternet) }
    }

    await store.send(.voted(.fits)) {
      $0.index = 1
      $0.fitsCount = 1
    }
    await store.receive(.submissionFailed) {
      $0.failedSubmissionCount = 1
      $0.toast = "투표를 저장하지 못했어요. 잠시 후 다시 시도해 주세요"
    }
  }

  func testReturn_dismisses() async {
    let store = TestStore(initialState: self.loaded()) {
      CardVoteFeature()
    }
    await store.send(.returnToRelayButtonTapped)
    await store.receive(.delegate(.dismiss))
  }
}
