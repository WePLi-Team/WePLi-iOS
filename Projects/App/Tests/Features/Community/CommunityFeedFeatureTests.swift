import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-060 · UI-1d · DEC-004

@MainActor
final class CommunityFeedFeatureTests: XCTestCase {
  private func loadedState() -> CommunityFeedFeature.State {
    var state = CommunityFeedFeature.State()
    state.stories = CommunityFeed.mock.stories
    state.posts = IdentifiedArray(uniqueElements: CommunityFeed.mock.posts)
    state.hasLoaded = true
    return state
  }

  func testOnAppear_loadsFeedOnce() async {
    let store = TestStore(initialState: CommunityFeedFeature.State()) {
      CommunityFeedFeature()
    } withDependencies: {
      $0.communityClient.fetchFeed = { .mock }
    }

    await store.send(.onAppear) {
      $0.isLoading = true
    }
    await store.receive(.feedLoaded(.mock)) {
      $0.isLoading = false
      $0.hasLoaded = true
      $0.stories = CommunityFeed.mock.stories
      $0.posts = IdentifiedArray(uniqueElements: CommunityFeed.mock.posts)
    }
    await store.send(.onAppear)
  }

  func testLike_isOptimisticAndCountsPlusOne() async {
    let store = TestStore(initialState: self.loadedState()) {
      CommunityFeedFeature()
    } withDependencies: {
      $0.communityClient.setLiked = { _, _ in }
    }

    await store.send(.likeTapped("p1")) {
      $0.posts[id: "p1"]?.isLiked = true
      $0.posts[id: "p1"]?.likeCount = 10124
    }
    // 원본: 처음부터 좋아요한 글(p4)은 끄면 -1
    await store.send(.likeTapped("p4")) {
      $0.posts[id: "p4"]?.isLiked = false
      $0.posts[id: "p4"]?.likeCount = 11900
    }
  }

  func testLikeFailure_restoresPreviousValue() async {
    let store = TestStore(initialState: self.loadedState()) {
      CommunityFeedFeature()
    } withDependencies: {
      $0.communityClient.setLiked = { _, _ in throw URLError(.notConnectedToInternet) }
    }

    await store.send(.likeTapped("p2")) {
      $0.posts[id: "p2"]?.isLiked = true
      $0.posts[id: "p2"]?.likeCount = 11902
    }
    await store.receive(.likeFailed("p2", restore: false)) {
      $0.posts[id: "p2"]?.isLiked = false
      $0.posts[id: "p2"]?.likeCount = 11901
    }
  }

  func testSave_togglesAndRestoresOnFailure() async {
    let shouldFail = LockIsolated(false)
    let store = TestStore(initialState: self.loadedState()) {
      CommunityFeedFeature()
    } withDependencies: {
      $0.communityClient.setSaved = { _, _ in
        if shouldFail.value {
          throw URLError(.timedOut)
        }
      }
    }

    await store.send(.saveTapped("p3")) {
      $0.posts[id: "p3"]?.isSaved = true
    }
    shouldFail.setValue(true)
    await store.send(.saveTapped("p3")) {
      $0.posts[id: "p3"]?.isSaved = false
    }
    await store.receive(.saveFailed("p3", restore: true)) {
      $0.posts[id: "p3"]?.isSaved = true
    }
  }

  func testTaps_sendDelegates() async {
    let store = TestStore(initialState: self.loadedState()) {
      CommunityFeedFeature()
    }

    await store.send(.composeButtonTapped)
    await store.receive(.delegate(.showCompose))
    await store.send(.notificationButtonTapped)
    await store.receive(.delegate(.showNotifications))
    await store.send(.postTapped("p1"))
    await store.receive(.delegate(.showPost("p1")))
    await store.send(.authorTapped("dlwlrma"))
    await store.receive(.delegate(.showProfile("dlwlrma")))
  }

  func testCountFormatter_usesThousandsSeparator() {
    XCTAssertEqual(CountFormatter.string(10123), "10,123")
    XCTAssertEqual(CountFormatter.string(923), "923")
  }
}
