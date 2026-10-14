import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-070 · UI-1e · UI-7g

@MainActor
final class MyFeatureTests: XCTestCase {
  func testOnAppear_loadsProfileAndVersion() async {
    let store = TestStore(initialState: MyFeature.State()) {
      MyFeature()
    } withDependencies: {
      $0.myClient.fetchProfile = { .mock }
      $0.myClient.appVersion = { "1.2.3" }
    }

    await store.send(.onAppear) {
      $0.appVersion = "1.2.3"
    }
    await store.receive(.profileLoaded(.mock)) {
      $0.profile = .mock
    }
  }

  func testOnAppear_whenProfileLoaded_doesNotRefetch() async {
    let store = TestStore(initialState: MyFeature.State(profile: .mock, appVersion: "1.0.0")) {
      MyFeature()
    } withDependencies: {
      $0.myClient.appVersion = { "1.0.0" }
    }

    await store.send(.onAppear)
  }

  func testProfileFailure_setsFlag() async {
    let store = TestStore(initialState: MyFeature.State()) {
      MyFeature()
    } withDependencies: {
      $0.myClient.fetchProfile = { throw URLError(.notConnectedToInternet) }
      $0.myClient.appVersion = { "1.0.0" }
    }

    await store.send(.onAppear) {
      $0.appVersion = "1.0.0"
    }
    await store.receive(.profileFailed) {
      $0.loadFailed = true
    }
  }

  func testTaps_sendDelegates() async {
    let store = TestStore(initialState: MyFeature.State()) {
      MyFeature()
    }

    await store.send(.businessCardButtonTapped)
    await store.receive(.delegate(.showBusinessCard))
    await store.send(.profileTapped)
    await store.receive(.delegate(.editProfile))
    await store.send(.menuTapped(.notificationSettings))
    await store.receive(.delegate(.show(.notificationSettings)))
    await store.send(.logoutTapped)
    await store.receive(.delegate(.logout))
  }

  func testSections_hideDeveloperModeUntilEnabled() {
    let hidden = MyFeature.State()
    XCTAssertEqual(hidden.sections, [.activity, .settings, .appInfo])
    XCTAssertFalse(MyMenuSection.allCases.flatMap { $0.menus(isDeveloperModeEnabled: false) }.contains(.developerMode))

    let shown = MyFeature.State(isDeveloperModeEnabled: true)
    XCTAssertEqual(shown.sections, [.activity, .settings, .appInfo, .etc])
    XCTAssertEqual(MyMenuSection.etc.menus(isDeveloperModeEnabled: true), [.developerMode])
  }

  func testMenus_useDesignCopy() {
    XCTAssertEqual(MyMenuSection.allCases.map(\.title), ["내 활동", "설정", "앱 정보", "기타"])
    XCTAssertEqual(
      MyMenuSection.activity.menus(isDeveloperModeEnabled: false).map(\.title),
      ["내 플레이리스트", "참여한 릴레이리스트", "좋아요 • 저장"]
    )
    XCTAssertEqual(Persona.allCases.map(\.name), ["소셜 튠즈", "멜로디 메모리즈", "노스텔지어 서너", "센티멘탈 심포니", "에너지 플래시"])
  }

  func testMockProfile_usesFakeEmail() {
    XCTAssertTrue(MyProfile.mock.email.hasSuffix("@example.com"))
  }
}
