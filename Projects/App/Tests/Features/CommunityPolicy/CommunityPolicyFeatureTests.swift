import ComposableArchitecture
@testable import WePLi
import XCTest

// UI-17b · DEC-027

@MainActor
final class CommunityPolicyFeatureTests: XCTestCase {
  func testSteps_followRestrictionLadder() {
    XCTAssertEqual(CommunityPolicyText.steps.map(\.countLabel), ["1회", "2회", "3회", "4회", "5회"])
    XCTAssertEqual(CommunityPolicyText.steps.map(\.title), ["경고", "3일 제한", "7일 제한", "30일 제한", "영구 제한"])
  }

  func testOnAppear_loadsStandingOnce() async {
    let store = TestStore(initialState: CommunityPolicyFeature.State()) { CommunityPolicyFeature() } withDependencies: {
      $0.communityPolicyClient.standing = { .mock }
    }
    await store.send(.onAppear)
    await store.receive(.standingLoaded(.mock)) { $0.standing = .mock }
    await store.send(.onAppear)
  }

  func testLoadFailure_showsPolicyWithoutStep() async {
    struct Failure: Error {}
    let store = TestStore(initialState: CommunityPolicyFeature.State()) { CommunityPolicyFeature() } withDependencies: {
      $0.communityPolicyClient.standing = { throw Failure() }
    }
    await store.send(.onAppear)
    await store.receive(.standingLoaded(.clean)) { $0.standing = .clean }
  }

  func testAppeal_opensOnlyWhileRestricted() async {
    let store = TestStore(initialState: CommunityPolicyFeature.State(standing: .clean)) { CommunityPolicyFeature() }
    await store.send(.appealTapped)

    let restricted = TestStore(initialState: CommunityPolicyFeature.State(standing: .mock)) { CommunityPolicyFeature() }
    await restricted.send(.appealTapped) {
      $0.appeal = AppealFeature.State(target: CommunityStanding.mock.appealTarget!)
    }
    await restricted.send(.appeal(.presented(.closeTapped)))
    await restricted.receive(.appeal(.presented(.delegate(.dismiss)))) { $0.appeal = nil }
  }
}

extension MainTabFeatureTests {
  func testAppInfoPolicyRow_pushesCommunityPolicy() async throws {
    var initial = MainTabFeature.State()
    initial.selectedTab = .my
    initial.myPath.append(.appInfo(AppInfoFeature.State()))
    let store = TestStore(initialState: initial) { MainTabFeature() }
    store.exhaustivity = .off
    let id = try XCTUnwrap(store.state.myPath.ids.last)
    await store.send(.myPath(.element(id: id, action: .appInfo(.documentTapped(AppDocument.policyID)))))
    await store.receive(.myPath(.element(id: id, action: .appInfo(.delegate(.showCommunityPolicy)))))
    guard case .communityPolicy? = store.state.myPath.last else { return XCTFail("운영정책이 열려야 한다") }
  }
}
