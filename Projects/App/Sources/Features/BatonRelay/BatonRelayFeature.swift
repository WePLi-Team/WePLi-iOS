import ComposableArchitecture
import Foundation

// REQ-035 · UI-8c 바통 릴레이 · UI-11c 바통 초대 받기 · DEC-004
// 링크로 들어오면 11c(받기 · 바로 넘기기)를 먼저 보여주고, 받으면 24시간 타이머가 돈다. 곡과 다음 키워드를 고르면 넘긴다.

@Reducer
struct BatonRelayFeature {
  @ObservableState
  struct State: Equatable {
    let relayID: String
    var relay: BatonRelay?
    var loadFailed = false
    var now = Date()
    /// 11c 「바통 받기」 뒤 「곡 고르러 가기」를 눌렀는지 — 누르면 8c를 보여준다
    var showsChain = false
    var pickID: BatonRelay.Pick.ID?
    var keyword: String?
    var isSending = false
    var toast: String?

    init(relayID: String) {
      self.relayID = relayID
    }

    /// 11c를 보여줄지 — 받기 전 · 바로 넘김 · 받았지만 아직 곡 고르러 가지 않음
    var showsInvite: Bool {
      switch self.relay?.turn {
      case .invited, .skipped: true
      case .mine: !self.showsChain
      default: false
      }
    }

    var canPass: Bool {
      self.pickID != nil && self.keyword != nil && !self.isSending
    }
  }

  enum Action: Equatable {
    case onAppear
    case onDisappear
    case loaded(BatonRelay)
    case loadFailed
    case retryButtonTapped
    case closeTapped
    case acceptTapped
    case accepted(endsAt: Date)
    case skipTapped
    case skipped
    case goPickTapped
    case pickTapped(BatonRelay.Pick.ID)
    case keywordTapped(String)
    case passTapped
    case passed(BatonRelay)
    case requestFailed
    case timerTicked
    case toastDismissed
    case delegate(BatonRelayDelegate)
  }

  enum CancelID {
    case timer
  }

  @Dependency(\.batonRelayClient)
  var client

  @Dependency(\.continuousClock)
  var clock

  @Dependency(\.date.now)
  var date

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.now = self.date
        guard state.relay == nil else { return self.timer() }
        return .merge(self.load(&state), self.timer())
      case .onDisappear:
        return .cancel(id: CancelID.timer)
      case let .loaded(relay):
        state.relay = relay
        return .none
      case .loadFailed:
        state.loadFailed = true
        return .none
      case .retryButtonTapped:
        return self.load(&state)
      case .closeTapped:
        return .send(.delegate(.dismiss))
      case .timerTicked:
        state.now = self.date
        return .none
      case .toastDismissed:
        state.toast = nil
        return .none
      case .acceptTapped, .accepted, .skipTapped, .skipped, .goPickTapped:
        return self.invite(&state, action)
      case .pickTapped, .keywordTapped, .passTapped, .passed, .requestFailed:
        return self.myTurn(&state, action)
      case .delegate:
        return .none
      }
    }
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.loadFailed = false
    let relayID = state.relayID
    return .run { send in
      do {
        try await send(.loaded(self.client.fetch(relayID)))
      } catch {
        await send(.loadFailed)
      }
    }
  }

  private func timer() -> Effect<Action> {
    .run { send in
      for await _ in self.clock.timer(interval: .seconds(1)) {
        await send(.timerTicked)
      }
    }
    .cancellable(id: CancelID.timer, cancelInFlight: true)
  }

  // MARK: 11c 받기 · 바로 넘기기

  private func invite(_ state: inout State, _ action: Action) -> Effect<Action> {
    let relayID = state.relayID
    switch action {
    case .acceptTapped:
      guard case .invited = state.relay?.turn, !state.isSending else { return .none }
      state.isSending = true
      return .run { send in
        do {
          try await send(.accepted(endsAt: self.client.accept(relayID)))
        } catch {
          await send(.requestFailed)
        }
      }
    case let .accepted(endsAt):
      state.isSending = false
      state.relay?.turn = .mine(endsAt: endsAt)
    case .skipTapped:
      guard case .invited = state.relay?.turn, !state.isSending else { return .none }
      state.isSending = true
      return .run { send in
        do {
          try await self.client.skip(relayID)
          await send(.skipped)
        } catch {
          await send(.requestFailed)
        }
      }
    case .skipped:
      state.isSending = false
      state.relay?.turn = .skipped
    case .goPickTapped:
      state.showsChain = true
    default:
      break
    }
    return .none
  }

  // MARK: 8c 내 차례

  private func myTurn(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case let .pickTapped(id):
      guard case .mine = state.relay?.turn else { return .none }
      state.pickID = id
    case let .keywordTapped(keyword):
      guard case .mine = state.relay?.turn else { return .none }
      state.keyword = keyword
    case .passTapped:
      guard state.canPass, let pickID = state.pickID, let keyword = state.keyword else { return .none }
      state.isSending = true
      let relayID = state.relayID
      return .run { send in
        do {
          try await send(.passed(self.client.pass(relayID, pickID, keyword)))
        } catch {
          await send(.requestFailed)
        }
      }
    case let .passed(relay):
      state.isSending = false
      state.relay = relay
    case .requestFailed:
      state.isSending = false
      // 원본에 없는 문구 — 디자인 확인 필요
      state.toast = "잠시 후 다시 시도해 주세요"
    default:
      break
    }
    return .none
  }
}

enum BatonRelayDelegate: Equatable {
  case dismiss
}
