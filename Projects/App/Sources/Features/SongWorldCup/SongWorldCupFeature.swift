import ComposableArchitecture
import Foundation

// REQ-034 · UI-8b · DEC-004 — 곡 월드컵 투표
// 고르면 0.26초 뒤 다음 대결(원본). 결승이 끝나면 우승곡을 서버에 보내고 다른 사람들의 결과와 비교한다.

@Reducer
struct SongWorldCupFeature {
  @ObservableState
  struct State: Equatable {
    let relayID: String
    let topic: String
    var songs: [WorldCupSong] = []
    var bracket = WorldCupBracket(songCount: 0)
    /// 고른 쪽 — 다음 대결로 넘어가기 전까지 다른 탭은 받지 않는다
    var picked: WorldCupSide?
    var crowd: WorldCupCrowd?
    var loadFailed = false
    var toast: String?

    init(relayID: String, topic: String) {
      self.relayID = relayID
      self.topic = topic
    }

    var pair: (top: WorldCupSong, bottom: WorldCupSong)? {
      guard let pair = self.bracket.pair, self.songs.indices.contains(pair.bottom) else { return nil }
      return (self.songs[pair.top], self.songs[pair.bottom])
    }

    var champion: WorldCupSong? {
      self.bracket.champion.flatMap { self.songs.indices.contains($0) ? self.songs[$0] : nil }
    }
  }

  enum Action: Equatable {
    case onAppear
    case loaded([WorldCupSong])
    case loadFailed
    case retryButtonTapped
    case sideTapped(WorldCupSide)
    case advance
    case crowdLoaded(WorldCupCrowd)
    case submitFailed
    case restartTapped
    case shareTapped
    case closeTapped
    case toastDismissed
    case delegate(SongWorldCupDelegate)
  }

  /// 고른 뒤 다음 대결까지(원본 setTimeout 260ms)
  static let advanceDelay: Duration = .milliseconds(260)

  @Dependency(\.songWorldCupClient)
  var client

  @Dependency(\.continuousClock)
  var clock

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.songs.isEmpty else { return .none }
        return self.load(&state)

      case let .loaded(songs):
        state.songs = songs
        state.bracket = WorldCupBracket(songCount: songs.count)
        return .none

      case .loadFailed:
        state.loadFailed = true
        return .none

      case .retryButtonTapped:
        return self.load(&state)

      case let .sideTapped(side):
        guard state.picked == nil, state.pair != nil else { return .none }
        state.picked = side
        return .run { send in
          try await self.clock.sleep(for: Self.advanceDelay)
          await send(.advance)
        }

      case .advance:
        guard let side = state.picked else { return .none }
        state.picked = nil
        state.bracket.pick(side)
        guard let champion = state.champion else { return .none }
        let relayID = state.relayID
        return .run { send in
          do {
            try await send(.crowdLoaded(self.client.submit(relayID, champion.id)))
          } catch {
            await send(.submitFailed)
          }
        }

      case let .crowdLoaded(crowd):
        state.crowd = crowd
        return .none

      case .submitFailed:
        // 원본에 없는 문구 — 디자인 확인 필요
        state.toast = "결과를 저장하지 못했어요"
        return .none

      case .restartTapped:
        state.bracket = WorldCupBracket(songCount: state.songs.count)
        state.picked = nil
        state.crowd = nil
        return .none

      case .closeTapped:
        return .send(.delegate(.dismiss))

      case .toastDismissed:
        state.toast = nil
        return .none

      // 원본에 동작이 없다(결과 공유하기) — 공유 카드 방식이 정해지면 잇는다
      case .shareTapped, .delegate:
        return .none
      }
    }
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.loadFailed = false
    let relayID = state.relayID
    return .run { send in
      do {
        try await send(.loaded(self.client.fetchSongs(relayID)))
      } catch {
        await send(.loadFailed)
      }
    }
  }
}

enum SongWorldCupDelegate: Equatable {
  case dismiss
}
