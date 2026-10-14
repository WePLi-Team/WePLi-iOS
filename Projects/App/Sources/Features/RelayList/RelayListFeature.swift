import ComposableArchitecture
import Foundation

// REQ-030 · UI-10a — 릴레이 탭 첫 화면

@Reducer
struct RelayListFeature {
  @ObservableState
  struct State: Equatable {
    var filter: RelayFilter = .live
    var relays: [Relay] = []
    var now = Date()
    var isLoading = false
    var loadFailed = false

    var sections: RelaySections {
      RelaySections.make(filter: self.filter, relays: self.relays)
    }
  }

  enum Action: Equatable {
    case onAppear
    case onDisappear
    case relaysLoaded([Relay])
    case relaysFailed
    case timerTicked
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

  private enum CancelID {
    case timer
  }

  @Dependency(\.relayClient)
  var relayClient

  @Dependency(\.continuousClock)
  var clock

  @Dependency(\.date.now)
  var now

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.now = self.now
        let load: Effect<Action> = state.relays.isEmpty ? self.load(&state) : .none
        let timer: Effect<Action> = .run { send in
          for await _ in self.clock.timer(interval: .seconds(1)) {
            await send(.timerTicked)
          }
        }
        .cancellable(id: CancelID.timer, cancelInFlight: true)
        return .merge(load, timer)

      case .onDisappear:
        return .cancel(id: CancelID.timer)

      case let .relaysLoaded(relays):
        state.isLoading = false
        state.relays = relays
        return .none

      case .relaysFailed:
        state.isLoading = false
        state.loadFailed = true
        return .none

      case .timerTicked:
        state.now = self.now
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
