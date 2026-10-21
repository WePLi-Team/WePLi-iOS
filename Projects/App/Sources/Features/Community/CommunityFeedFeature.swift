import ComposableArchitecture
import Foundation

// REQ-060 · UI-1d · DEC-004 — 커뮤니티 피드

@Reducer
struct CommunityFeedFeature {
  @ObservableState
  struct State: Equatable {
    var stories: [Story] = []
    var posts: IdentifiedArrayOf<Post> = []
    var isLoading = false
    var loadFailed = false
    var hasLoaded = false
    /// 게시글 / 친구(UI-13b)
    var segment: CommunitySegment = .posts
    var friends = FriendFeedFeature.State()
  }

  enum Action: Equatable {
    case onAppear
    case retryButtonTapped
    case feedLoaded(CommunityFeed)
    case feedFailed
    case likeTapped(Post.ID)
    case saveTapped(Post.ID)
    /// 서버 반영 실패 — 화면에 먼저 바꾼 값을 요청 전 값으로 되돌린다
    case likeFailed(Post.ID, restore: Bool)
    case saveFailed(Post.ID, restore: Bool)
    case composeButtonTapped
    case notificationButtonTapped
    case postTapped(Post.ID)
    case authorTapped(String)
    case storyTapped(Story.ID)
    case segmentSelected(CommunitySegment)
    case friends(FriendFeedFeature.Action)
    case delegate(Delegate)
  }

  enum Delegate: Equatable {
    /// 게시글 작성 (UI-2b)
    case showCompose
    /// 알림 (UI-4d)
    case showNotifications
    /// 게시글 상세 · 댓글 (UI-2c · 9c · 9d)
    case showPost(Post.ID)
    /// 친구 프로필(UI-13g — 5a를 대신함, DEC-010)
    case showProfile(String)
    case showStory(Story.ID)
  }

  @Dependency(\.communityClient)
  var communityClient

  var body: some ReducerOf<Self> {
    Scope(state: \.friends, action: \.friends) {
      FriendFeedFeature()
    }
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard !state.hasLoaded, !state.isLoading else { return .none }
        return self.load(&state)

      case .retryButtonTapped:
        return self.load(&state)

      case let .feedLoaded(feed):
        state.isLoading = false
        state.hasLoaded = true
        state.stories = feed.stories
        state.posts = IdentifiedArray(uniqueElements: feed.posts)
        return .none

      case .feedFailed:
        state.isLoading = false
        state.loadFailed = true
        return .none

      case let .likeTapped(id):
        guard let previous = state.posts[id: id]?.isLiked else { return .none }
        self.setLiked(!previous, on: id, in: &state)
        return .run { send in
          do {
            try await self.communityClient.setLiked(id, !previous)
          } catch {
            await send(.likeFailed(id, restore: previous))
          }
        }

      case let .likeFailed(id, restore):
        self.setLiked(restore, on: id, in: &state)
        return .none

      case let .saveTapped(id):
        guard let previous = state.posts[id: id]?.isSaved else { return .none }
        state.posts[id: id]?.isSaved = !previous
        return .run { send in
          do {
            try await self.communityClient.setSaved(id, !previous)
          } catch {
            await send(.saveFailed(id, restore: previous))
          }
        }

      case let .saveFailed(id, restore):
        state.posts[id: id]?.isSaved = restore
        return .none

      case .composeButtonTapped:
        return .send(.delegate(.showCompose))

      case .notificationButtonTapped:
        return .send(.delegate(.showNotifications))

      case let .postTapped(id):
        return .send(.delegate(.showPost(id)))

      case let .authorTapped(user):
        return .send(.delegate(.showProfile(user)))

      case let .storyTapped(id):
        return .send(.delegate(.showStory(id)))

      case let .segmentSelected(segment):
        state.segment = segment
        return .none

      case .friends, .delegate:
        return .none
      }
    }
  }

  /// 좋아요 상태를 바꾸고 수를 ±1 한다(같은 값이면 그대로).
  private func setLiked(_ isLiked: Bool, on id: Post.ID, in state: inout State) {
    guard var post = state.posts[id: id], post.isLiked != isLiked else { return }
    post.isLiked = isLiked
    post.likeCount += isLiked ? 1 : -1
    state.posts[id: id] = post
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.isLoading = true
    state.loadFailed = false
    return .run { send in
      do {
        try await send(.feedLoaded(self.communityClient.fetchFeed()))
      } catch {
        await send(.feedFailed)
      }
    }
  }
}

/// 커뮤니티 위 밑줄 탭 — 게시글(UI-1d) · 친구(UI-13b)
enum CommunitySegment: CaseIterable, Equatable, Hashable, Sendable {
  case posts
  case friends

  var title: String {
    switch self {
    case .posts: "게시글"
    case .friends: "친구"
    }
  }
}
