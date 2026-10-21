import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-114 · UI-7g

@MainActor
final class AppInfoFeatureTests: XCTestCase {
  func testTexts() {
    XCTAssertNil(AppInfoText.developerToast(taps: 2))
    XCTAssertEqual(AppInfoText.developerToast(taps: 3), "개발자 모드까지 4번 남았어요")
    XCTAssertEqual(AppInfoText.developerToast(taps: 6), "개발자 모드까지 1번 남았어요")
    XCTAssertEqual(AppInfoText.developerToast(taps: 7), "개발자 모드가 켜졌어요")
    XCTAssertTrue(AppInfoText.isNewer("1.2.0", than: "1.0.0"))
    XCTAssertTrue(AppInfoText.isNewer("1.10", than: "1.9.9"))
    XCTAssertFalse(AppInfoText.isNewer("1.0", than: "1.0.0"))
  }

  func testOnAppear_showsUpdateOnlyWhenNewer() async {
    let store = TestStore(initialState: AppInfoFeature.State()) { AppInfoFeature() } withDependencies: {
      $0.appInfoClient.latestVersion = { "1.2.0" }
    }
    await store.send(.onAppear) { $0.version = "1.0.0" }
    await store.receive(.latestLoaded("1.2.0")) { $0.latestVersion = "1.2.0" }
    XCTAssertEqual(store.state.update, "1.2.0")
  }

  func testSevenTaps_enablesDeveloperMode() async {
    let clock = TestClock()
    let store = TestStore(initialState: AppInfoFeature.State()) { AppInfoFeature() } withDependencies: {
      $0.continuousClock = clock
    }
    await store.send(.versionTapped) { $0.versionTaps = 1 }
    await store.send(.versionTapped) { $0.versionTaps = 2 }
    await store.send(.versionTapped) {
      $0.versionTaps = 3
      $0.toast = "개발자 모드까지 4번 남았어요"
    }
    for taps in 4 ... 6 {
      await store.send(.versionTapped) {
        $0.versionTaps = taps
        $0.toast = "개발자 모드까지 \(7 - taps)번 남았어요"
      }
    }
    await store.send(.versionTapped) {
      $0.versionTaps = 7
      $0.toast = "개발자 모드가 켜졌어요"
      $0.isDeveloperModeEnabled = true
    }
    await store.receive(.delegate(.developerModeEnabled))
    await clock.advance(by: .milliseconds(1400))
    await store.receive(.toastExpired) { $0.toast = nil }
    // 켜진 뒤에는 더 세지 않는다
    await store.send(.versionTapped)
  }

  func testDocument_opensAndBackReturns() async {
    let store = TestStore(initialState: AppInfoFeature.State()) { AppInfoFeature() }
    await store.send(.documentTapped("terms")) { $0.document = AppDocument.all[0] }
    await store.send(.backButtonTapped) { $0.document = nil }
    await store.send(.backButtonTapped)
    await store.receive(.delegate(.dismiss))
  }

  func testPolicyDocument_opensCommunityPolicyScreen() async {
    let store = TestStore(initialState: AppInfoFeature.State()) { AppInfoFeature() }
    await store.send(.documentTapped(AppDocument.policyID))
    await store.receive(.delegate(.showCommunityPolicy))
  }
}

extension MainTabFeatureTests {
  func testMyMenus_openNoticesAndAppInfo_developerModeShowsRow() async throws {
    var initial = MainTabFeature.State()
    initial.selectedTab = .my
    let store = TestStore(initialState: initial) { MainTabFeature() } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }
    store.exhaustivity = .off
    await store.send(.my(.menuTapped(.noticesAndTerms)))
    await store.receive(.my(.delegate(.show(.noticesAndTerms))))
    guard case .notices? = store.state.myPath.last else { return XCTFail("공지가 열려야 한다") }

    await store.send(.my(.appVersionTapped))
    await store.receive(.my(.delegate(.showAppInfo)))
    let id = try XCTUnwrap(store.state.myPath.ids.last)
    for _ in 0 ..< 7 {
      await store.send(.myPath(.element(id: id, action: .appInfo(.versionTapped))))
    }
    await store.receive(.myPath(.element(id: id, action: .appInfo(.delegate(.developerModeEnabled)))))
    XCTAssertTrue(store.state.my.isDeveloperModeEnabled)
    XCTAssertEqual(
      MyMenuSection.etc.menus(isDeveloperModeEnabled: store.state.my.isDeveloperModeEnabled),
      [.developerMode]
    )
  }
}
