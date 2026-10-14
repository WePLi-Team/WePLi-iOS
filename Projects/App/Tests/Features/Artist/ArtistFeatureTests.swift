import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-024 · UI-5b · DEC-004

@MainActor
final class ArtistFeatureTests: XCTestCase {
  func testOnAppear_loadsArtist() async {
    let artist = ArtistDetail.mock(id: "아이유")
    let store = TestStore(initialState: ArtistFeature.State(artistID: "아이유")) {
      ArtistFeature()
    } withDependencies: {
      $0.artistClient.fetch = { _ in artist }
    }

    await store.send(.onAppear)
    await store.receive(.loaded(artist)) { $0.artist = artist }
    XCTAssertEqual(artist.name, "아이유 (IU)")
    XCTAssertEqual(artist.meta(for: artist.places[0]), "플레이리스트 · 아이유 3곡 포함")
    XCTAssertEqual(artist.meta(for: artist.places[1]), "게시글 · dlwlrma")
    XCTAssertEqual(artist.popularSongs[0].subtitle, "밤편지 · 2017")
  }

  func testLoadFailure_thenRetry() async {
    let store = TestStore(initialState: ArtistFeature.State(artistID: "아이유")) {
      ArtistFeature()
    } withDependencies: {
      $0.artistClient.fetch = { _ in throw URLError(.notConnectedToInternet) }
    }

    await store.send(.onAppear)
    await store.receive(.loadFailed) { $0.loadFailed = true }
    await store.send(.retryButtonTapped) { $0.loadFailed = false }
    await store.receive(.loadFailed) { $0.loadFailed = true }
  }

  func testLike_isOptimisticAndRollsBack() async {
    let artist = ArtistDetail.mock(id: "아이유")
    let store = TestStore(initialState: ArtistFeature.State(artistID: "아이유", artist: artist)) {
      ArtistFeature()
    } withDependencies: {
      $0.artistClient.setLiked = { _, _ in throw URLError(.timedOut) }
    }

    await store.send(.likeButtonTapped) { $0.artist?.isLiked = true }
    await store.receive(.likeFailed(restore: false)) { $0.artist?.isLiked = false }
  }

  func testTaps_delegate() async {
    let artist = ArtistDetail.mock(id: "아이유")
    let store = TestStore(initialState: ArtistFeature.State(artistID: "아이유", artist: artist)) {
      ArtistFeature()
    }

    await store.send(.relatedArtistTapped("비투비"))
    await store.receive(.delegate(.showArtist("비투비")))
    await store.send(.placeTapped("pl-1"))
    await store.receive(.delegate(.showPlaylist("pl-1")))
    await store.send(.placeTapped("post-1"))
    await store.receive(.delegate(.showPost("post-1")))
    await store.send(.songTapped("밤편지"))
    await store.receive(.delegate(.showSong("밤편지")))
    await store.send(.backButtonTapped)
    await store.receive(.delegate(.dismiss))
  }
}
