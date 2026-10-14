import ComposableArchitecture
import Foundation

// REQ-074 · UI-10c · DEC-004 — 팔로워 · 팔로잉

@Reducer
struct FollowListFeature {
  enum Tab: Equatable, Sendable {
    case followers
    case following
  }

  @ObservableState
  struct State: Equatable {
    let userName: String
    var tab: Tab
    var lists: FollowLists?
    var query = ""
    var loadFailed = false

    init(userName: String, tab: Tab = .followers) {
      self.userName = userName
      self.tab = tab
    }

    /// 이름 부분 일치(대소문자 무시)로 거른 현재 탭 목록
    var visibleUsers: [FollowUser] {
      let users = self.tab == .followers ? self.lists?.followers ?? [] : self.lists?.following ?? []
      let needle = self.query.trimmingCharacters(in: .whitespaces).lowercased()
      guard !needle.isEmpty else { return users }
      return users.filter { $0.name.lowercased().contains(needle) }
    }
  }

  enum Action: Equatable {
    case onAppear
    case loaded(FollowLists)
    case loadFailed
    case tabSelected(Tab)
    case queryChanged(String)
    case followButtonTapped(FollowUser.ID)
    case followFailed(FollowUser.ID, restore: Bool)
    case userTapped(FollowUser.ID)
    case backButtonTapped
    case delegate(Delegate)
  }

  enum Delegate: Equatable {
    case dismiss
    /// 사용자 프로필 (UI-5a)
    case showProfile(String)
  }

  @Dependency(\.followListClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.lists == nil else { return .none }
        state.loadFailed = false
        let name = state.userName
        return .run { send in
          do {
            try await send(.loaded(self.client.fetch(name)))
          } catch {
            await send(.loadFailed)
          }
        }

      case let .loaded(lists):
        state.lists = lists
        return .none

      case .loadFailed:
        state.loadFailed = true
        return .none

      case let .tabSelected(tab):
        state.tab = tab
        return .none

      case let .queryChanged(text):
        state.query = text
        return .none

      case let .followButtonTapped(id):
        guard let previous = Self.isFollowing(id, in: state.lists) else { return .none }
        Self.setFollowing(!previous, id: id, in: &state.lists)
        return .run { send in
          do {
            try await self.client.setFollowing(id, !previous)
          } catch {
            await send(.followFailed(id, restore: previous))
          }
        }

      case let .followFailed(id, restore):
        Self.setFollowing(restore, id: id, in: &state.lists)
        return .none

      case let .userTapped(id):
        return .send(.delegate(.showProfile(id)))

      case .backButtonTapped:
        return .send(.delegate(.dismiss))

      case .delegate:
        return .none
      }
    }
  }

  private static func isFollowing(_ id: FollowUser.ID, in lists: FollowLists?) -> Bool? {
    guard let lists else { return nil }
    return (lists.followers + lists.following).first { $0.id == id }?.isFollowing
  }

  /// 같은 사람이 두 목록에 있으면 둘 다 바꾸고, 팔로잉 수를 ±1 한다
  private static func setFollowing(_ isFollowing: Bool, id: FollowUser.ID, in lists: inout FollowLists?) {
    guard var updated = lists, self.isFollowing(id, in: updated) != isFollowing else { return }
    for index in updated.followers.indices where updated.followers[index].id == id {
      updated.followers[index].isFollowing = isFollowing
    }
    for index in updated.following.indices where updated.following[index].id == id {
      updated.following[index].isFollowing = isFollowing
    }
    updated.followingCount += isFollowing ? 1 : -1
    lists = updated
  }
}
