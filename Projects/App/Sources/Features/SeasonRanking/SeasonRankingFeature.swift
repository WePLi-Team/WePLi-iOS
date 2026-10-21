import ComposableArchitecture
import Foundation

// UI-8f · DEC-022 — 시즌 랭킹(push). 1위 예측(8d) 「내 칭호」 머리에서 연다.
// 큐레이터 탭은 내 순위와 다음 목표, 호스트 탭은 릴레이를 잘 여는 사람(팔로우)

@Reducer
struct SeasonRankingFeature {
  @ObservableState
  struct State: Equatable {
    var tab: SeasonRankingTab = .curator
    var ranking: SeasonRanking?
    var loadFailed = false
    var now = Date()
    var toast: String?
  }

  enum Action: Equatable {
    case onAppear
    case loaded(SeasonRanking)
    case loadFailed
    case retryButtonTapped
    case backButtonTapped
    case tabSelected(SeasonRankingTab)
    case followTapped(SeasonHost.ID)
    case followFailed(SeasonHost.ID, wasFollowing: Bool)
    case toastDismissed
    case delegate(SeasonRankingDelegate)
  }

  @Dependency(\.seasonRankingClient)
  var client

  @Dependency(\.date.now)
  var date

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.ranking == nil else { return .none }
        return self.load(&state)
      case let .loaded(ranking):
        state.ranking = ranking
        return .none
      case .loadFailed:
        state.loadFailed = true
        return .none
      case .retryButtonTapped:
        return self.load(&state)
      case .backButtonTapped:
        return .send(.delegate(.dismiss))
      case let .tabSelected(tab):
        state.tab = tab
        return .none
      case let .followTapped(id):
        return self.toggleFollow(id, &state)
      case let .followFailed(id, wasFollowing):
        Self.setFollowing(id, wasFollowing, &state)
        // 원본에 없는 문구 — 디자인 확인 필요
        state.toast = "팔로우를 바꾸지 못했어요"
        return .none
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
    state.now = self.date
    return .run { send in
      do {
        try await send(.loaded(self.client.fetch()))
      } catch {
        await send(.loadFailed)
      }
    }
  }

  /// 먼저 반영하고 실패하면 되돌린다(DEC-004)
  private func toggleFollow(_ id: SeasonHost.ID, _ state: inout State) -> Effect<Action> {
    guard let host = state.ranking?.hosts.first(where: { $0.id == id }) else { return .none }
    let isOn = !host.isFollowing
    Self.setFollowing(id, isOn, &state)
    return .run { send in
      do {
        try await self.client.setFollowing(id, isOn)
      } catch {
        await send(.followFailed(id, wasFollowing: !isOn))
      }
    }
  }

  private static func setFollowing(_ id: SeasonHost.ID, _ isOn: Bool, _ state: inout State) {
    guard let index = state.ranking?.hosts.firstIndex(where: { $0.id == id }) else { return }
    state.ranking?.hosts[index].isFollowing = isOn
  }
}

enum SeasonRankingDelegate: Equatable {
  case dismiss
}
