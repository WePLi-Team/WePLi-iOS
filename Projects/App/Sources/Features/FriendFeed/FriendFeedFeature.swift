import ComposableArchitecture
import Foundation

// REQ-079 · UI-13b · DEC-004 — 커뮤니티 › 친구. 반응은 먼저 반영하고 실패하면 되돌린다.

@Reducer
struct FriendFeedFeature {
  @ObservableState
  struct State: Equatable {
    var feed: FriendFeed?
    var loadFailed = false
    var toast: String?
  }

  enum Action: Equatable {
    case onAppear
    case loaded(FriendFeed)
    case loadFailed
    case retryButtonTapped
    case railTapped(FriendListening.ID)
    case sameSongTapped
    case headphonesSent(String)
    case reactionTapped(FriendListening.ID, FriendReaction)
    case reactionFailed(FriendListening.ID, restore: FriendListening)
    case playTapped(FriendListening.ID)
    case weeklyTapped(FriendWeeklySong.ID)
    case requestFailed
    case toastDismissed
    case delegate(FriendFeedDelegate)
  }

  @Dependency(\.friendFeedClient)
  var client

  @Dependency(\.nowPlayingWidgetClient)
  var widget

  @Dependency(\.date.now)
  var now

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.feed == nil else { return .none }
        return self.load(&state)
      case let .loaded(feed):
        state.feed = feed
        // 잠금화면 위젯(UI-13e)도 새로 그린다
        let snapshot = NowPlayingWidgetSnapshot(feed, now: self.now)
        return .run { _ in await self.widget.update(snapshot) }
      case .loadFailed:
        state.loadFailed = true
        return .none
      case .retryButtonTapped:
        return self.load(&state)
      case let .railTapped(id):
        // 「나」 → 연결과 공개 범위(UI-13a), 친구 → 친구 프로필(UI-13g)
        guard let row = state.feed?.rail.first(where: { $0.id == id }) else { return .none }
        return .send(.delegate(row.isMe ? .showListeningShare : .showProfile(id)))
      case .sameSongTapped, .headphonesSent, .playTapped, .requestFailed:
        return self.listen(&state, action)
      case let .reactionTapped(id, reaction):
        guard let index = state.feed?.feed.firstIndex(where: { $0.id == id }), var row = state.feed?.feed[index] else {
          return .none
        }
        let previous = row
        row.toggle(reaction)
        state.feed?.feed[index] = row
        let mine = row.myReaction
        return .run { send in
          do {
            try await self.client.react(id, mine)
          } catch {
            await send(.reactionFailed(id, restore: previous))
          }
        }
      case let .reactionFailed(id, previous):
        guard let index = state.feed?.feed.firstIndex(where: { $0.id == id }) else { return .none }
        state.feed?.feed[index] = previous
        return .none
      case let .weeklyTapped(id):
        return .send(.delegate(.showSong(id)))
      case .toastDismissed:
        state.toast = nil
        return .none
      case .delegate:
        return .none
      }
    }
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.loadFailed = false
    return .run { send in
      do {
        try await send(.loaded(self.client.fetch()))
      } catch {
        await send(.loadFailed)
      }
    }
  }

  // MARK: 같은 곡 · 음악 앱에서 열기

  private func listen(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case .sameSongTapped:
      guard let friend = state.feed?.sameSong else { return .none }
      return .run { send in
        do {
          try await self.client.sendHeadphones(friend.id)
          await send(.headphonesSent(friend.name))
        } catch {
          await send(.requestFailed)
        }
      }
    case let .headphonesSent(name):
      state.toast = "\(name)님에게 🎧 반응을 보냈어요"
    case let .playTapped(id):
      guard let row = state.feed?.feed.first(where: { $0.id == id }) else { return .none }
      // 미결정 — 원본은 늘 Apple Music으로 적는다. 연결된 앱이 정해지면 그 이름으로
      state.toast = "Apple Music에서 ‘\(row.title)’을(를) 열어요"
      return .run { _ in await self.client.openInMusicApp(row.title, row.artist) }
    case .requestFailed:
      // 원본에 없는 문구 — 디자인 확인 필요
      state.toast = "잠시 후 다시 시도해 주세요"
    default:
      break
    }
    return .none
  }
}

enum FriendFeedDelegate: Equatable {
  /// 「나」 → 연결과 공개 범위(UI-13a)
  case showListeningShare
  case showSong(String)
  /// 친구 프로필(UI-13g)
  case showProfile(String)
}
