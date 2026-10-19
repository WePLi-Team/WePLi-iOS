import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-102 · UI-6d · DEC-023

@MainActor
final class TasteMatchFeatureTests: XCTestCase {
  private struct Failure: Error {}

  func testHeadline() {
    XCTAssertEqual(TasteMatchText.headline(name: "chuuuuu__", score: 82), "chuuuuu__님과 꽤 잘 맞아요")
  }

  func testRecommend_oncePerSongAndRollsBack() async {
    var state = TasteMatchFeature.State(userID: "jisoo", name: "지수")
    state.match = .mock(userID: "jisoo")
    let calls = LockIsolated(0)
    let store = TestStore(initialState: state) { TasteMatchFeature() } withDependencies: {
      $0.tasteMatchClient.recommend = { _, _ in
        calls.withValue { $0 += 1 }
        if calls.value == 1 {
          throw Failure()
        }
      }
    }
    let id = "밤편지|아이유 (IU)"
    await store.send(.recommendTapped(id)) { $0.match?.recommendations[id: id]?.isSent = true }
    await store.receive(.recommendFailed(id)) {
      $0.match?.recommendations[id: id]?.isSent = false
      $0.toast = TasteMatchText.sendFailed
    }
    await store.send(.recommendTapped(id)) { $0.match?.recommendations[id: id]?.isSent = true }
    // 보낸 곡은 다시 보내지 않는다
    await store.send(.recommendTapped(id))
    XCTAssertEqual(calls.value, 2)
  }

  func testCreatePlaylist_opensCreateRelay() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .community
    var profile = FriendProfileFeature.State(userID: "jisoo")
    profile.profile = .mock(id: "jisoo")
    initial.communityPath.append(.friendProfile(profile))
    let store = TestStore(initialState: initial) { MainTabFeature() }
    store.exhaustivity = .off
    let profileID = initial.communityPath.ids[0]
    await store.send(.communityPath(.element(id: profileID, action: .friendProfile(.tasteMatchTapped))))
    await store.receive(.communityPath(.element(
      id: profileID,
      action: .friendProfile(.delegate(.showTasteMatch(userID: "jisoo")))
    )))
    guard case let .tasteMatch(match)? = store.state.communityPath.last else {
      return XCTFail("취향 궁합이 열리지 않았어요")
    }
    XCTAssertEqual(match.name, "지수")
    let matchID = store.state.communityPath.ids[1]
    await store.send(.communityPath(.element(id: matchID, action: .tasteMatch(.createPlaylistTapped))))
    await store.receive(.communityPath(.element(id: matchID, action: .tasteMatch(.delegate(.createRelay)))))
    XCTAssertNotNil(store.state.createRelay)
  }
}
