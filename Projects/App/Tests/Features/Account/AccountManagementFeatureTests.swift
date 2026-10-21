import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-013 · UI-7c · UI-17e · DEC-004

@MainActor
final class AccountManagementFeatureTests: XCTestCase {
  private let deletesAt = PendingDeletion.preview.deletesAt

  func testTexts() {
    XCTAssertEqual(AccountText.day(PendingDeletion.preview.requestedAt), "10월 21일")
    XCTAssertEqual(AccountText.day(self.deletesAt), "11월 4일")
    let rules = AccountText.rules(.google)
    XCTAssertEqual(rules.count, 5)
    XCTAssertTrue(rules[0].hasPrefix("탈퇴를 신청하고 14일 안에"))
    XCTAssertEqual(rules.last, "Google 로그인 연결도 함께 해제돼요.")
  }

  func testWithdraw_reasonThenAgreeThenDoneAndSignOut() async {
    let sentReasons = LockIsolated<Set<WithdrawReason>>([])
    let signedOut = LockIsolated(false)
    let store = TestStore(initialState: AccountManagementFeature.State()) {
      AccountManagementFeature()
    } withDependencies: {
      $0.accountClient.withdraw = { reasons in
        sentReasons.setValue(reasons)
        return self.deletesAt
      }
      $0.accountClient.signOut = { signedOut.setValue(true) }
    }
    await store.send(.withdrawTapped) { $0.step = .reason }
    // 사유를 고르지 않으면 다음으로 가지 않는다
    await store.send(.nextTapped)
    await store.send(.reasonToggled(.noSongs)) { $0.reasons = [.noSongs] }
    await store.send(.nextTapped) { $0.step = .confirm }
    // 동의하지 않으면 탈퇴하지 않는다
    await store.send(.confirmTapped)
    await store.send(.agreeToggled) { $0.hasAgreed = true }
    await store.send(.confirmTapped) { $0.isWithdrawing = true }
    await store.receive(.withdrawn(self.deletesAt)) {
      $0.isWithdrawing = false
      $0.deletesAt = self.deletesAt
      $0.step = .done
    }
    XCTAssertEqual(sentReasons.value, [.noSongs])
    await store.send(.doneTapped)
    await store.receive(.delegate(.signedOut))
    XCTAssertTrue(signedOut.value)
  }

  func testKeepUsing_resetsToManage() async {
    var initial = AccountManagementFeature.State()
    initial.step = .confirm
    initial.reasons = [.privacy]
    initial.hasAgreed = true
    let store = TestStore(initialState: initial) { AccountManagementFeature() }
    await store.send(.keepUsingTapped) {
      $0.step = .manage
      $0.reasons = []
      $0.hasAgreed = false
    }
  }

  func testBack_fromEditProfileEntryDismissesAtReason() async {
    let store = TestStore(initialState: AccountManagementFeature.State(entry: .reason)) { AccountManagementFeature() }
    await store.send(.reasonToggled(.rarelyUsed)) { $0.reasons = [.rarelyUsed] }
    await store.send(.nextTapped) { $0.step = .confirm }
    await store.send(.backButtonTapped) { $0.step = .reason }
    await store.send(.backButtonTapped)
    await store.receive(.delegate(.dismiss))
  }

  func testUnblock_removesRowAndRestoresOnFailure() async {
    var initial = AccountManagementFeature.State()
    let users = [BlockedUser(id: "woogi", name: "woogi"), BlockedUser(id: "dbeoddl__", name: "dbeoddl__")]
    initial.blocked = users
    let store = TestStore(initialState: initial) { AccountManagementFeature() } withDependencies: {
      $0.friendProfileClient.setBlocked = { _, _ in throw CancellationError() }
    }
    await store.send(.unblockTapped("woogi")) { $0.blocked = [users[1]] }
    await store.receive(.unblockFailed(users[0], 0)) {
      $0.blocked = users
      $0.toast = "차단을 풀지 못했어요. 다시 시도해 주세요"
    }
  }
}

