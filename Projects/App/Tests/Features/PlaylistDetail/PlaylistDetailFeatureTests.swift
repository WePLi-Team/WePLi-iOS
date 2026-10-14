import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-025 · UI-3d · DEC-004

@MainActor
final class PlaylistDetailFeatureTests: XCTestCase {
  func testInfo_matchesDesign() {
    XCTAssertEqual(PlaylistDetail.mock(id: "p").info, "2024.09.08 • 12곡 • 1시간 34분")
  }

  func testOnAppear_loadsOnce() async {
    let store = TestStore(initialState: PlaylistDetailFeature.State(playlistID: "p")) {
      PlaylistDetailFeature()
    } withDependencies: {
      $0.playlistDetailClient.fetch = { id in .mock(id: id) }
    }

    await store.send(.onAppear)
    await store.receive(.loaded(.mock(id: "p"))) {
      $0.playlist = .mock(id: "p")
    }
    await store.send(.onAppear)
  }

  func testIntroduction_togglesExpanded() async {
    let store = TestStore(initialState: PlaylistDetailFeature.State(playlistID: "p", playlist: .mock(id: "p"))) {
      PlaylistDetailFeature()
    }

    await store.send(.introductionTapped) { $0.isIntroductionExpanded = true }
    await store.send(.introductionTapped) { $0.isIntroductionExpanded = false }
  }

  func testSave_optimisticAndRestoredOnFailure() async {
    let store = TestStore(initialState: PlaylistDetailFeature.State(playlistID: "p", playlist: .mock(id: "p"))) {
      PlaylistDetailFeature()
    } withDependencies: {
      $0.playlistDetailClient.setSaved = { _, _ in throw URLError(.timedOut) }
    }

    await store.send(.saveButtonTapped) { $0.playlist?.isSaved = true }
    await store.receive(.saveFailed(restore: false)) { $0.playlist?.isSaved = false }
  }

  func testPlayAndShuffle_sendDelegates() async {
    let store = TestStore(initialState: PlaylistDetailFeature.State(playlistID: "p", playlist: .mock(id: "p"))) {
      PlaylistDetailFeature()
    }

    await store.send(.playButtonTapped)
    await store.receive(.delegate(.play(playlistID: "p", shuffled: false)))
    await store.send(.shuffleButtonTapped)
    await store.receive(.delegate(.play(playlistID: "p", shuffled: true)))
    await store.send(.artistTapped("비투비"))
    await store.receive(.delegate(.showArtist("비투비")))
  }
}
