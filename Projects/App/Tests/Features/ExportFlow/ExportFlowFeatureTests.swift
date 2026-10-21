import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-050 · UI-14c–14k · UI-14o

@MainActor
final class ExportFlowFeatureTests: XCTestCase {
  private func makeState() -> ExportFlowFeature.State {
    ExportFlowFeature.State(
      relayID: "r1",
      title: "졸릴 때 잠 깨는 청량맛 노동요",
      recommenderCount: 248,
      songs: ExportSample.songs
    )
  }

  func testSelection_summaryAndCounts() {
    var state = self.makeState()
    XCTAssertEqual(state.name, "WePLi · 졸릴 때 잠 깨는 청량맛 노동요")
    XCTAssertEqual(ExportText.summary(state.selectedSongs), "Supernova, How Sweet, Hype Boy 외 9곡")
    state.selection = .top10
    XCTAssertEqual(ExportText.summary(state.selectedSongs), "Supernova, How Sweet, Hype Boy 외 7곡")
    state.selection = .voted
    XCTAssertEqual(ExportText.summary(state.selectedSongs), "Supernova, Hype Boy, 해야 (HEYA) 외 2곡")
    XCTAssertEqual(ExportSelection.voted.title(total: 12, votedCount: state.votedCount), "내가 투표한 5곡")
  }

  func testListFormat_lines() {
    let songs = Array(ExportSample.songs.prefix(2))
    XCTAssertEqual(ExportListFormat.titleFirst.lines(songs), ["1. Supernova - aespa", "2. How Sweet - NewJeans"])
    XCTAssertEqual(ExportListFormat.artistFirst.lines(songs), ["1. aespa - Supernova", "2. NewJeans - How Sweet"])
  }

  func testName_limitedTo40() async {
    let store = TestStore(initialState: self.makeState()) { ExportFlowFeature() }
    await store.send(.nameChanged(String(repeating: "가", count: 45))) {
      $0.name = String(repeating: "가", count: 40)
    }
  }

  func testLastService_staysWhenAnotherIsSelected() async {
    let store = TestStore(initialState: self.makeState()) { ExportFlowFeature() }
    XCTAssertEqual(store.state.lastService, .appleMusic)
    await store.send(.serviceSelected(.spotify)) { $0.service = .spotify }
    XCTAssertEqual(store.state.lastService, .appleMusic)
  }

  func testOtherApps_goesToCopyList_andBack() async {
    let store = TestStore(initialState: self.makeState()) { ExportFlowFeature() } withDependencies: {
      $0.exportClient.isConnected = { $0 == .appleMusic }
    }
    await store.send(.serviceSelected(.otherApps)) { $0.service = .otherApps }
    await store.send(.serviceNextTapped) { $0.step = .copyList }
    await store.receive(.connections([.appleMusic])) { $0.connected = [.appleMusic] }
    await store.send(.backTapped) { $0.step = .service }
  }

  func testConnectedService_skipsPermissionAndMatches() async {
    let store = TestStore(initialState: self.makeState()) { ExportFlowFeature() } withDependencies: {
      $0.exportClient.hasSubscription = { true }
      $0.exportClient.match = { _, songs in
        AsyncStream { continuation in
          for song in songs {
            continuation.yield(ExportMatchEvent(songID: song.id, match: ExportSample.match(for: song.id)))
          }
          continuation.finish()
        }
      }
    }
    store.exhaustivity = .off
    await store.send(.selectionSelected(.voted))
    await store.send(.connections([.appleMusic]))
    await store.send(.addTapped)
    await store.skipReceivedActions()
    XCTAssertEqual(store.state.step, .review)
    XCTAssertEqual(store.state.matchedCount, 5)
    // 투표한 5곡 중 Small girl만 다른 버전 — 그대만 있다면은 투표한 곡이 아니다
    XCTAssertEqual(store.state.foundSongs.count, 4)
    XCTAssertEqual(store.state.checkSongs.map(\.id), ["small-girl"])
    XCTAssertEqual(store.state.exportSongIDs.count, 5)
  }

  func testAppleMusic_firstTime_asksPermission() async {
    let store = TestStore(initialState: self.makeState()) { ExportFlowFeature() } withDependencies: {
      $0.exportClient.isConnected = { _ in false }
      $0.exportClient.connect = { _ in false }
    }
    await store.send(.serviceNextTapped) { $0.step = .settings }
    await store.receive(\.connections)
    await store.send(.addTapped) { $0.step = .appleMusicPermission }
    await store.send(.connectTapped) { $0.isConnecting = true }
    await store.receive(.connectResult(false)) {
      $0.isConnecting = false
      $0.toast = "Apple Music에 연결하지 못했어요"
    }
    await store.send(.laterTapped) { $0.step = .settings }
  }

