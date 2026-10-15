import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-040 · UI-14b · DEC-004

@MainActor
final class CompletedPlaylistFeatureTests: XCTestCase {
  private func loaded() -> CompletedPlaylistFeature.State {
    var state = CompletedPlaylistFeature.State(relayID: "wake-up")
    state.playlist = .mock(id: "wake-up")
    return state
  }

  func testTexts() {
    let playlist = CompletedPlaylist.mock(id: "wake-up")
    XCTAssertEqual(playlist.stats, "248명이 추천한 12곡 · 10월 12일 완성")
    XCTAssertEqual(playlist.rankingMeta, "추천 248명 · 투표 1,284명")
    XCTAssertEqual(playlist.myBest?.rank, 4)
    XCTAssertEqual(playlist.exportTitle, "내 음악 앱으로 내보내기")
  }

  func testLike_isOptimisticAndRollsBack() async {
    let store = TestStore(initialState: self.loaded()) {
      CompletedPlaylistFeature()
    } withDependencies: {
      $0.completedPlaylistClient.setLiked = { _, _ in throw URLError(.timedOut) }
    }

    await store.send(.likeTapped) {
      $0.playlist?.isLiked = true
      $0.playlist?.likeCount = 1205
    }
    await store.receive(.toggleFailed(.like, restore: false)) {
      $0.playlist?.isLiked = false
      $0.playlist?.likeCount = 1204
      $0.toast = "잠시 후 다시 시도해 주세요"
    }
  }

  func testSaveAndNextRelayAlert() async {
    let store = TestStore(initialState: self.loaded()) {
      CompletedPlaylistFeature()
    } withDependencies: {
      $0.completedPlaylistClient.setSaved = { _, _ in }
      $0.completedPlaylistClient.setNextRelayAlert = { _, _ in }
    }

    await store.send(.saveTapped) { $0.playlist?.isSaved = true }
    await store.send(.nextRelayAlertTapped) { $0.playlist?.isNextRelayAlertOn = true }
  }

  func testTaps_delegate() async {
    let store = TestStore(initialState: self.loaded()) {
      CompletedPlaylistFeature()
    }

    await store.send(.songTapped("easy"))
    await store.receive(.delegate(.showSong("easy")))
    await store.send(.songMoreTapped("easy"))
    await store.receive(.delegate(.songMenu(ComposeTrack(id: "easy", title: "EASY", artist: "LE SSERAFIM (르세라핌)"))))
    await store.send(.similarTapped("first-love"))
    await store.receive(.delegate(.showPlaylist("first-love")))
    await store.send(.exportTapped)
    await store.receive(.delegate(.export(relayID: "wake-up")))
    await store.send(.backButtonTapped)
    await store.receive(.delegate(.dismiss))
  }
}

@MainActor
final class CompletedPlaylistNavigationTests: XCTestCase {
  func testHomeCompletedHero_opensCompletedPlaylist() async {
    var home = HomeFeature.State()
    home.feed = .mock(now: Date(timeIntervalSince1970: 0))
    let store = TestStore(initialState: home) {
      HomeFeature()
    }

    await store.send(.heroTapped("wake-up"))
    await store.receive(.delegate(.showCompletedPlaylist("wake-up")))
    await store.send(.heroTapped("cafe-bgm"))
    await store.receive(.delegate(.showRelay("cafe-bgm")))
  }

  func testRoutes_toCompletedPlaylist() async {
    var initial = MainTabFeature.State()
    initial.relay.relays = [
      Relay(id: "wake-up", title: "졸릴 때", voteFormat: .card, participantCount: 1, status: .completed, isMine: false),
    ]
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    }
    store.exhaustivity = .off

    await store.send(.home(.delegate(.showCompletedPlaylist("wake-up"))))
    XCTAssertNotNil(store.state.homePath[id: store.state.homePath.ids[0], case: \.completedPlaylist])

    await store.send(.relay(.delegate(.showRelay("wake-up"))))
    let relayID = store.state.relayPath.ids[0]
    XCTAssertNotNil(store.state.relayPath[id: relayID, case: \.completedPlaylist])

    // 비슷한 완성 플리 → 완성 플리, 곡 → 곡 상세, ··· → 곡 메뉴
    await store.send(.relayPath(.element(
      id: relayID,
      action: .completedPlaylist(.delegate(.showPlaylist("first-love")))
    )))
    await store.send(.relayPath(.element(id: relayID, action: .completedPlaylist(.delegate(.showSong("easy"))))))
    XCTAssertEqual(store.state.relayPath.count, 3)
    let song = ComposeTrack(id: "easy", title: "EASY", artist: "LE SSERAFIM (르세라핌)")
    await store.send(.relayPath(.element(id: relayID, action: .completedPlaylist(.delegate(.songMenu(song))))))
    XCTAssertEqual(store.state.songMenu?.title, "EASY")
  }

  func testCompletedNotification_opensCompletedPlaylist() async {
    var initial = MainTabFeature.State()
    var notifications = NotificationsFeature.State()
    notifications.notifications = [
      AppNotification(
        id: "n6",
        group: .thisWeek,
        kind: .relayCompleted,
        text: "완성",
        timeText: "2일 전",
        actionTitle: "듣기",
        isRead: true,
        relayID: "first-love"
      ),
    ]
    initial.communityPath.append(.notifications(notifications))
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    }
    store.exhaustivity = .off
    let id = initial.communityPath.ids[0]

    await store.send(.communityPath(.element(id: id, action: .notifications(.delegate(.open("n6"))))))
    guard let last = store.state.communityPath.ids.last else { return XCTFail("화면이 열리지 않음") }
    XCTAssertNotNil(store.state.communityPath[id: last, case: \.completedPlaylist])
  }
}
