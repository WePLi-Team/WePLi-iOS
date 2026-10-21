import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-079 · UI-13a

@MainActor
final class ListeningShareFeatureTests: XCTestCase {
  func testDoneText() {
    var settings = ListeningShareSettings()
    XCTAssertEqual(ListeningShareText.done(settings, nickname: "김동"), "이제 친구들이 김동님이 듣는 음악을 볼 수 있어요.")
    settings.visibility = .groups
    XCTAssertEqual(ListeningShareText.done(settings, nickname: "김동"), "고른 그룹 멤버들이 볼 수 있어요.")
    settings.groups = ["우리 넷", "밴드부"]
    XCTAssertEqual(ListeningShareText.done(settings, nickname: "김동"), "우리 넷, 밴드부 멤버들이 볼 수 있어요.")
  }

  func testNext_needsOneConnectedService() async {
    let store = TestStore(initialState: ListeningShareFeature.State(nickname: "김동")) { ListeningShareFeature()
    } withDependencies: {
      $0.listeningShareClient.connect = { _ in true }
      $0.listeningShareClient.disconnect = { _ in }
    }
    await store.send(.nextTapped)
    await store.send(.stepTapped(.visibility))
    await store.send(.serviceTapped(.spotify)) { $0.connecting = .spotify }
    await store.receive(.connectResult(.spotify, true)) {
      $0.connecting = nil
      $0.connected = [.spotify]
    }
    await store.send(.nextTapped) { $0.step = .visibility }
    // 연결됨을 다시 누르면 끊는다
    await store.send(.stepTapped(.connect)) { $0.step = .connect }
    await store.send(.serviceTapped(.spotify)) { $0.connecting = .spotify }
    await store.receive(.connectResult(.spotify, false)) {
      $0.connecting = nil
      $0.connected = []
    }
  }

  func testVisibility_groupsAndSave() async {
    var state = ListeningShareFeature.State(nickname: "김동")
    state.connected = [.appleMusic]
    state.step = .visibility
    let saved = LockIsolated<ListeningShareSettings?>(nil)
    let store = TestStore(initialState: state) { ListeningShareFeature() } withDependencies: {
      $0.listeningShareClient.groups = { ["우리 넷", "밴드부", "점심 메이트"] }
      $0.listeningShareClient.save = { saved.setValue($0) }
    }
    await store.send(.onAppear)
    await store.receive(.groupsLoaded(["우리 넷", "밴드부", "점심 메이트"])) {
      $0.groups = ["우리 넷", "밴드부", "점심 메이트"]
      $0.settings.groups = ["우리 넷"]
    }
    XCTAssertEqual(store.state.settings.visibility, .friends)
    await store.send(.visibilitySelected(.groups)) { $0.settings.visibility = .groups }
    await store.send(.groupToggled("밴드부")) { $0.settings.groups = ["우리 넷", "밴드부"] }
    await store.send(.groupToggled("우리 넷")) { $0.settings.groups = ["밴드부"] }
    await store.send(.hidesAtNightToggled(true)) { $0.settings.hidesAtNight = true }
    await store.send(.doneTapped) { $0.isSaving = true }
    await store.receive(.saved) {
      $0.isSaving = false
      $0.step = .done
    }
    XCTAssertEqual(saved.value?.groups, ["밴드부"])
    XCTAssertEqual(saved.value?.hidesAtNight, true)
  }
}

extension MainTabFeatureTests {
  func testListeningShareMenu_opensFullScreen() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .my
    let store = TestStore(initialState: initial) { MainTabFeature() }
    store.exhaustivity = .off
    await store.send(.my(.menuTapped(.listeningShare)))
    await store.receive(.my(.delegate(.show(.listeningShare))))
    XCTAssertNotNil(store.state.listeningShare)
    await store.send(.listeningShare(.presented(.closeTapped)))
    await store.receive(.listeningShare(.presented(.delegate(.dismiss))))
    XCTAssertNil(store.state.listeningShare)
  }
}
