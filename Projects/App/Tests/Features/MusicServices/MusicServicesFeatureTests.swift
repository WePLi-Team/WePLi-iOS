import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-050 · UI-11b

@MainActor
final class MusicServicesFeatureTests: XCTestCase {
  private struct Failure: Error {}

  private func loaded() -> MusicServicesFeature.State {
    MusicServicesFeature.State(settings: .mock)
  }

  func testStatusText() {
    let connections = MusicServiceSettings.mock.connections
    XCTAssertEqual(
      connections.map(\.status),
      ["연결됨 · 내보내기 · 지금 듣는 중", "연결됨 · 내보내기 · 지금 듣는 중", "내보내기만", "지금 듣는 중만"]
    )
    // Last.fm은 플리를 받을 수 없어 기본으로 담을 곳에서 뺀다(DEC-018)
    XCTAssertEqual(MusicServiceSettings.mock.destinations.map(\.service), [.appleMusic, .spotify, .youtubeMusic])
  }

  func testDisconnectingDefault_movesDefaultToFirstConnected() {
    var settings = MusicServiceSettings.mock
    settings.setConnected(.appleMusic, false)
    XCTAssertEqual(settings.defaultService, .spotify)
    settings.setConnected(.spotify, false)
    XCTAssertNil(settings.defaultService)
    // Last.fm을 연결해도 기본으로 담을 곳이 되지 않는다
    settings.setConnected(.lastFM, true)
    XCTAssertNil(settings.defaultService)
    settings.setConnected(.youtubeMusic, true)
    XCTAssertEqual(settings.defaultService, .youtubeMusic)
  }

  func testConnect_marksConnected() async {
    let store = TestStore(initialState: self.loaded()) { MusicServicesFeature() } withDependencies: {
      $0.musicServicesClient.connect = { _ in }
    }
    await store.send(.connectTapped(.lastFM)) { $0.connecting = .lastFM }
    await store.receive(.connected(.lastFM)) {
      $0.connecting = nil
      $0.settings?.connections[3].isConnected = true
    }
  }

  func testDefault_onlyConnectedAndRollsBack() async {
    let store = TestStore(initialState: self.loaded()) { MusicServicesFeature() } withDependencies: {
      $0.musicServicesClient.setDefault = { _ in throw Failure() }
    }
    // 연결 안 된 YouTube Music은 고를 수 없다
    await store.send(.defaultSelected(.youtubeMusic))
    await store.send(.defaultSelected(.spotify)) { $0.settings?.defaultService = .spotify }
    await store.receive(.saveFailed(previous: .mock)) {
      $0.settings?.defaultService = .appleMusic
      $0.toast = "설정을 저장하지 못했어요"
    }
  }

  func testDisconnect_andAutoExportSave() async {
    let store = TestStore(initialState: self.loaded()) { MusicServicesFeature() } withDependencies: {
      $0.musicServicesClient.disconnect = { _ in }
      $0.musicServicesClient.setAutoExport = { _ in }
    }
    await store.send(.disconnectTapped(.appleMusic)) {
      $0.settings?.connections[0].isConnected = false
      $0.settings?.defaultService = .spotify
    }
    await store.send(.autoExportToggled(false)) { $0.settings?.autoExport = false }
  }

  func testExportedRow_opensExportedPlaylist() async {
    let store = TestStore(initialState: self.loaded()) { MusicServicesFeature() }
    await store.send(.exportedTapped("cafe-bgm"))
    await store.receive(.delegate(.showExported(playlistID: "cafe-bgm")))
  }
}