@MainActor
final class AccountGraceFeatureTests: XCTestCase {
  func testRestore_thenHomeFinishesLogin() async {
    let store = TestStore(initialState: AccountGraceFeature.State(mode: .pending(.preview))) {
      AccountGraceFeature()
    } withDependencies: {
      $0.accountClient.restore = {}
    }
    await store.send(.restoreTapped) { $0.isRestoring = true }
    await store.receive(.restored) {
      $0.isRestoring = false
      $0.isRestored = true
    }
    await store.send(.homeTapped)
    await store.receive(.delegate(.restored))
  }

  func testLeave_signsOut() async {
    let signedOut = LockIsolated(false)
    let store = TestStore(initialState: AccountGraceFeature.State(mode: .pending(.preview))) {
      AccountGraceFeature()
    } withDependencies: {
      $0.accountClient.signOut = { signedOut.setValue(true) }
    }
    await store.send(.leaveTapped)
    await store.receive(.delegate(.signedOut))
    XCTAssertTrue(signedOut.value)
  }

  func testLogin_pendingAccountShowsGraceThenRestoreLogsIn() async {
    let store = TestStore(initialState: LoginFeature.State()) { LoginFeature() } withDependencies: {
      $0.authClient.signInWithApple = {}
      $0.accountClient.status = { .pendingDeletion(.preview) }
    }
    store.exhaustivity = .off
    await store.send(.appleLoginButtonTapped)
    await store.receive(\.accountChecked)
    XCTAssertEqual(store.state.accountGrace?.mode, .pending(.preview))
    XCTAssertFalse(store.state.isLoading)

    await store.send(.accountGrace(.presented(.delegate(.restored))))
    XCTAssertNil(store.state.accountGrace)
    await store.receive(\.loginResponse)
  }

  func testLogin_blockedAccountShowsRejoinBlock() async {
    let store = TestStore(initialState: LoginFeature.State()) { LoginFeature() } withDependencies: {
      $0.authClient.signInWithGoogle = {}
      $0.accountClient.status = { .rejoinBlocked(.preview) }
    }
    store.exhaustivity = .off
    await store.send(.googleLoginButtonTapped)
    await store.receive(\.accountChecked)
    XCTAssertEqual(store.state.accountGrace?.mode, .blocked(.preview))
  }
}

/// UI-7c 진입 — 마이 「계정 관리」 · 내 정보 수정 「회원 탈퇴」, 탈퇴 뒤 로그아웃은 앱 루트로
@MainActor
final class AccountNavigationTests: XCTestCase {
  func testMyMenuAndEditProfile_openAccountManagement() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .my
    initial.my.profile = .mock
    let store = TestStore(initialState: initial) { MainTabFeature() }
    store.exhaustivity = .off

    await store.send(.my(.menuTapped(.accountManagement)))
    await store.receive(.my(.delegate(.show(.accountManagement))))
    XCTAssertEqual(store.state.myPath.last?.accountManagement?.step, .manage)

    await store.send(.my(.profileTapped))
    await store.receive(.my(.delegate(.editProfile)))
    guard let editID = store.state.myPath.ids.last else { return XCTFail("내 정보 수정이 열리지 않음") }
    await store.send(.myPath(.element(id: editID, action: .editProfile(.withdrawTapped))))
    await store.receive(.myPath(.element(id: editID, action: .editProfile(.delegate(.showWithdraw)))))
    XCTAssertEqual(store.state.myPath.last?.accountManagement?.step, .reason)

    guard let accountID = store.state.myPath.ids.last else { return XCTFail("계정 관리가 열리지 않음") }
    await store.send(.myPath(.element(id: accountID, action: .accountManagement(.delegate(.signedOut)))))
    await store.receive(.delegate(.signedOut))
  }
}
