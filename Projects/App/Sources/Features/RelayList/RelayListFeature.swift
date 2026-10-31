import ComposableArchitecture
import Foundation

// REQ-030 · UI-10a — 릴레이 탭 첫 화면

@Reducer
struct RelayListFeature {
  @ObservableState
  struct State: Equatable {
    var filter: RelayFilter = .live
    var relays: [Relay] = []
    var isLoading = false
    var loadFailed = false

    var sections: RelaySections {
      RelaySections.make(filter: self.filter, relays: self.relays)
    }
  }

  enum Action: Equatable {
    case onAppear
    case relaysLoaded([Relay])
    case relaysFailed
    case filterSelected(RelayFilter)
    case relayTapped(Relay.ID)
    case openRelayButtonTapped
    case retryButtonTapped
    case delegate(Delegate)
  }

  enum Delegate: Equatable {
    /// 릴레이 상세(투표 방식별 화면)로 — 상세 이슈에서 연결
    case showRelay(Relay.ID)
    /// 릴레이 만들기(UI-6a)로 — 6a 이슈에서 연결
    case showCreateRelay
  }

  @Dependency(\.relayClient)
  var relayClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // 남은 시간은 행이 스스로 1초마다 다시 그린다(WePLiTicking)
        return state.relays.isEmpty ? self.load(&state) : .none

      case let .relaysLoaded(relays):
        state.isLoading = false
        state.relays = relays
        return .none

      case .relaysFailed:
        state.isLoading = false
        state.loadFailed = true
        return .none

      case let .filterSelected(filter):
        state.filter = filter
        return .none

      case let .relayTapped(id):
        return .send(.delegate(.showRelay(id)))

      case .openRelayButtonTapped:
        return .send(.delegate(.showCreateRelay))

      case .retryButtonTapped:
        return self.load(&state)

      case .delegate:
        return .none
      }
    }
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.isLoading = true
    state.loadFailed = false
    return .run { send in
      do {
        try await send(.relaysLoaded(self.relayClient.fetchRelays()))
      } catch {
        await send(.relaysFailed)
      }
    }
  }
}
