import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-023 · REQ-022 · UI-2d · DEC-004

@MainActor
final class SongDetailFeatureTests: XCTestCase {
  func testPreviewText_andProgress() {
    XCTAssertEqual(SongPreview.elapsedText(7), "0:07")
    XCTAssertEqual(SongPreview.remainingText(7), "-0:23")
    XCTAssertEqual(SongPreview.progress(15), 0.5)
    XCTAssertEqual(SongPreview.elapsedText(40), "0:30")
  }

  func testPreview_stopsAndResetsAfterThirtySeconds() async {
    let clock = TestClock()
    let store = TestStore(initialState: SongDetailFeature.State(songID: "s", song: .mock(id: "s"))) {
      SongDetailFeature()
    } withDependencies: {
      $0.continuousClock = clock
    }
    store.exhaustivity = .off

    await store.send(.previewButtonTapped) {
      $0.isPlaying = true
    }
    await clock.advance(by: .seconds(29))
    await store.skipReceivedActions()
    XCTAssertEqual(store.state.position, 29)
    XCTAssertTrue(store.state.isPlaying)
    await clock.advance(by: .seconds(1))
    await store.skipReceivedActions()
    XCTAssertFalse(store.state.isPlaying)
    XCTAssertEqual(store.state.position, 0)
    // 멈춘 뒤에는 더 진행하지 않는다
    await clock.advance(by: .seconds(5))
    XCTAssertEqual(store.state.position, 0)
  }

  func testPause_keepsPositionAndResumes() async {
    let clock = TestClock()
    let store = TestStore(initialState: SongDetailFeature.State(songID: "s", song: .mock(id: "s"))) {
      SongDetailFeature()
    } withDependencies: {
      $0.continuousClock = clock
    }

    await store.send(.previewButtonTapped) {
      $0.isPlaying = true
    }
    await clock.advance(by: .seconds(2))
    await store.receive(.previewTicked) { $0.position = 1 }
    await store.receive(.previewTicked) { $0.position = 2 }
    await store.send(.previewButtonTapped) {
      $0.isPlaying = false
    }
    await store.send(.previewButtonTapped) {
      $0.isPlaying = true
    }
    await clock.advance(by: .seconds(1))
    await store.receive(.previewTicked) { $0.position = 3 }
    await store.send(.onDisappear) {
      $0.isPlaying = false
    }
  }

  func testLike_optimisticAndRestoredOnFailure() async {
    let store = TestStore(initialState: SongDetailFeature.State(songID: "s", song: .mock(id: "s"))) {
      SongDetailFeature()
    } withDependencies: {
      $0.songDetailClient.setLiked = { _, _ in throw URLError(.timedOut) }
    }

    await store.send(.likeButtonTapped) {
      $0.song?.isLiked = true
      $0.song?.likeCount = 10124
    }
    await store.receive(.likeFailed(restore: false)) {
      $0.song?.isLiked = false
      $0.song?.likeCount = 10123
    }
  }

  func testOnAppear_loads() async {
    let store = TestStore(initialState: SongDetailFeature.State(songID: "s")) {
      SongDetailFeature()
    } withDependencies: {
      $0.songDetailClient.fetch = { id in .mock(id: id) }
    }

    await store.send(.onAppear)
    await store.receive(.loaded(.mock(id: "s"))) {
      $0.song = .mock(id: "s")
    }
    XCTAssertEqual(store.state.song?.meta, "밤편지 · 싱글 · 2017.03.24")
    XCTAssertEqual(store.state.song?.artistTag, "#아이유(IU)")
  }

  func testTaps_sendDelegates() async {
    let store = TestStore(initialState: SongDetailFeature.State(songID: "s", song: .mock(id: "s"))) {
      SongDetailFeature()
    }

    await store.send(.addToPlaylistTapped)
    await store.receive(.delegate(.addToPlaylist(songID: "s")))
    await store.send(.openInMusicTapped)
    await store.receive(.delegate(.openInMusic(songID: "s")))
    await store.send(.artistTapped)
    await store.receive(.delegate(.showArtist))
    await store.send(.recommendTapped)
    await store.receive(.delegate(.recommendToRelay(songID: "s")))
    await store.send(.relayTapped("first-love"))
    await store.receive(.delegate(.showRelay("first-love")))
  }

  /// 2d v2 — 함께 들으면 좋은 곡의 재생 아이콘은 곡 상세 미리듣기를 멈추고 플레이어로 넘긴다
  func testRelatedPlay_stopsPreviewAndSendsDelegate() async {
    var state = SongDetailFeature.State(songID: "s", song: .mock(id: "s"))
    state.isPlaying = true
    let store = TestStore(initialState: state) {
      SongDetailFeature()
    }

    await store.send(.relatedPlayTapped("Blueming")) {
      $0.isPlaying = false
    }
    await store.receive(.delegate(.playRelated("Blueming")))
  }
}
