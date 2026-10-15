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
    XCTAssertEqual(connections.map(\.status), ["연결됨 · iCloud 보관함", "연결됨 · dongdong0915", "연결 안 됨"])
  }

  func testDisconnectingDefault_movesDefaultToFirstConnected() {
    var settings = MusicServiceSettings.mock
    settings.setConnected(.appleMusic, false)
    XCTAssertEqual(settings.defaultService, .spotify)
    settings.setConnected(.spotify, false)
    XCTAssertNil(settings.defaultService)
    settings.setConnected(.youtubeMusic, true)
    XCTAssertEqual(settings.defaultService, .youtubeMusic)
  }

  func testConnect_marksConnectedWithDetail() async {
    let store = TestStore(initialState: self.loaded()) { MusicServicesFeature() } withDependencies: {
      $0.musicServicesClient.connect = { _ in "dong@gmail" }
    }
    await store.send(.connectTapped(.youtubeMusic)) { $0.connecting = .youtubeMusic }
    await store.receive(.connected(.youtubeMusic, detail: "dong@gmail")) {
      $0.connecting = nil
      $0.settings?.connections[2].isConnected = true
      $0.settings?.connections[2].detail = "dong@gmail"
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
      $0.settings?.connections[0].detail = nil
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
