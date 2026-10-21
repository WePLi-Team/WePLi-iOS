import ComposableArchitecture
@testable import WePLi
import XCTest

// #104 — 로그인 버튼을 누르면 메인 탭으로 임시 진입(실제 연동은 #14)

@MainActor
final class AppFeatureTests: XCTestCase {
  func testInitialState_isLogin() {
    XCTAssertEqual(AppFeature.State(), .login(LoginFeature.State()))
  }

  func testAppleLogin_entersMainTab() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }

    await store.send(.login(.appleLoginButtonTapped)) {
      $0 = .login(LoginFeature.State(isLoading: true))
    }
    // 로그인 직후 계정 상태를 확인한다(UI-17e) — 정상 계정이면 그대로 로그인을 마친다
    await store.receive(\.login.accountChecked)
    await store.receive(\.login.loginResponse) {
      $0 = .login(LoginFeature.State(isLoading: false))
    }
    // 메인 탭 상태는 생성 시각(Date())을 담고 있어 값 대신 화면 전환만 확인한다.
    store.exhaustivity = .off
    await store.receive(\.login.delegate)
    guard case .mainTab = store.state else {
      return XCTFail("메인 탭으로 들어가야 한다")
    }
  }

  func testGoogleLogin_entersMainTab() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }

    await store.send(.login(.googleLoginButtonTapped)) {
      $0 = .login(LoginFeature.State(isLoading: true))
    }
    // 로그인 직후 계정 상태를 확인한다(UI-17e) — 정상 계정이면 그대로 로그인을 마친다
    await store.receive(\.login.accountChecked)
    await store.receive(\.login.loginResponse) {
      $0 = .login(LoginFeature.State(isLoading: false))
    }
    // 메인 탭 상태는 생성 시각(Date())을 담고 있어 값 대신 화면 전환만 확인한다.
    store.exhaustivity = .off
    await store.receive(\.login.delegate)
    guard case .mainTab = store.state else {
      return XCTFail("메인 탭으로 들어가야 한다")
    }
  }

  func testLoginFailure_staysOnLogin() async {
    struct Failure: Error, LocalizedError {
      var errorDescription: String? {
        "실패"
      }
    }
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    } withDependencies: {
      $0.authClient.signInWithApple = { throw Failure() }
    }

    await store.send(.login(.appleLoginButtonTapped)) {
      $0 = .login(LoginFeature.State(isLoading: true))
    }
    await store.receive(\.login.loginResponse) {
      $0 = .login(LoginFeature.State(isLoading: false, error: "실패"))
    }
  }

  func testSignedOut_returnsToLogin() async {
    let store = TestStore(initialState: AppFeature.State.mainTab(MainTabFeature.State())) {
      AppFeature()
    }
    store.exhaustivity = .off
    await store.send(.mainTab(.delegate(.signedOut)))
    XCTAssertEqual(store.state, .login(LoginFeature.State()))
  }

  func testBrowseAsGuest_entersMainTabAsGuest() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }
    store.exhaustivity = .off
    await store.send(.login(.browseTapped))
    await store.receive(\.login.delegate)
    guard case let .mainTab(mainTab) = store.state else {
      return XCTFail("메인 탭으로 들어가야 한다")
    }
    XCTAssertTrue(mainTab.isGuest)
  }

  func testGuestLoginRequested_returnsToLogin() async {
    var guest = MainTabFeature.State()
    guest.isGuest = true
    let store = TestStore(initialState: AppFeature.State.mainTab(guest)) {
      AppFeature()
    }
    store.exhaustivity = .off
    await store.send(.mainTab(.delegate(.loginRequested)))
    XCTAssertEqual(store.state, .login(LoginFeature.State()))
  }
}
