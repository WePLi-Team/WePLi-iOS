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
