import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-082 · UI-5d · DEC-004

@MainActor
final class NotificationSettingsFeatureTests: XCTestCase {
  private func loaded() -> NotificationSettingsFeature.State {
    var state = NotificationSettingsFeature.State()
    state.settings = .defaults
    return state
  }

  func testDefaults_matchDesign() {
    let defaults = NotificationSettings.defaults
    XCTAssertTrue(defaults.isPushEnabled)
    XCTAssertFalse(defaults.enabled.contains(.like))
    XCTAssertFalse(defaults.enabled.contains(.promotion))
    XCTAssertTrue(defaults.enabled.contains(.deadline))
    XCTAssertEqual(defaults.quietHours, "22:00 – 08:00")
  }

  func testMasterOff_keepsChildValuesAndLocksToggles() async {
    var off = NotificationSettings.defaults
    off.isPushEnabled = false
    let store = TestStore(initialState: self.loaded()) {
      NotificationSettingsFeature()
    } withDependencies: {
      $0.notificationSettingsClient.save = { $0 }
    }

    await store.send(.pushToggled(false)) { $0.settings = off }
    await store.receive(.saved(off))
    XCTAssertEqual(store.state.settings?.enabled, NotificationSettings.defaults.enabled)
    // 잠긴 동안에는 하위 항목을 바꾸지 않는다
    await store.send(.settingToggled(.like, true))
  }

  func testPromotion_recordsConsentDateInSeoul() async {
    // 2026-10-14 15:30 UTC = 2026-10-15 00:30 KST
    let now = Date(timeIntervalSince1970: 1791991800)
    let store = TestStore(initialState: self.loaded()) {
      NotificationSettingsFeature()
    } withDependencies: {
      $0.date.now = now
      $0.notificationSettingsClient = .liveValue
    }
    store.exhaustivity = .off

    await store.send(.settingToggled(.promotion, true))
    await store.skipReceivedActions()
    XCTAssertEqual(store.state.settings?.promotionConsentDate, "2026.10.15")

    await store.send(.settingToggled(.promotion, false))
    await store.skipReceivedActions()
    XCTAssertNil(store.state.settings?.promotionConsentDate)
  }

  func testSaveFailure_restoresAndShowsToast() async {
    let store = TestStore(initialState: self.loaded()) {
      NotificationSettingsFeature()
    } withDependencies: {
      $0.notificationSettingsClient.save = { _ in throw URLError(.timedOut) }
    }
    var changed = NotificationSettings.defaults
    changed.enabled.insert(.like)

    await store.send(.settingToggled(.like, true)) { $0.settings = changed }
    await store.receive(.saveFailed(restore: .defaults)) {
      $0.settings = .defaults
      $0.toast = "설정을 저장하지 못했어요. 잠시 후 다시 시도해 주세요"
    }
  }

  func testConsentDate_formatsInSeoul() {
    XCTAssertEqual(ConsentDate.string(Date(timeIntervalSince1970: 1791991800)), "2026.10.15")
  }
}
