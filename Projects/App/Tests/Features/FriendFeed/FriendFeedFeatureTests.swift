import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-079 · UI-13b

@MainActor
final class FriendFeedFeatureTests: XCTestCase {
  private func loaded() -> FriendFeedFeature.State {
    var state = FriendFeedFeature.State()
    state.feed = .mock
    return state
  }

  func testMetaAndToggle() {
    var row = FriendFeed.mock.feed[0]
    XCTAssertEqual(row.meta, "민수님이 지금 듣는 중 · 방금")
    XCTAssertEqual(FriendFeed.mock.feed[2].meta, "수빈님이 최근 들은 곡 · 1시간 전")
    row.toggle(.fire)
    XCTAssertEqual(row.reactions[.fire], 4)
    row.toggle(.clap)
    XCTAssertEqual(row.reactions[.fire], 3)
    XCTAssertEqual(row.reactions[.clap], 1)
    XCTAssertEqual(row.myReaction, .clap)
    row.toggle(.clap)
    XCTAssertEqual(row.reactions[.clap], 0)
    XCTAssertNil(row.myReaction)
  }

  func testReaction_rollsBackOnFailure() async {
    struct Failure: Error {}
    let store = TestStore(initialState: self.loaded()) { FriendFeedFeature() } withDependencies: {
      $0.friendFeedClient.react = { _, _ in throw Failure() }
    }
    let previous = FriendFeed.mock.feed[1]
    await store.send(.reactionTapped("jongmin", .clap)) {
      $0.feed?.feed[1].myReaction = .clap
      $0.feed?.feed[1].reactions[.clap] = 3
    }
    await store.receive(.reactionFailed("jongmin", restore: previous)) { $0.feed?.feed[1] = previous }
  }

  func testSameSongAndPlay_showToasts() async {
    let store = TestStore(initialState: self.loaded()) { FriendFeedFeature() } withDependencies: {
      $0.friendFeedClient.sendHeadphones = { _ in }
      $0.friendFeedClient.openInMusicApp = { _, _ in }
    }
    await store.send(.sameSongTapped)
    await store.receive(.headphonesSent("지수")) { $0.toast = "지수님에게 🎧 반응을 보냈어요" }
    await store.send(.playTapped("minsu")) { $0.toast = "Apple Music에서 ‘Supernova’을(를) 열어요" }
  }

  func testMe_opensListeningShare_friendOpensProfile() async {
    let store = TestStore(initialState: self.loaded()) { FriendFeedFeature() }
    // 친구 → 친구 프로필(UI-13g)
    await store.send(.railTapped("jisoo"))
    await store.receive(.delegate(.showProfile("jisoo")))
    await store.send(.railTapped("me"))
    await store.receive(.delegate(.showListeningShare))
  }
}

extension MainTabFeatureTests {
  func testCommunityFriendsTab_meOpensListeningShare() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .community
    initial.community.friends.feed = .mock
    let store = TestStore(initialState: initial) { MainTabFeature() }
    store.exhaustivity = .off
    await store.send(.community(.segmentSelected(.friends))) { $0.community.segment = .friends }
    await store.send(.community(.friends(.railTapped("me"))))
    await store.receive(.community(.friends(.delegate(.showListeningShare))))
    XCTAssertNotNil(store.state.listeningShare)
  }
}
