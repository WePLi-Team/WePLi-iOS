import ComposableArchitecture
import Foundation

// REQ-022 · UI-4a 미니 플레이어 · UI-4b 지금 재생 중 · DEC-004
// 한 재생을 미니 플레이어와 전체 화면이 함께 쓴다. 30초 미리듣기가 끝나면 다음 곡으로 넘어가고, 마지막 곡이면 멈춘다.

@Reducer
struct PlayerFeature {
  @ObservableState
  struct State: Equatable {
    var queue: [PlayerTrack] = []
    var index: Int?
    /// 「첫 사랑이 생각나는 노래 모음」 — 어느 릴레이 · 플리에서 재생 중인지
    var source: String?
    var isPlaying = false
    /// 들은 초(0…30)
    var position = 0
    var likedIDs: Set<PlayerTrack.ID> = []
    /// 지금 재생 중(4b)
    var isExpanded = false

    var current: PlayerTrack? {
      self.index.flatMap { self.queue.indices.contains($0) ? self.queue[$0] : nil }
    }

    /// 「다음 곡」
    var upcoming: [PlayerTrack] {
      guard let index = self.index, index + 1 < self.queue.count else { return [] }
      return Array(self.queue[(index + 1)...])
    }

    var isLiked: Bool {
      self.current.map { self.likedIDs.contains($0.id) } ?? false
    }
  }

  enum Action: Equatable {
    case play(queue: [PlayerTrack], startAt: Int, source: String?)
    case playPauseTapped
    case nextTapped
    case previousTapped
    case tick
    case miniPlayerTapped
    case collapseTapped
    case expandedChanged(Bool)
    case likeTapped
    case likeFailed(PlayerTrack.ID, restore: Bool)
    case openInMusicTapped
    case upcomingTapped(PlayerTrack.ID)
  }

  enum CancelID {
    case timer
  }

  @Dependency(\.playerClient)
  var client

  @Dependency(\.continuousClock)
  var clock

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .play(queue, startAt, source):
        guard queue.indices.contains(startAt) else { return .none }
        state.queue = queue
        state.source = source
        return self.start(&state, at: startAt)
      case .playPauseTapped:
        return self.togglePlay(&state)
      case .nextTapped, .previousTapped, .tick, .upcomingTapped:
        return self.move(&state, action)
      case .miniPlayerTapped:
        state.isExpanded = state.current != nil
        return .none
      case .collapseTapped:
        state.isExpanded = false
        return .none
      case let .expandedChanged(isExpanded):
        state.isExpanded = isExpanded && state.current != nil
        return .none
      case .likeTapped, .likeFailed, .openInMusicTapped:
        return self.trackAction(&state, action)
      }
    }
  }

  // MARK: 재생 · 일시정지

  private func start(_ state: inout State, at index: Int) -> Effect<Action> {
    state.index = index
    state.position = 0
    state.isPlaying = true
    guard let track = state.current else { return .none }
    return .merge(.run { _ in await self.client.play(track) }, self.timer())
  }

  private func togglePlay(_ state: inout State) -> Effect<Action> {
    guard state.current != nil else { return .none }
    state.isPlaying.toggle()
    if state.isPlaying {
      return .merge(.run { _ in await self.client.resume() }, self.timer())
    }
    return .merge(.run { _ in await self.client.pause() }, .cancel(id: CancelID.timer))
  }

  private func timer() -> Effect<Action> {
    .run { send in
      for await _ in self.clock.timer(interval: .seconds(1)) {
        await send(.tick)
      }
    }
    .cancellable(id: CancelID.timer, cancelInFlight: true)
  }

  private func stop(_ state: inout State) -> Effect<Action> {
    state.isPlaying = false
    state.position = 0
    return .merge(.run { _ in await self.client.pause() }, .cancel(id: CancelID.timer))
  }

  // MARK: 이전 · 다음 · 진행

  private func move(_ state: inout State, _ action: Action) -> Effect<Action> {
    guard let index = state.index else { return .none }
    switch action {
    case .tick:
      guard state.isPlaying else { return .none }
      state.position += 1
      guard state.position >= PlayerText.previewLength else { return .none }
      // 미리듣기가 끝나면 다음 곡 — 마지막 곡이면 처음으로 돌려 멈춘다
      return index + 1 < state.queue.count ? self.start(&state, at: index + 1) : self.stop(&state)
    case .nextTapped:
      return index + 1 < state.queue.count ? self.start(&state, at: index + 1) : self.stop(&state)
    case .previousTapped:
      // 3초 넘게 들었거나 첫 곡이면 처음부터
      let target = state.position > PlayerText.restartThreshold || index == 0 ? index : index - 1
      return self.start(&state, at: target)
    case let .upcomingTapped(id):
      guard let target = state.queue.firstIndex(where: { $0.id == id }) else { return .none }
      return self.start(&state, at: target)
    default:
      return .none
    }
  }

  // MARK: 좋아요 · Music에서 열기

  private func trackAction(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case .likeTapped:
      guard let track = state.current else { return .none }
      let wasLiked = state.likedIDs.contains(track.id)
      if wasLiked {
        state.likedIDs.remove(track.id)
      } else {
        state.likedIDs.insert(track.id)
      }
      return .run { send in
        do {
          try await self.client.setLiked(track.id, !wasLiked)
        } catch {
          await send(.likeFailed(track.id, restore: wasLiked))
        }
      }
    case let .likeFailed(id, restore):
      if restore {
        state.likedIDs.insert(id)
      } else {
        state.likedIDs.remove(id)
      }
      return .none
    case .openInMusicTapped:
      guard let track = state.current else { return .none }
      return .run { _ in await self.client.openInMusic(track) }
    default:
      return .none
    }
  }
}