  func testSpotify_connectsWithoutExplainer() async {
    var state = self.makeState()
    state.step = .settings
    state.service = .spotify
    state.connected = [.appleMusic]
    let store = TestStore(initialState: state) { ExportFlowFeature() } withDependencies: {
      $0.exportClient.connect = { _ in true }
      $0.exportClient.match = { _, _ in AsyncStream { $0.finish() } }
    }
    await store.send(.addTapped) { $0.isConnecting = true }
    await store.receive(.connectResult(true)) {
      $0.isConnecting = false
      $0.connected = [.appleMusic, .spotify]
      $0.step = .matching
    }
    await store.receive(.matchingFinished) { $0.step = .review }
  }

  func testReview_alternativeAndSkipChangeCount() async {
    var state = self.makeState()
    state.step = .review
    for song in state.songs {
      state.matches[song.id] = ExportSample.match(for: song.id)
    }
    let store = TestStore(initialState: state) { ExportFlowFeature() }
    // 고르기 전에는 「확인 필요」 곡을 담지 않는다
    XCTAssertEqual(store.state.exportSongIDs.count, 11)
    XCTAssertEqual(store.state.foundSongs.count, 10)
    let live = ExportSample.alternatives[0]
    await store.send(.changeTapped("nerd")) { $0.picking = "nerd" }
    await store.send(.alternativePicked(.replace(live))) { $0.pick = .replace(live) }
    await store.send(.alternativeConfirmTapped) {
      $0.resolutions["nerd"] = .replace(live)
      $0.picking = nil
      $0.pick = nil
    }
    XCTAssertEqual(store.state.exportSongIDs.count, 12)
    XCTAssertTrue(store.state.exportSongIDs.contains("live"))
    await store.send(.changeTapped("nerd")) {
      $0.picking = "nerd"
      $0.pick = .replace(live)
    }
    await store.send(.alternativePicked(.skip)) { $0.pick = .skip }
    await store.send(.alternativeConfirmTapped) {
      $0.resolutions["nerd"] = .skip
      $0.picking = nil
      $0.pick = nil
    }
    XCTAssertEqual(store.state.exportSongIDs.count, 11)
  }

  func testConfirm_createsPlaylistAndShowsDone() async {
    var state = self.makeState()
    state.step = .review
    for song in state.songs {
      state.matches[song.id] = ExportSample.match(for: song.id)
    }
    let created = LockIsolated<[String]>([])
    let store = TestStore(initialState: state) { ExportFlowFeature() } withDependencies: {
      $0.exportClient.addSongs = { _, _, ids in
        created.setValue(ids)
        return "p1"
      }
    }
    await store.send(.addFoundOnlyTapped) {
      $0.isAdding = true
      $0.pendingSongIDs = $0.foundSongs.map(\.id)
    }
    await store.receive(.added(playlistID: "p1")) {
      $0.isAdding = false
      $0.playlistID = "p1"
      $0.addedCount = 10
      $0.step = .done
    }
    XCTAssertFalse(created.value.contains("nerd"))
    XCTAssertFalse(created.value.contains("small-girl"))
  }

  func testCopy_showsCopiedFor1800ms() async {
    let clock = TestClock()
    let copied = LockIsolated<String?>(nil)
    var state = self.makeState()
    state.step = .copyList
    let store = TestStore(initialState: state) { ExportFlowFeature() } withDependencies: {
      $0.continuousClock = clock
      $0.exportClient.copy = { copied.setValue($0) }
    }
    await store.send(.copyTapped) { $0.isCopied = true }
    await clock.advance(by: .milliseconds(1799))
    await clock.advance(by: .milliseconds(1))
    await store.receive(.copyReset) { $0.isCopied = false }
    XCTAssertEqual(copied.value?.components(separatedBy: "\n").first, "1. Supernova - aespa")
  }

  // MARK: 14f · 14n

  private func reviewState() -> ExportFlowFeature.State {
    var state = self.makeState()
    state.step = .review
    state.connected = [.appleMusic, .spotify]
    for song in state.songs {
      state.matches[song.id] = .found
    }
    return state
  }

