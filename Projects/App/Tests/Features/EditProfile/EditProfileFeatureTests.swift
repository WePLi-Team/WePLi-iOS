import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-012 · UI-3e

@MainActor
final class EditProfileFeatureTests: XCTestCase {
  func testNickname_isClampedToSixteenGraphemes() async {
    let store = TestStore(initialState: EditProfileFeature.State(profile: .mock)) {
      EditProfileFeature()
    }

    await store.send(.nicknameChanged("가나다라마바사아자차카타파하가나다")) {
      $0.nickname = "가나다라마바사아자차카타파하가나"
    }
    // 이모지 한 개도 한 글자로 센다
    await store.send(.nicknameChanged("👨‍👩‍👧‍👦음악")) {
      $0.nickname = "👨‍👩‍👧‍👦음악"
    }
    XCTAssertEqual(store.state.nickname.count, 3)
  }

  func testBio_isClampedToFifty() async {
    let store = TestStore(initialState: EditProfileFeature.State(profile: .mock)) {
      EditProfileFeature()
    }
    let long = String(repeating: "가", count: 60)

    await store.send(.bioChanged(long)) {
      $0.bio = String(repeating: "가", count: 50)
    }
  }

  func testDone_isDisabledForBlankNickname() {
    var state = EditProfileFeature.State(profile: .mock)
    XCTAssertTrue(state.canSave)
    state.nickname = "   "
    XCTAssertFalse(state.canSave)
    state.nickname = "김동"
    state.persona = nil
    XCTAssertFalse(state.canSave)
  }

  func testSave_trimsShowsToastAndDelegates() async {
    var expected = MyProfile.mock
    expected.nickname = "새 이름"
    expected.persona = .energyFlash
    let store = TestStore(initialState: EditProfileFeature.State(profile: .mock)) {
      EditProfileFeature()
    } withDependencies: {
      $0.editProfileClient.save = { $0 }
    }

    await store.send(.nicknameChanged("  새 이름 ")) { $0.nickname = "  새 이름 " }
    await store.send(.personaSelected(.energyFlash)) { $0.persona = .energyFlash }
    await store.send(.doneButtonTapped) { $0.isSaving = true }
    await store.receive(.saved(expected)) {
      $0.isSaving = false
      $0.nickname = "새 이름"
      $0.toast = "내 정보를 저장했어요"
    }
    await store.receive(.delegate(.profileUpdated(expected)))
  }

  func testSaveFailure_showsToastAndKeepsInput() async {
    let store = TestStore(initialState: EditProfileFeature.State(profile: .mock)) {
      EditProfileFeature()
    } withDependencies: {
      $0.editProfileClient.save = { _ in throw URLError(.timedOut) }
    }

    await store.send(.doneButtonTapped) { $0.isSaving = true }
    await store.receive(.saveFailed) {
      $0.isSaving = false
      $0.toast = "저장하지 못했어요. 잠시 후 다시 시도해 주세요"
    }
  }

  func testWithdrawAndPhoto_sendDelegates() async {
    let store = TestStore(initialState: EditProfileFeature.State(profile: .mock)) {
      EditProfileFeature()
    }

    await store.send(.withdrawTapped)
    await store.receive(.delegate(.showWithdraw))
    await store.send(.changePhotoTapped)
    await store.receive(.delegate(.pickPhoto))
  }
}
