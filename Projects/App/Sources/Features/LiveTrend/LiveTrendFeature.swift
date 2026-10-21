import ComposableArchitecture
import Foundation

// REQ-079 · UI-13f · DEC-004 — 지금 위플리 · 전체 트렌드(push). 듣는 사람 수는 2초마다 다시 받고, 시간대를 고르면 목록이 바뀐다.

@Reducer
struct LiveTrendFeature {
  @ObservableState
  struct State: Equatable {
    var trend: LiveTrend?
    var loadFailed = false
    var slot: LiveTrendSlot = .now

    var songs: [LiveTrendSong] {
      self.trend?.rankings[self.slot] ?? []
    }
  }

  enum Action: Equatable {
    case onAppear
    case onDisappear
    case loaded(LiveTrend)
    case loadFailed
    case retryButtonTapped
    case listenersTicked
    case listenersUpdated(Int)
    case backButtonTapped
    case slotSelected(LiveTrendSlot)
    case songTapped(LiveTrendSong.ID)
    case heroPlayTapped
    case delegate(LiveTrendDelegate)
  }

  enum CancelID {
    case poll
  }

  /// 듣는 사람 수를 다시 받는 간격(원본 2초)
  static let pollInterval: Duration = .seconds(2)

  @Dependency(\.liveTrendClient)
  var client

  @Dependency(\.continuousClock)
  var clock

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        let poll = Effect<Action>.run { send in
          for await _ in self.clock.timer(interval: Self.pollInterval) {
            await send(.listenersTicked)
          }
        }
        .cancellable(id: CancelID.poll, cancelInFlight: true)
        return state.trend == nil ? .merge(self.load(&state), poll) : poll
      case .onDisappear:
        return .cancel(id: CancelID.poll)
      case let .loaded(trend):
        state.trend = trend
        return .none
      case .loadFailed:
        state.loadFailed = true
        return .none
      case .retryButtonTapped:
        return self.load(&state)
      case .listenersTicked:
        guard state.trend != nil else { return .none }
        return .run { send in
          // 한 번 못 받아도 다음 틱에 다시 받는다
          if let count = try? await self.client.listeners() {
            await send(.listenersUpdated(count))
          }
        }
      case let .listenersUpdated(count):
        state.trend?.listeners = count
        return .none
      case .backButtonTapped:
        return .send(.delegate(.dismiss))
      case let .slotSelected(slot):
        state.slot = slot
        return .none
      case let .songTapped(id):
        return .send(.delegate(.showSong(id)))
      case .heroPlayTapped:
        guard let hero = state.trend?.hero else { return .none }
        return .send(.delegate(.play(hero)))
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
}

enum LiveTrendDelegate: Equatable {
  case dismiss
  case showSong(LiveTrendSong.ID)
  /// 히어로 「듣기」 → 미리듣기 플레이어(UI-4b)
  case play(LiveTrendSong)
}
