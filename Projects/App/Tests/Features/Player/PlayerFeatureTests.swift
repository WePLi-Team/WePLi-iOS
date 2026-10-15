import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-022 · UI-4b

@MainActor
final class PlayerFeatureTests: XCTestCase {
  private let queue = [
    PlayerTrack(id: "a", title: "밤편지", artist: "아이유 (IU)"),
    PlayerTrack(id: "b", title: "Blueming", artist: "아이유 (IU)"),
    PlayerTrack(id: "c", title: "밤양갱", artist: "비비(bibi)"),
  ]

  func testTexts() {
    XCTAssertEqual(PlayerText.elapsed(8), "0:08")
    XCTAssertEqual(PlayerText.remaining(8), "-0:22")
    XCTAssertEqual(PlayerText.progress(15), 0.5)
  }

  func testPreviewEnds_advancesThenStopsAtLastSong() async {
    let clock = TestClock()
    let played = LockIsolated<[String]>([])
    let store = TestStore(initialState: PlayerFeature.State()) { PlayerFeature() } withDependencies: {
      $0.continuousClock = clock
      $0.playerClient.play = { track in played.withValue { $0.append(track.id) } }
    }
    store.exhaustivity = .off
    await store.send(.play(queue: self.queue, startAt: 1, source: "첫 사랑이 생각나는 노래 모음")) {
      $0.index = 1
      $0.isPlaying = true
    }
    XCTAssertEqual(store.state.upcoming.map(\.id), ["c"])
    await clock.advance(by: .seconds(30))
    await store.skipReceivedActions()
    XCTAssertEqual(store.state.index, 2)
    XCTAssertEqual(store.state.position, 0)
    await clock.advance(by: .seconds(30))
    await store.skipReceivedActions()
    // 마지막 곡이 끝나면 처음으로 돌려 멈춘다
    XCTAssertEqual(store.state.index, 2)
    XCTAssertFalse(store.state.isPlaying)
    XCTAssertEqual(played.value, ["b", "c"])
    await store.send(.playPauseTapped) { $0.isPlaying = true }
    await store.send(.playPauseTapped) { $0.isPlaying = false }
  }

  func testPrevious_restartsAfterThreeSecondsOtherwiseGoesBack() async {
    var state = PlayerFeature.State()
    state.queue = self.queue
    state.index = 1
    state.position = 10
    let store = TestStore(initialState: state) { PlayerFeature() } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }
    store.exhaustivity = .off
    await store.send(.previousTapped) {
      $0.index = 1
      $0.position = 0
      $0.isPlaying = true
    }
    await store.send(.previousTapped) { $0.index = 0 }
    await store.send(.upcomingTapped("c")) { $0.index = 2 }
    await store.send(.nextTapped) { $0.isPlaying = false }
  }

  func testLike_rollsBackOnFailure() async {
    struct Failure: Error {}
    var state = PlayerFeature.State()
    state.queue = self.queue
    state.index = 0
    let store = TestStore(initialState: state) { PlayerFeature() } withDependencies: {
      $0.playerClient.setLiked = { _, _ in throw Failure() }
    }
    await store.send(.likeTapped) { $0.likedIDs = ["a"] }
    await store.receive(.likeFailed("a", restore: false)) { $0.likedIDs = [] }
  }

  func testExpand_onlyWhenPlaying() async {
    let store = TestStore(initialState: PlayerFeature.State()) { PlayerFeature() }
    await store.send(.miniPlayerTapped)
    await store.send(.expandedChanged(true))
  }
}

extension MainTabFeatureTests {
  func testRelayDetailPlaySong_startsPlayerAtThatSong() async {
    let detail = RelayDetail.mock(id: "r", now: Date(timeIntervalSince1970: 1800000000))
    var initial = MainTabFeature.State()
    initial.selectedTab = .relay
    initial.relayPath.append(.relayDetail(RelayDetailFeature.State(relayID: "r", detail: detail)))
    let store = TestStore(initialState: initial) { MainTabFeature() } withDependencies: {
      $0.continuousClock = TestClock()
    }
    store.exhaustivity = .off
    let id = initial.relayPath.ids[0]
    let song = detail.ranking[1]
    await store.send(.relayPath(.element(id: id, action: .relayDetail(.songPlayTapped(song.id)))))
    await store.skipReceivedActions()
    XCTAssertEqual(store.state.player.current?.title, song.title)
    XCTAssertEqual(store.state.player.queue.count, detail.ranking.count)
    XCTAssertEqual(store.state.player.source, detail.title.replacingOccurrences(of: "\n", with: " "))
    await store.send(.player(.miniPlayerTapped)) { $0.player.isExpanded = true }
    await store.send(.player(.collapseTapped)) { $0.player.isExpanded = false }
  }
}
