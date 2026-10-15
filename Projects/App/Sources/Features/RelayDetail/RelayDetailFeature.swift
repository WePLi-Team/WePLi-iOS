import ComposableArchitecture
import Foundation

// REQ-031 · REQ-037 · UI-3c — 릴레이리스트 상세 · 상태

@Reducer
struct RelayDetailFeature {
  @ObservableState
  struct State: Equatable {
    let relayID: String
    var detail: RelayDetail?
    var now = Date()
    var loadFailed = false

    var displayState: RelayDisplayState? {
      self.detail.map { RelayDisplayState($0, now: self.now) }
    }

    init(relayID: String, detail: RelayDetail? = nil) {
      self.relayID = relayID
      self.detail = detail
    }
  }

  enum Action: Equatable {
    case onAppear
    case onDisappear
    case detailLoaded(RelayDetail)
    case detailFailed
    case retryButtonTapped
    case timerTicked
    case backButtonTapped
    case shareButtonTapped
    case recommendButtonTapped
    case voteButtonTapped
    case playAllButtonTapped
    case addToMyPlaylistButtonTapped
    case exportButtonTapped
    case songPlayTapped(RankedSong.ID)
    case delegate(Delegate)
  }

  enum Delegate: Equatable {
    case dismiss
    case share(relayID: String)
    /// 곡 검색 · 추천 (UI-2a)
    case showRecommend(relayID: String)
    /// 카드 투표 (UI-3b)
    case showVote(relayID: String)
    case playAll(relayID: String)
    case addToMyPlaylist(relayID: String)
    /// 내 음악 앱으로 내보내기 — 완성이면 UI-14c, 진행 중이면 먼저 담기 UI-14l
    case export(relayID: String)
    case playSong(RankedSong.ID)
  }

  private enum CancelID {
    case timer
  }

  @Dependency(\.relayDetailClient)
  var client

  @Dependency(\.continuousClock)
  var clock

  @Dependency(\.date.now)
  var now

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.now = self.now
        let timer: Effect<Action> = .run { send in
          for await _ in self.clock.timer(interval: .seconds(1)) {
            await send(.timerTicked)
          }
        }
        .cancellable(id: CancelID.timer, cancelInFlight: true)
        return state.detail == nil ? .merge(self.load(&state), timer) : timer

      case .onDisappear:
        return .cancel(id: CancelID.timer)

      case let .detailLoaded(detail):
        state.detail = detail
        return .none

      case .detailFailed:
        state.loadFailed = true
        return .none

      case .retryButtonTapped:
        return self.load(&state)

      case .timerTicked:
        state.now = self.now
        // 완성되면 더 셀 시간이 없다
        return state.displayState == .completed ? .cancel(id: CancelID.timer) : .none

      case .backButtonTapped:
        return .send(.delegate(.dismiss))

      case .shareButtonTapped:
        return .send(.delegate(.share(relayID: state.relayID)))

      case .recommendButtonTapped:
        return .send(.delegate(.showRecommend(relayID: state.relayID)))

      case .voteButtonTapped:
        return .send(.delegate(.showVote(relayID: state.relayID)))

      case .playAllButtonTapped:
        return .send(.delegate(.playAll(relayID: state.relayID)))

      case .addToMyPlaylistButtonTapped:
        return .send(.delegate(.addToMyPlaylist(relayID: state.relayID)))

      case .exportButtonTapped:
        return .send(.delegate(.export(relayID: state.relayID)))

      case let .songPlayTapped(id):
        return .send(.delegate(.playSong(id)))

      case .delegate:
        return .none
      }
    }
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.loadFailed = false
    let id = state.relayID
    return .run { send in
      do {
        try await send(.detailLoaded(self.client.fetch(id)))
      } catch {
        await send(.detailFailed)
      }
    }
  }
}
