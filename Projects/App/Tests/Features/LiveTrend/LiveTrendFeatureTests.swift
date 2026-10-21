import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-079 · UI-13f

@MainActor
final class LiveTrendFeatureTests: XCTestCase {
  func testSlots_changeList() async {
    var state = LiveTrendFeature.State()
    state.trend = .mock
    let store = TestStore(initialState: state) { LiveTrendFeature() }
    XCTAssertEqual(store.state.songs.count, 5)
    XCTAssertEqual(store.state.songs.filter(\.isRising).map(\.title), ["How Sweet", "소나기"])
    await store.send(.slotSelected(.dawn)) { $0.slot = .dawn }
    XCTAssertEqual(store.state.songs.first?.title, "밤편지")
    XCTAssertEqual(LiveTrendSlot.allCases.map(\.title), ["지금", "새벽", "출근길", "점심", "밤"])
  }

  func testListeners_pollEveryTwoSecondsUntilDisappear() async {
    let clock = TestClock()
    let store = TestStore(initialState: LiveTrendFeature.State()) { LiveTrendFeature() } withDependencies: {
      $0.continuousClock = clock
      $0.liveTrendClient.fetch = { .mock }
      $0.liveTrendClient.listeners = { 131 }
    }
    await store.send(.onAppear)
    await store.receive(.loaded(.mock)) { $0.trend = .mock }
    await clock.advance(by: .seconds(2))
    await store.receive(.listenersTicked)
    await store.receive(.listenersUpdated(131)) { $0.trend?.listeners = 131 }
    await store.send(.onDisappear)
  }

  func testHeroPlayAndSong() async {
    var state = LiveTrendFeature.State()
    state.trend = .mock
    let store = TestStore(initialState: state) { LiveTrendFeature() }
    await store.send(.heroPlayTapped)
    await store.receive(.delegate(.play(LiveTrend.mock.hero)))
    await store.send(.songTapped("Supernova|aespa"))
    await store.receive(.delegate(.showSong("Supernova|aespa")))
  }
}

extension MainTabFeatureTests {
  func testHomeLiveHeader_opensLiveTrend() async {
    var initial = MainTabFeature.State()
    initial.home.feed = .mock(now: Date(timeIntervalSince1970: 1800000000))
    let store = TestStore(initialState: initial) { MainTabFeature() }
    store.exhaustivity = .off
    await store.send(.home(.liveHeaderTapped))
    await store.skipReceivedActions()
    guard case .liveTrend? = store.state.homePath.last else { return XCTFail("지금 위플리가 열려야 한다") }
  }
}
