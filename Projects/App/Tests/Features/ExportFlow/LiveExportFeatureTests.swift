import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-050 · UI-14l · 14m

@MainActor
final class LiveExportFeatureTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1800000000)

  func testTexts() {
    XCTAssertEqual(
      ExportText.untilDeadline(from: self.now, to: self.now.addingTimeInterval(2 * 86400 + 4 * 3600)),
      "2일 4시간"
    )
    XCTAssertEqual(ExportText.untilDeadline(from: self.now, to: self.now.addingTimeInterval(3 * 3600 + 59)), "3시간")
    XCTAssertEqual(ExportText.untilDeadline(from: self.now, to: self.now.addingTimeInterval(20)), "1분")
    XCTAssertEqual(
      ExportText.liveTop(["Radical Optimism", "Houdini"] + Array(repeating: "곡", count: 10)),
      "1위 Radical Optimism · 2위 Houdini 외 10곡"
    )
  }

  func testExport_sendsTopTwelveWithAutoSync() async {
    let songs = (1 ... 15).map { ExportSong(id: "s\($0)", title: "곡 \($0)", artist: "가수", recommender: "") }
    let sent = LockIsolated<(count: Int, autoSync: Bool)?>(nil)
    let playlist = ExportedPlaylist.mock(id: "p", relayID: "cafe", title: "카페", service: .appleMusic, endsAt: self.now)
    let state = LiveExportFeature.State(relayID: "cafe", title: "카페", endsAt: self.now, songs: songs)
    XCTAssertEqual(state.songs.count, 12)
    let store = TestStore(initialState: state) { LiveExportFeature() } withDependencies: {
      $0.exportClient.exportLive = { _, _, ids, autoSync in
        sent.setValue((ids.count, autoSync))
        return playlist
      }
    }
    await store.send(.autoSyncToggled(false)) { $0.autoSync = false }
    await store.send(.exportTapped) { $0.isExporting = true }
    await store.receive(.exported(playlist)) { $0.isExporting = false }
    await store.receive(.delegate(.exported(playlist)))
    XCTAssertEqual(sent.value?.count, 12)
    XCTAssertEqual(sent.value?.autoSync, false)
  }

  func testExportedPlaylist_syncToggleRollsBackOnFailure() async {
    struct Failure: Error {}
    let playlist = ExportedPlaylist.mock(id: "p", relayID: "cafe", title: "카페", service: .appleMusic, endsAt: self.now)
    let store = TestStore(initialState: ExportedPlaylistFeature.State(playlistID: "p", playlist: playlist)) {
      ExportedPlaylistFeature()
    } withDependencies: {
      $0.exportClient.setSync = { _, _ in throw Failure() }
    }
    await store.send(.syncToggleTapped) { $0.playlist?.isSyncOn = false }
    await store.receive(.syncFailed(restore: true)) {
      $0.playlist?.isSyncOn = true
      $0.toast = "자동 반영을 바꾸지 못했어요"
    }
  }

  func testExportedPlaylist_loadsOnAppear() async {
    let playlist = ExportedPlaylist.mock(id: "p", relayID: "cafe", title: "카페", service: .spotify, endsAt: nil)
    let store = TestStore(initialState: ExportedPlaylistFeature.State(playlistID: "p")) {
      ExportedPlaylistFeature()
    } withDependencies: {
      $0.exportClient.fetchExported = { _ in playlist }
    }
    await store.send(.onAppear)
    await store.receive(.loaded(playlist)) { $0.playlist = playlist }
    XCTAssertFalse(playlist.isSyncOn)
  }
}