  func testNoSubscription_showsSubscriptionNeeded() async {
    var state = self.makeState()
    state.step = .settings
    state.connected = [.appleMusic]
    let store = TestStore(initialState: state) { ExportFlowFeature() } withDependencies: {
      $0.exportClient.hasSubscription = { false }
    }
    await store.send(.addTapped)
    await store.receive(.subscriptionChecked(false)) { $0.step = .subscriptionNeeded }
    await store.send(.subscriptionOfferTapped) { $0.showsSubscriptionOffer = true }
    await store.send(.subscriptionOfferChanged(false)) { $0.showsSubscriptionOffer = false }
    await store.send(.copyListTapped) { $0.step = .copyList }
  }

  func testInterrupted_resumesRemainingSongsInSamePlaylist() async {
    let calls = LockIsolated<[ExportTarget]>([])
    let store = TestStore(initialState: self.reviewState()) { ExportFlowFeature() } withDependencies: {
      $0.exportClient.addSongs = { _, target, ids in
        calls.withValue { $0.append(target) }
        if case .new = target {
          throw ExportError.interrupted(playlistID: "p1", added: 8)
        }
        XCTAssertEqual(ids.count, 4)
        return "p1"
      }
    }
    store.exhaustivity = .off
    await store.send(.confirmTapped)
    await store.receive(.addStopped(.interrupted(playlistID: "p1", added: 8))) {
      $0.isAdding = false
      $0.playlistID = "p1"
      $0.addedCount = 8
      $0.step = .problem(.interrupted)
    }
    XCTAssertEqual(store.state.remainingSongIDs.count, 4)
    await store.send(.resumeTapped) { $0.isAdding = true }
    await store.receive(.added(playlistID: "p1")) {
      $0.isAdding = false
      $0.addedCount = 12
      $0.step = .done
    }
    XCTAssertEqual(calls.value.last, .append(playlistID: "p1"))
  }

  func testExpired_reconnectsThenResumes() async {
    var state = self.reviewState()
    state.service = .spotify
    let store = TestStore(initialState: state) { ExportFlowFeature() } withDependencies: {
      $0.exportClient.connect = { _ in true }
      $0.exportClient.addSongs = { _, target, _ in
        guard case .append = target else { throw ExportError.expired(playlistID: "p2", added: 3) }
        return "p2"
      }
    }
    store.exhaustivity = .off
    await store.send(.confirmTapped)
    await store.receive(.addStopped(.expired(playlistID: "p2", added: 3))) {
      $0.connected = [.appleMusic]
      $0.step = .problem(.expired)
    }
    await store.send(.reconnectTapped) { $0.isConnecting = true }
    await store.receive(.connectResult(true)) { $0.connected = [.appleMusic, .spotify] }
    await store.receive(.added(playlistID: "p2")) {
      $0.addedCount = 12
      $0.step = .done
    }
  }

  func testAlreadyExported_updateMatchesAgainAndReplaces() async {
    let record = ExportRecord(service: .appleMusic, playlistID: "am-1", exportedOn: "10월 12일", songCount: 12)
    var state = self.makeState()
    state = ExportFlowFeature.State(
      relayID: state.relayID,
      title: state.title,
      recommenderCount: 248,
      songs: state.songs,
      exported: record
    )
    XCTAssertEqual(state.step, .problem(.alreadyExported(record)))
    let target = LockIsolated<ExportTarget?>(nil)
    let store = TestStore(initialState: state) { ExportFlowFeature() } withDependencies: {
      $0.exportClient.hasSubscription = { true }
      $0.exportClient.match = { _, _ in AsyncStream { $0.finish() } }
      $0.exportClient.addSongs = { _, value, _ in
        target.setValue(value)
        return "am-1"
      }
    }
    store.exhaustivity = .off
    await store.send(.reExportContinueTapped) {
      $0.updatesExisting = true
      $0.playlistID = "am-1"
    }
    await store.receive(.subscriptionChecked(true))
    await store.receive(.matchingFinished) { $0.step = .review }
  }

  func testAlreadyExported_newGoesToSettings() async {
    let record = ExportRecord(service: .spotify, playlistID: "sp-1", exportedOn: "10월 12일", songCount: 12)
    let state = ExportFlowFeature.State(
      relayID: "r1",
      title: "졸릴 때 잠 깨는 청량맛 노동요",
      recommenderCount: 248,
      songs: ExportSample.songs,
      exported: record
    )
    let store = TestStore(initialState: state) { ExportFlowFeature() }
    XCTAssertEqual(store.state.service, .spotify)
    await store.send(.reExportSelected(.new)) { $0.reExport = .new }
    await store.send(.reExportContinueTapped) { $0.step = .settings }
  }
}
