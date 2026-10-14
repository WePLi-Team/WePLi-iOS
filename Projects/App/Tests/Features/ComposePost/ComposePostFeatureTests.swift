import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-061 · REQ-062 · UI-2b · UI-2a

@MainActor
final class ComposePostFeatureTests: XCTestCase {
  private let iu = ComposeTrack(id: "c2", title: "밤편지", artist: "아이유 (IU)")
  private let aespa = ComposeTrack(id: "c10", title: "Supernova", artist: "aespa")

  // MARK: 2b 게시글 작성

  func testPublish_requiresTitleAndBody() {
    var state = ComposePostFeature.State()
    XCTAssertFalse(state.canPublish)
    state.title = "비 오는 날 듣는 플리"
    state.body = "   "
    XCTAssertFalse(state.canPublish)
    state.body = "좋은 노래 모음"
    XCTAssertTrue(state.canPublish)
  }

  func testBody_isClampedTo500() async {
    let store = TestStore(initialState: ComposePostFeature.State()) {
      ComposePostFeature()
    }
    await store.send(.bodyChanged(String(repeating: "가", count: 510))) {
      $0.body = String(repeating: "가", count: 500)
    }
  }

  func testPickerAdd_skipsDuplicates() async {
    var state = ComposePostFeature.State()
    state.tracks = [self.iu]
    state.picker = SongPickerFeature.State()
    let store = TestStore(initialState: state) {
      ComposePostFeature()
    }

    await store.send(.picker(.presented(.delegate(.add([self.iu, self.aespa]))))) {
      $0.tracks = [self.iu, self.aespa]
    }
  }

  func testAddSong_searchOpensPicker() async {
    let store = TestStore(initialState: ComposePostFeature.State()) {
      ComposePostFeature()
    }
    store.exhaustivity = .off

    await store.send(.addSongTapped)
    XCTAssertNotNil(store.state.addSongDialog)
    await store.send(.addSongDialog(.presented(.searchSongs)))
    XCTAssertNotNil(store.state.picker)
  }

  func testRemoveAndMoveTracks() async {
    var state = ComposePostFeature.State()
    state.tracks = [self.iu, self.aespa]
    let store = TestStore(initialState: state) {
      ComposePostFeature()
    }

    await store.send(.tracksMoved(IndexSet(integer: 0), 2)) { $0.tracks = [self.aespa, self.iu] }
    await store.send(.removeTrackTapped("c10")) { $0.tracks = [self.iu] }
  }

  func testPublish_trimsAndDelegates() async {
    let published = LockIsolated<PostDraft?>(nil)
    var state = ComposePostFeature.State()
    state.title = " 제목 "
    state.body = " 내용 "
    let store = TestStore(initialState: state) {
      ComposePostFeature()
    } withDependencies: {
      $0.composeClient.publish = { published.setValue($0) }
    }

    await store.send(.publishButtonTapped) { $0.isPublishing = true }
    await store.receive(.published) { $0.isPublishing = false }
    await store.receive(.delegate(.published))
    XCTAssertEqual(published.value, PostDraft(title: "제목", body: "내용", tracks: []))
  }

  // MARK: 2a 곡 검색 · 선택

  func testRecentSearches_latestFirstUniqueMaxEight() {
    let list = (1 ... 8).map { "검색\($0)" }
    XCTAssertEqual(RecentSearches.adding("검색3", to: list).prefix(3), ["검색3", "검색1", "검색2"])
    XCTAssertEqual(RecentSearches.adding("새 검색", to: list).count, 8)
    XCTAssertEqual(RecentSearches.adding("새 검색", to: list).last, "검색7")
  }

  func testSuggestion_searchesAndUpdatesRecent() async {
    var state = SongPickerFeature.State()
    state.recent = ["로이킴", "아이유"]
    let store = TestStore(initialState: state) {
      SongPickerFeature()
    } withDependencies: {
      $0.composeClient.searchTracks = { _ in [self.iu] }
    }

    await store.send(.suggestionTapped("아이유")) {
      $0.query = "아이유"
      $0.recent = ["아이유", "로이킴"]
      $0.isSearching = true
    }
    await store.receive(.resultsLoaded([self.iu])) {
      $0.isSearching = false
      $0.results = [self.iu]
    }
  }

  func testSelectAndAdd_clearsSelectionKeepsQuery() async {
    var state = SongPickerFeature.State()
    state.query = "아이유"
    state.results = [self.iu, self.aespa]
    let store = TestStore(initialState: state) {
      SongPickerFeature()
    }

    await store.send(.trackToggled("c2")) {
      $0.selectedIDs = ["c2"]
      $0.selectedTracks = [self.iu]
    }
    await store.send(.addButtonTapped) {
      $0.selectedIDs = []
      $0.selectedTracks = []
      $0.toast = "1곡을 게시글에 추가했어요"
    }
    await store.receive(.delegate(.add([self.iu])))
    XCTAssertEqual(store.state.query, "아이유")
  }

  func testCatalogSearch_matchesTitleOrArtist() async throws {
    let results = try await ComposeClient.liveValue.searchTracks("newjeans")
    XCTAssertEqual(results.map(\.title), ["How Sweet", "Hype Boy"])
  }
}
