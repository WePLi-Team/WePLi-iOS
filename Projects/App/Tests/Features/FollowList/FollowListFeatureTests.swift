import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-074 · UI-10c · DEC-004

@MainActor
final class FollowListFeatureTests: XCTestCase {
  private func loaded(tab: FollowListFeature.Tab = .followers) -> FollowListFeature.State {
    var state = FollowListFeature.State(userName: "김동", tab: tab)
    state.lists = .mock
    return state
  }

  func testTabs_showFollowersAndFollowing() {
    XCTAssertEqual(self.loaded().visibleUsers.map(\.name), ["chuuuuu__", "roykim", "minnie._.", "woogi"])
    XCTAssertEqual(self.loaded(tab: .following).visibleUsers.map(\.name), ["chuuuuu__", "minnie._.", "younha_holic"])
  }

  func testSearch_isCaseInsensitivePartialMatch() {
    var state = self.loaded()
    state.query = "ROY"
    XCTAssertEqual(state.visibleUsers.map(\.name), ["roykim"])
  }

  func testFollow_isOptimisticAndUpdatesBothListsAndCount() async {
    let store = TestStore(initialState: self.loaded()) {
      FollowListFeature()
    } withDependencies: {
      $0.followListClient.setFollowing = { _, _ in }
    }

    // 팔로잉 목록에도 있는 사람(chuuuuu__)을 끊으면 두 목록 모두 바뀐다
    await store.send(.followButtonTapped("chuuuuu__")) {
      $0.lists?.followers[0].isFollowing = false
      $0.lists?.following[0].isFollowing = false
      $0.lists?.followingCount = 311
    }
  }

  func testFollowFailure_restores() async {
    let store = TestStore(initialState: self.loaded()) {
      FollowListFeature()
    } withDependencies: {
      $0.followListClient.setFollowing = { _, _ in throw URLError(.timedOut) }
    }

    await store.send(.followButtonTapped("roykim")) {
      $0.lists?.followers[1].isFollowing = true
      $0.lists?.followingCount = 313
    }
    await store.receive(.followFailed("roykim", restore: false)) {
      $0.lists?.followers[1].isFollowing = false
      $0.lists?.followingCount = 312
    }
  }

  func testUserTap_showsProfile() async {
    let store = TestStore(initialState: self.loaded()) {
      FollowListFeature()
    }
    await store.send(.userTapped("woogi"))
    await store.receive(.delegate(.showProfile("woogi")))
  }
}
