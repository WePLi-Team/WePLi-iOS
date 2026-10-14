import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-078 · UI-10d · DEC-004

@MainActor
final class MyPlaylistFeatureTests: XCTestCase {
  private func loaded(editing: Bool = false) -> MyPlaylistFeature.State {
    var state = MyPlaylistFeature.State(playlistID: "album")
    state.playlist = .mock(id: "album")
    if editing {
      state.isEditing = true
      state.beforeEdit = state.playlist
    }
    return state
  }

  func testMeta_andNameLimit() {
    XCTAssertEqual(MyPlaylist.mock(id: "album").meta, "6곡 · 비공개")
    XCTAssertEqual(MyPlaylist.clampName(String(repeating: "가", count: 40)).count, 30)
  }

  func testEditing_appliesLiveAndSavesOnDone() async {
    let saved = LockIsolated<MyPlaylist?>(nil)
    let store = TestStore(initialState: self.loaded()) {
      MyPlaylistFeature()
    } withDependencies: {
      $0.myPlaylistClient.save = { playlist in
        saved.setValue(playlist)
        return playlist
      }
    }
    let original = MyPlaylist.mock(id: "album")

    await store.send(.editButtonTapped) {
      $0.isEditing = true
      $0.beforeEdit = original
    }
    await store.send(.removeTapped("bam")) { $0.playlist?.tracks.removeAll { $0.id == "bam" } }
    XCTAssertEqual(store.state.playlist?.meta, "5곡 · 비공개")
    // 맨 위에서 ▲는 아무 일도 없다
    await store.send(.moveUpTapped("shopper"))
    await store.send(.moveDownTapped("shopper")) {
      $0.playlist?.tracks.swapAt(0, 1)
    }
    await store.send(.nameChanged("새 이름")) { $0.playlist?.name = "새 이름" }

    await store.send(.editButtonTapped) {
      $0.isEditing = false
      $0.isSaving = true
    }
    let edited = try? XCTUnwrap(store.state.playlist)
    await store.receive(.saved(edited ?? original)) {
      $0.isSaving = false
      $0.beforeEdit = nil
    }
    XCTAssertEqual(saved.value?.tracks.map(\.id), ["supernova", "shopper", "rain", "lovepoem", "sea"])
  }

  func testDoneWithoutChanges_doesNotSave() async {
    let store = TestStore(initialState: self.loaded(editing: true)) {
      MyPlaylistFeature()
    }

    await store.send(.editButtonTapped) {
      $0.isEditing = false
      $0.beforeEdit = nil
    }
  }

  func testEmptyName_keepsOriginal_andSaveFailureRollsBack() async {
    let store = TestStore(initialState: self.loaded(editing: true)) {
      MyPlaylistFeature()
    } withDependencies: {
      $0.myPlaylistClient.save = { _ in throw URLError(.timedOut) }
    }
    let original = MyPlaylist.mock(id: "album")

    await store.send(.removeTapped("sea")) { $0.playlist?.tracks.removeAll { $0.id == "sea" } }
    await store.send(.nameChanged("  ")) { $0.playlist?.name = "  " }
    await store.send(.editButtonTapped) {
      $0.isEditing = false
      $0.isSaving = true
      $0.playlist?.name = original.name
    }
    await store.receive(.saveFailed) {
      $0.isSaving = false
      $0.playlist = original
      $0.beforeEdit = nil
      $0.toast = "변경 사항을 저장하지 못했어요"
    }
  }

  func testDelete_confirmsThenDelegates() async {
    let store = TestStore(initialState: self.loaded(editing: true)) {
      MyPlaylistFeature()
    } withDependencies: {
      $0.myPlaylistClient.delete = { _ in }
    }
    store.exhaustivity = .off

    await store.send(.deleteTapped)
    XCTAssertNotNil(store.state.deleteDialog)
    await store.send(.deleteDialog(.presented(.confirm)))
    await store.receive(.deleted)
    await store.receive(.delegate(.deleted("album")))
  }
}

@MainActor
final class MyPlaylistNavigationTests: XCTestCase {
  func testLibraryPlaylist_opensAndDeleteRemovesFromLibrary() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .my
    var library = LibraryFeature.State(segment: .playlists)
    library.library = .mock(now: Date(timeIntervalSince1970: 0))
    initial.myPath.append(.library(library))
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    } withDependencies: {
      $0.myPlaylistClient.delete = { _ in }
    }
    store.exhaustivity = .off
    let libraryID = initial.myPath.ids[0]

    await store.send(.myPath(.element(id: libraryID, action: .library(.playlistTapped("album")))))
    await store.receive(.myPath(.element(id: libraryID, action: .library(.delegate(.showPlaylist("album"))))))
    guard let playlistID = store.state.myPath.ids.last, store.state.myPath.count == 2 else {
      return XCTFail("내 플레이리스트가 열리지 않음")
    }

    await store.send(.myPath(.element(id: playlistID, action: .myPlaylist(.deleteTapped))))
    await store.send(.myPath(.element(id: playlistID, action: .myPlaylist(.deleteDialog(.presented(.confirm))))))
    await store.skipReceivedActions()
    XCTAssertEqual(store.state.myPath.count, 1)
    XCTAssertEqual(
      store.state.myPath[id: libraryID, case: \.library]?.library?.playlists.map(\.id),
      ["rainy"]
    )
  }
}
