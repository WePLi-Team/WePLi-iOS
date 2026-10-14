import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-001

@MainActor
final class MainTabFeatureTests: XCTestCase {
  func testInitialTab_isHome() {
    XCTAssertEqual(MainTabFeature.State().selectedTab, .home)
  }

  func testTabSelected_changesSelectedTab() async {
    let store = TestStore(initialState: MainTabFeature.State()) {
      MainTabFeature()
    }

    await store.send(.tabSelected(.relay)) {
      $0.selectedTab = .relay
    }
    await store.send(.tabSelected(.search)) {
      $0.selectedTab = .search
    }
  }

  func testTabs_matchDesignOrder() {
    XCTAssertEqual(MainTabFeature.Tab.allCases, [.home, .relay, .community, .my, .search])
    XCTAssertEqual(MainTabFeature.Tab.capsuleTabs, [.home, .relay, .community, .my])
    XCTAssertEqual(MainTabFeature.Tab.allCases.map(\.title), ["홈", "릴레이", "커뮤니티", "마이", "검색"])
  }
}

// DEC-007 · REQ-030 · REQ-031 · REQ-033 — 릴레이 탭 → 상세 → 투표 → 돌아가기

@MainActor
final class RelayNavigationTests: XCTestCase {
  func testRelayFlow_listToDetailToVoteAndBack() async throws {
    let now = Date(timeIntervalSince1970: 1800000000)
    let detail = RelayDetail.mock(id: "first-love", now: now)
    var initial = MainTabFeature.State()
    initial.selectedTab = .relay
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    } withDependencies: {
      $0.relayDetailClient.fetch = { _ in detail }
    }
    store.exhaustivity = .off

    await store.send(.relay(.relayTapped("first-love")))
    await store.receive(.relay(.delegate(.showRelay("first-love"))))
    XCTAssertEqual(store.state.relayPath.count, 1)
    XCTAssertTrue(store.state.hidesTabBar)

    guard let detailID = store.state.relayPath.ids.first else { return XCTFail("상세가 열리지 않음") }
    await store.send(.relayPath(.element(id: detailID, action: .detail(.detailLoaded(detail)))))
    await store.send(.relayPath(.element(id: detailID, action: .detail(.voteButtonTapped))))
    await store.receive(.relayPath(.element(
      id: detailID,
      action: .detail(.delegate(.showVote(relayID: "first-love")))
    )))
    XCTAssertEqual(store.state.relayPath.count, 2)
    let vote = try store.state.relayPath[id: XCTUnwrap(store.state.relayPath.ids.last), case: \.vote]
    XCTAssertEqual(vote?.topic, "첫 사랑이 생각나는 노래 모음")

    guard let voteID = store.state.relayPath.ids.last else { return XCTFail("투표가 열리지 않음") }
    await store.send(.relayPath(.element(id: voteID, action: .vote(.returnToRelayButtonTapped))))
    await store.receive(.relayPath(.element(id: voteID, action: .vote(.delegate(.dismiss)))))
    XCTAssertEqual(store.state.relayPath.count, 1)

    await store.send(.relayPath(.element(id: detailID, action: .detail(.backButtonTapped))))
    await store.receive(.relayPath(.element(id: detailID, action: .detail(.delegate(.dismiss)))))
    XCTAssertTrue(store.state.relayPath.isEmpty)
    XCTAssertFalse(store.state.hidesTabBar)
  }
}
