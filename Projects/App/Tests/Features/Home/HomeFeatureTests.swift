import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-020 · UI-12a · DEC-008

@MainActor
final class HomeFeatureTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1791991800)

  func testCountdown_matchesDesignFormat() {
    XCTAssertEqual(HomeCountdown.clock(from: self.now, to: self.now.addingTimeInterval(187953)), "2일 04:12:33")
    XCTAssertEqual(HomeCountdown.clock(from: self.now, to: self.now.addingTimeInterval(33410)), "09:16:50")
    XCTAssertEqual(HomeCountdown.clock(from: self.now, to: self.now.addingTimeInterval(-5)), "00:00:00")
  }

  func testOnAppear_loadsAndTicks() async {
    let clock = TestClock()
    let feed = HomeFeed.mock(now: self.now)
    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date.now = self.now
      $0.homeClient.fetch = { feed }
    }

    await store.send(.onAppear) { $0.now = self.now }
    await store.receive(.loaded(feed)) { $0.feed = feed }
    await clock.advance(by: .seconds(1))
    await store.receive(.timerTicked)
    await store.send(.onDisappear)
  }

  func testTaps_delegate() async {
    var initial = HomeFeature.State()
    initial.feed = .mock(now: self.now)
    let store = TestStore(initialState: initial) {
      HomeFeature()
    }

    await store.send(.heroTapped("cafe-bgm"))
    await store.receive(.delegate(.showRelay("cafe-bgm")))
    await store.send(.notificationsTapped)
    await store.receive(.delegate(.showNotifications))
    await store.send(.chartSongTapped("supernova"))
    await store.receive(.delegate(.showSong("supernova")))
    await store.send(.chartMoreTapped("bam"))
    await store.receive(.delegate(.songMenu(ComposeTrack(id: "bam", title: "밤양갱", artist: "비비 (BIBI)"))))
    await store.send(.heroPageChanged(2)) { $0.heroPage = 2 }
  }

  func testLoadFailure_thenRetry() async {
    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    } withDependencies: {
      $0.homeClient.fetch = { throw URLError(.notConnectedToInternet) }
      $0.continuousClock = TestClock()
      $0.date.now = Date(timeIntervalSince1970: 0)
    }
    store.exhaustivity = .off

    await store.send(.onAppear)
    await store.receive(.loadFailed) { $0.loadFailed = true }
    await store.send(.retryButtonTapped) { $0.loadFailed = false }
    await store.receive(.loadFailed)
    await store.send(.onDisappear)
  }
}

@MainActor
final class HomeNavigationTests: XCTestCase {
  func testHome_opensRelaySongNotificationsAndMenu() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .home
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    } withDependencies: {
      $0.songDetailClient.setLiked = { _, _ in }
    }
    store.exhaustivity = .off

    await store.send(.home(.delegate(.showRelay("cafe-bgm"))))
    XCTAssertTrue(store.state.hidesTabBar)
    await store.send(.home(.delegate(.showSong("supernova"))))
    await store.send(.home(.delegate(.showNotifications)))
    let ids = store.state.homePath.ids
    XCTAssertEqual(ids.count, 3)
    XCTAssertNotNil(store.state.homePath[id: ids[0], case: \.relayDetail])
    XCTAssertNotNil(store.state.homePath[id: ids[1], case: \.songDetail])

    // TOP 100 ··· — 곡 상세 없이 연 시트는 좋아요를 직접 저장하고, 아티스트는 홈 탭에 연다
    await store.send(.home(.delegate(.songMenu(ComposeTrack(id: "bam", title: "밤양갱", artist: "비비 (BIBI)")))))
    XCTAssertEqual(store.state.songMenu?.savesLike, true)
    XCTAssertNil(store.state.songMenuSource)
    await store.send(.songMenu(.presented(.likeButtonTapped))) { $0.songMenu?.isLiked = true }
    await store.send(.songMenu(.presented(.itemTapped(.artist))))
    await store.receive(.songMenu(.presented(.delegate(.selected(.artist)))))
    XCTAssertNil(store.state.songMenu)
    XCTAssertEqual(store.state.homePath.count, 4)
  }
}
