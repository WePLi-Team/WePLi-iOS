import ComposableArchitecture
@testable import WePLi
import XCTest

// UI-17c · UI-7e · DEC-024

@MainActor
final class HiddenPostFeatureTests: XCTestCase {
  func testSteps_showHiddenTimeInSeoul() {
    XCTAssertEqual(HiddenPost.mock.steps.map(\.title), ["신고 5건 · 임시로 가려짐", "운영팀 검토 중", "결과 안내"])
    XCTAssertEqual(HiddenPost.mock.steps[0].detail, "10월 19일 오후 2:02")
    XCTAssertEqual(HiddenPostText.day(HiddenPost.mock.postedAt), "10월 19일")
  }

  func testAppeal_opensWithPostTarget() async {
    let store = TestStore(initialState: HiddenPostFeature.State(post: .mock)) { HiddenPostFeature() }
    await store.send(.appealTapped) {
      $0.appeal = AppealFeature.State(target: AppealTarget(
        id: "hidden-1",
        kind: .post,
        title: "비 오는 날 듣는 플리",
        reason: "욕설 · 비하 표현 신고 누적"
      ))
    }
    await store.send(.appeal(.presented(.closeTapped)))
    await store.receive(.appeal(.presented(.delegate(.dismiss)))) { $0.appeal = nil }
  }

  func testDelete_confirmsThenDeletes() async {
    let store = TestStore(initialState: HiddenPostFeature.State(post: .mock)) { HiddenPostFeature()
    } withDependencies: {
      $0.hiddenPostClient.delete = { _ in }
    }
    store.exhaustivity = .off(showSkippedAssertions: false)
    await store.send(.deleteTapped)
    XCTAssertNotNil(store.state.deleteDialog)
    await store.send(.deleteDialog(.presented(.confirm))) {
      $0.deleteDialog = nil
      $0.isDeleting = true
    }
    await store.receive(.deleted) { $0.isDeleting = false }
    await store.receive(.delegate(.deleted("hidden-1")))
  }

  func testDeleteFailure_showsToast() async {
    struct Failure: Error {}
    var initial = HiddenPostFeature.State(post: .mock)
    initial.deleteDialog = ConfirmationDialogState { TextState("") }
    let store = TestStore(initialState: initial) { HiddenPostFeature() } withDependencies: {
      $0.hiddenPostClient.delete = { _ in throw Failure() }
    }
    await store.send(.deleteDialog(.presented(.confirm))) {
      $0.deleteDialog = nil
      $0.isDeleting = true
    }
    await store.receive(.deleteFailed) {
      $0.isDeleting = false
      $0.toast = "글을 삭제하지 못했어요"
    }
  }

  func testNotice_opensAppealAndPolicy() async {
    var initial = CommunityFeedFeature.State()
    initial.hiddenMine = .mock
    let store = TestStore(initialState: initial) { CommunityFeedFeature() }
    await store.send(.hiddenNoticeTapped)
    await store.receive(.delegate(.showHiddenPost(.mock)))
    await store.send(.hiddenPolicyTapped)
    await store.receive(.delegate(.showPolicy))
    await store.send(.hiddenAppealTapped) {
      $0.appeal = AppealFeature.State(target: HiddenPost.mock.appealTarget)
    }
  }
}

extension MainTabFeatureTests {
  func testHiddenPost_opensFromCommunity_policyPushes_deleteRemovesNotice() async throws {
    var initial = MainTabFeature.State()
    initial.selectedTab = .community
    initial.community.hiddenMine = .mock
    let store = TestStore(initialState: initial) { MainTabFeature() } withDependencies: {
      $0.hiddenPostClient.delete = { _ in }
    }
    store.exhaustivity = .off
    await store.send(.community(.hiddenNoticeTapped))
    await store.receive(.community(.delegate(.showHiddenPost(.mock))))
    guard case .hiddenPost? = store.state.communityPath.last else { return XCTFail("내 가려진 글이 열려야 한다") }
    let id = try XCTUnwrap(store.state.communityPath.ids.last)

    await store.send(.communityPath(.element(id: id, action: .hiddenPost(.policyTapped))))
    await store.receive(.communityPath(.element(id: id, action: .hiddenPost(.delegate(.showPolicy)))))
    guard case .communityPolicy? = store.state.communityPath.last else { return XCTFail("운영정책이 열려야 한다") }

    await store.send(.communityPath(.element(id: id, action: .hiddenPost(.delegate(.deleted("hidden-1"))))))
    XCTAssertTrue(store.state.communityPath.isEmpty)
    XCTAssertNil(store.state.community.hiddenMine)
  }
}
