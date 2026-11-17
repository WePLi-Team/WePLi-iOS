import ComposableArchitecture
import Foundation
import WePLiDesignSystem
import WePLiSharedModels

// REQ-030 · UI-10a — 릴레이 탭 첫 화면

@Reducer
public struct RelayListFeature {
  @ObservableState
  public struct State: Equatable {
    public var filter: RelayFilter = .live
    public var relays: [Relay] = []
    public var isLoading = false
    public var loadFailed = false

    public var sections: RelaySections {
      RelaySections.make(filter: self.filter, relays: self.relays)
    }

    public init(filter: RelayFilter = .live, relays: [Relay] = [], isLoading: Bool = false, loadFailed: Bool = false) {
      self.filter = filter
      self.relays = relays
      self.isLoading = isLoading
      self.loadFailed = loadFailed
    }
  }

  public enum Action: Equatable {
    case onAppear
    case relaysLoaded([Relay])
    case relaysFailed
    case filterSelected(RelayFilter)
    case relayTapped(Relay.ID)
    case openRelayButtonTapped
    case retryButtonTapped
    case delegate(Delegate)
  }

  public enum Delegate: Equatable {
    /// 릴레이 상세(투표 방식별 화면)로 — 상세 이슈에서 연결
    case showRelay(Relay.ID)
    /// 릴레이 만들기(UI-6a)로 — 6a 이슈에서 연결
    case showCreateRelay
  }

  @Dependency(\.relayClient)
  public var relayClient

  public var body: some ReducerOf<Self> {
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

  public init() {}
}
