import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-030 · UI-10a

@MainActor
final class RelayListFeatureTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1800000000)

  // MARK: 남은 시간 표기

  func testRemainingTime_underOneDay_showsClock() {
    XCTAssertEqual(
      RemainingTimeFormatter.string(from: self.now, to: self.now.addingTimeInterval(2.3 * 3600)),
      "2:18:00"
    )
    XCTAssertEqual(RemainingTimeFormatter.string(from: self.now, to: self.now.addingTimeInterval(59)), "0:00:59")
  }

  func testRemainingTime_overOneDay_showsDaysAndHours() {
    XCTAssertEqual(
      RemainingTimeFormatter.string(from: self.now, to: self.now.addingTimeInterval(36.2 * 3600)),
      "1일 12시간"
    )
    XCTAssertEqual(RemainingTimeFormatter.string(from: self.now, to: self.now.addingTimeInterval(61 * 3600)), "2일 13시간")
  }

  func testRemainingTime_afterDeadline_isZero() {
    XCTAssertEqual(RemainingTimeFormatter.string(from: self.now, to: self.now.addingTimeInterval(-10)), "0:00:00")
  }

  // MARK: 필터 규칙

  func testLiveFilter_featuresSoonestAndRemovesItFromList() {
    let sections = RelaySections.make(filter: .live, relays: RelayMockData.relays(now: self.now))
    XCTAssertEqual(sections.featured?.id, "cafe-bgm")
    XCTAssertEqual(sections.list.map(\.id), ["summer-idol", "rainy-night", "first-love"])
  }

  func testClosingSoonFilter_returnsTwoSoonestLive() {
    let sections = RelaySections.make(filter: .closingSoon, relays: RelayMockData.relays(now: self.now))
    XCTAssertNil(sections.featured)
    XCTAssertEqual(sections.list.map(\.id), ["cafe-bgm", "rainy-night"])
  }

  func testCompletedAndMineFilters() {
    let relays = RelayMockData.relays(now: self.now)
    XCTAssertEqual(RelaySections.make(filter: .completed, relays: relays).list.map(\.id), ["wake-up", "childhood"])
    XCTAssertEqual(
      RelaySections.make(filter: .mine, relays: relays).list.map(\.id),
      ["cafe-bgm", "rainy-night", "wake-up"]
    )
  }

  func testEmptyRelays_areEmptyForEveryFilter() {
    for filter in RelayFilter.allCases {
      XCTAssertTrue(RelaySections.make(filter: filter, relays: []).isEmpty, "\(filter)")
    }
  }

  func testParticipantText_batonShowsFriends() {
    let relays = RelayMockData.relays(now: self.now)
    XCTAssertEqual(relays[0].participantText, "3,012")
    XCTAssertEqual(relays[2].participantText, "친구 8")
  }

  // MARK: 리듀서

  func testOnAppear_loadsRelaysAndTicksEverySecond() async {
    let clock = TestClock()
    let relays = RelayMockData.relays(now: self.now)
    let store = TestStore(initialState: RelayListFeature.State()) {
      RelayListFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date.now = self.now
      $0.relayClient.fetchRelays = { relays }
    }

    await store.send(.onAppear) {
      $0.now = self.now
      $0.isLoading = true
    }
    await store.receive(.relaysLoaded(relays)) {
      $0.isLoading = false
      $0.relays = relays
    }
    await clock.advance(by: .seconds(1))
    await store.receive(.timerTicked)
    await store.send(.onDisappear)
  }

  func testLoadFailure_thenRetrySucceeds() async {
    let relays = RelayMockData.relays(now: self.now)
    let shouldFail = LockIsolated(true)
    let store = TestStore(initialState: RelayListFeature.State()) {
      RelayListFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.date.now = self.now
      $0.relayClient.fetchRelays = {
        if shouldFail.value {
          throw URLError(.notConnectedToInternet)
        }
        return relays
      }
    }
    store.exhaustivity = .off

    await store.send(.onAppear)
    await store.receive(.relaysFailed) {
      $0.loadFailed = true
      $0.isLoading = false
    }

    shouldFail.setValue(false)
    await store.send(.retryButtonTapped) {
      $0.isLoading = true
      $0.loadFailed = false
    }
    await store.receive(.relaysLoaded(relays)) {
      $0.relays = relays
      $0.isLoading = false
    }
    await store.send(.onDisappear)
  }

  func testFilterAndTaps_sendDelegates() async {
    let store = TestStore(initialState: RelayListFeature.State()) {
      RelayListFeature()
    }

    await store.send(.filterSelected(.completed)) {
      $0.filter = .completed
    }
    await store.send(.relayTapped("wake-up"))
    await store.receive(.delegate(.showRelay("wake-up")))
    await store.send(.openRelayButtonTapped)
    await store.receive(.delegate(.showCreateRelay))
  }
}
