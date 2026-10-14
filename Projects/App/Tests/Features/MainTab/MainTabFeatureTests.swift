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

@MainActor
final class CommunityNavigationTests: XCTestCase {
  func testBell_pushesNotificationsAndBackPops() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .community
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    }
    store.exhaustivity = .off

    await store.send(.community(.notificationButtonTapped))
    await store.receive(.community(.delegate(.showNotifications)))
    XCTAssertEqual(store.state.communityPath.count, 1)
    XCTAssertTrue(store.state.hidesTabBar)

    guard let id = store.state.communityPath.ids.first else { return XCTFail("알림이 열리지 않음") }
    await store.send(.communityPath(.element(id: id, action: .notifications(.backButtonTapped))))
    await store.receive(.communityPath(.element(id: id, action: .notifications(.delegate(.dismiss)))))
    XCTAssertTrue(store.state.communityPath.isEmpty)
  }
}

@MainActor
final class MyNavigationTests: XCTestCase {
  func testProfileCard_pushesEditAndSavedProfileUpdatesMyTab() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .my
    initial.my.profile = .mock
    var updated = MyProfile.mock
    updated.nickname = "새 이름"
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    } withDependencies: {
      $0.editProfileClient.save = { $0 }
    }
    store.exhaustivity = .off

    await store.send(.my(.profileTapped))
    await store.receive(.my(.delegate(.editProfile)))
    guard let id = store.state.myPath.ids.first else { return XCTFail("내 정보 수정이 열리지 않음") }
    XCTAssertTrue(store.state.hidesTabBar)

    await store.send(.myPath(.element(id: id, action: .editProfile(.nicknameChanged("새 이름")))))
    await store.send(.myPath(.element(id: id, action: .editProfile(.doneButtonTapped))))
    await store.receive(.myPath(.element(id: id, action: .editProfile(.delegate(.profileUpdated(updated))))))
    XCTAssertEqual(store.state.my.profile?.nickname, "새 이름")

    await store.send(.myPath(.element(id: id, action: .editProfile(.backButtonTapped))))
    await store.receive(.myPath(.element(id: id, action: .editProfile(.delegate(.dismiss)))))
    XCTAssertTrue(store.state.myPath.isEmpty)
  }
}

@MainActor
final class ComposeNavigationTests: XCTestCase {
  func testCompose_opensAsSheetAndPublishingReloadsFeed() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .community
    initial.community.hasLoaded = true
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    } withDependencies: {
      $0.composeClient.publish = { _ in }
      $0.communityClient.fetchFeed = { .mock }
    }
    store.exhaustivity = .off

    await store.send(.community(.composeButtonTapped))
    await store.receive(.community(.delegate(.showCompose)))
    XCTAssertNotNil(store.state.compose)

    await store.send(.compose(.presented(.titleChanged("제목"))))
    await store.send(.compose(.presented(.bodyChanged("내용"))))
    await store.send(.compose(.presented(.publishButtonTapped)))
    await store.receive(.compose(.presented(.delegate(.published))))
    XCTAssertNil(store.state.compose)
    await store.receive(.community(.feedLoaded(.mock)))
    XCTAssertTrue(store.state.community.hasLoaded)
  }
}

@MainActor
final class PostDetailNavigationTests: XCTestCase {
  func testPost_pushesDetailAndSongReplyComesBackFromPicker() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .community
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    } withDependencies: {
      $0.postDetailClient.fetch = { .mock(postID: $0) }
    }
    store.exhaustivity = .off

    await store.send(.community(.postTapped("p3")))
    await store.receive(.community(.delegate(.showPost("p3"))))
    guard let id = store.state.communityPath.ids.first else { return XCTFail("게시글 상세가 열리지 않음") }
    await store.send(.communityPath(.element(id: id, action: .postDetail(.loaded(.mock(postID: "p3"))))))

    await store.send(.communityPath(.element(id: id, action: .postDetail(.songReplyButtonTapped))))
    await store.receive(.communityPath(.element(id: id, action: .postDetail(.delegate(.pickReplySong)))))
    XCTAssertNotNil(store.state.replySongPicker)

    let track = ComposeTrack(id: "c13", title: "밤양갱", artist: "비비(bibi)")
    await store.send(.replySongPicker(.presented(.delegate(.add([track])))))
    XCTAssertNil(store.state.replySongPicker)
    await store.receive(.communityPath(.element(
      id: id,
      action: .postDetail(.replySongPicked(Track(title: "밤양갱", artist: "비비(bibi)")))
    )))
    XCTAssertEqual(store.state.communityPath[id: id, case: \.postDetail]?.replySong?.title, "밤양갱")
  }
}
