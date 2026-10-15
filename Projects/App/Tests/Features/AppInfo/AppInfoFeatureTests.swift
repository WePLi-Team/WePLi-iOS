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
    await store.send(.documentTapped("policy")) { $0.document = AppDocument.all[2] }
    await store.send(.backButtonTapped) { $0.document = nil }
    await store.send(.backButtonTapped)
    await store.receive(.delegate(.dismiss))
  }
}
