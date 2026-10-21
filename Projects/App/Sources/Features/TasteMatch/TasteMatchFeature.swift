import ComposableArchitecture
import Foundation

// REQ-102 · UI-6d · DEC-023 — 취향 궁합(push). 친구 프로필(UI-13g)의 「나와 취향 N% 일치」에서 연다.
// 추천 보내기는 먼저 「보냄」으로 바꾸고 서버가 거절하면 되돌린다(DEC-004).

@Reducer
struct TasteMatchFeature {
  @ObservableState
  struct State: Equatable {
    let userID: String
    /// 상대 이름 — 프로필에서 받는다
    let name: String
    var match: TasteMatch?
    var loadFailed = false
    var toast: String?

    init(userID: String, name: String) {
      self.userID = userID
      self.name = name
    }
  }

  enum Action: Equatable {
    case onAppear
    case loaded(TasteMatch)
    case loadFailed
    case retryButtonTapped
    case backButtonTapped
    case recommendTapped(TasteMatchSong.ID)
    case recommendFailed(TasteMatchSong.ID)
    case artistTapped(String)
    case createPlaylistTapped
    case toastDismissed
    case delegate(TasteMatchDelegate)
  }

  @Dependency(\.tasteMatchClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.match == nil else { return .none }
        return self.load(&state)
      case let .loaded(match):
        state.match = match
        return .none
      case .loadFailed:
        state.loadFailed = true
        return .none
      case .retryButtonTapped:
        return self.load(&state)
      case .backButtonTapped:
        return .send(.delegate(.dismiss))
      case let .recommendTapped(id):
        return self.recommend(id, &state)
      case let .recommendFailed(id):
        state.match?.recommendations[id: id]?.isSent = false
        state.toast = TasteMatchText.sendFailed
        return .none
      case let .artistTapped(name):
        return .send(.delegate(.showArtist(name)))
      case .createPlaylistTapped:
        return .send(.delegate(.createRelay))
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
    let userID = state.userID
    return .run { send in
      do {
        try await send(.loaded(self.client.fetch(userID)))
      } catch {
        await send(.loadFailed)
      }
    }
  }

  private func recommend(_ id: TasteMatchSong.ID, _ state: inout State) -> Effect<Action> {
    // 곡당 1번 — 보낸 곡은 다시 보내지 않는다
    guard state.match?.recommendations[id: id]?.isSent == false else { return .none }
    state.match?.recommendations[id: id]?.isSent = true
    let userID = state.userID
    return .run { send in
      do {
        try await self.client.recommend(userID, id)
      } catch {
        await send(.recommendFailed(id))
      }
    }
  }
}

enum TasteMatchDelegate: Equatable {
  case dismiss
  case showArtist(String)
  /// 「둘이서 플레이리스트 만들기」 → 릴레이 만들기(UI-6a)
  case createRelay
}
