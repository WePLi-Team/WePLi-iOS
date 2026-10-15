import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-031 · REQ-037 · UI-3c

@MainActor
final class RelayDetailFeatureTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1800000000)

  func testCountdown_showsDaysHoursMinutesSeconds() {
    let end = self.now.addingTimeInterval(36 * 3600 + 10 * 60 + 15)
    XCTAssertEqual(CountdownFormatter.string(from: self.now, to: end), "1일 12시간 10분 15초")
    XCTAssertEqual(CountdownFormatter.string(from: self.now, to: self.now.addingTimeInterval(-5)), "0일 0시간 0분 0초")
  }

  func testDisplayState_becomesCompletedWhenTimeRunsOut() {
    var detail = RelayDetail.mock(id: "r", now: self.now)
    XCTAssertEqual(RelayDisplayState(detail, now: self.now), .live)
    XCTAssertEqual(RelayDisplayState(detail, now: self.now.addingTimeInterval(36 * 3600 + 10 * 60 + 15)), .completed)

    detail.status = .empty(endsAt: self.now.addingTimeInterval(60))
    XCTAssertEqual(RelayDisplayState(detail, now: self.now), .empty)
    detail.status = .completed
    XCTAssertEqual(RelayDisplayState(detail, now: self.now), .completed)
  }

  func testTopThree_areHighlighted() {
    let ranking = RelayDetail.mock(id: "r", now: self.now).ranking
    XCTAssertEqual(ranking.filter(\.isTop).map(\.rank), [1, 2, 3])
  }

  func testOnAppear_loadsAndTicks() async {
    let clock = TestClock()
    let detail = RelayDetail.mock(id: "first-love", now: self.now)
    let store = TestStore(initialState: RelayDetailFeature.State(relayID: "first-love")) {
      RelayDetailFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date.now = self.now
      $0.relayDetailClient.fetch = { _ in detail }
    }

    await store.send(.onAppear) {
      $0.now = self.now
    }
    await store.receive(.detailLoaded(detail)) {
      $0.detail = detail
    }
    await clock.advance(by: .seconds(1))
    await store.receive(.timerTicked)
    await store.send(.onDisappear)
  }

  func testTimer_stopsWhenCompleted() async {
    let clock = TestClock()
    var detail = RelayDetail.mock(id: "r", now: self.now)
    detail.status = .live(endsAt: self.now.addingTimeInterval(1))
    let current = LockIsolated(self.now)
    let store = TestStore(initialState: RelayDetailFeature.State(relayID: "r", detail: detail)) {
      RelayDetailFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date = .init { current.value }
    }

    await store.send(.onAppear) {
      $0.now = self.now
    }
    current.setValue(self.now.addingTimeInterval(1))
    await clock.advance(by: .seconds(1))
    await store.receive(.timerTicked) {
      $0.now = self.now.addingTimeInterval(1)
    }
    XCTAssertEqual(store.state.displayState, .completed)
  }

  func testButtons_sendDelegates() async {
    let store = TestStore(initialState: RelayDetailFeature.State(relayID: "r")) {
      RelayDetailFeature()
    }

    await store.send(.voteButtonTapped)
    await store.receive(.delegate(.showVote(relayID: "r")))
    await store.send(.recommendButtonTapped)
    await store.receive(.delegate(.showRecommend(relayID: "r")))
    await store.send(.playAllButtonTapped)
    await store.receive(.delegate(.playAll(relayID: "r")))
    await store.send(.addToMyPlaylistButtonTapped)
    await store.receive(.delegate(.addToMyPlaylist(relayID: "r")))
    await store.send(.exportButtonTapped)
    await store.receive(.delegate(.export(relayID: "r")))
    await store.send(.backButtonTapped)
    await store.receive(.delegate(.dismiss))
  }

  func testLoadFailure_thenRetry() async {
    let fail = LockIsolated(true)
    let detail = RelayDetail.mock(id: "r", now: self.now)
    let store = TestStore(initialState: RelayDetailFeature.State(relayID: "r")) {
      RelayDetailFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.date.now = self.now
      $0.relayDetailClient.fetch = { _ in
        if fail.value {
          throw URLError(.timedOut)
        }
        return detail
      }
    }
    store.exhaustivity = .off

    await store.send(.onAppear)
    await store.receive(.detailFailed) {
      $0.loadFailed = true
    }
    fail.setValue(false)
    await store.send(.retryButtonTapped) {
      $0.loadFailed = false
    }
    await store.receive(.detailLoaded(detail)) {
      $0.detail = detail
    }
    await store.send(.onDisappear)
  }
}
