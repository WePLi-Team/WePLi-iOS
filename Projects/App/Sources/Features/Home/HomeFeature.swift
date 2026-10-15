import ComposableArchitecture
import Foundation

// REQ-020 · UI-12a · DEC-008 — 통합 홈
// 원본은 화살표 · 카드 대부분에 목적지가 없다. 이름으로 분명한 것만 잇는다(알림 · 릴레이 상세 · 곡 상세 · 곡 메뉴).

@Reducer
struct HomeFeature {
  @ObservableState
  struct State: Equatable {
    var feed: HomeFeed?
    var heroPage = 0
    var now = Date()
    var loadFailed = false
  }

  enum Action: Equatable {
    case onAppear
    case onDisappear
    case loaded(HomeFeed)
    case loadFailed
    case retryButtonTapped
    case timerTicked
    case heroPageChanged(Int)
    case heroTapped(HomeHero.ID)
    case notificationsTapped
    case chartSongTapped(HomeChartSong.ID)
    case chartMoreTapped(HomeChartSong.ID)
    case chartPlayAllTapped
    case completedPlayAllTapped(HomeHero.ID)
    case bannerTapped(HomeBanner.ID)
    case delegate(HomeDelegate)
  }

  private enum CancelID {
    case timer
  }

  @Dependency(\.homeClient)
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
        let timer = Effect<Action>.run { send in
          for await _ in self.clock.timer(interval: .seconds(1)) {
            await send(.timerTicked)
          }
        }
        .cancellable(id: CancelID.timer, cancelInFlight: true)
        guard state.feed == nil else { return timer }
        return .merge(self.load(&state), timer)

      case .onDisappear:
        return .cancel(id: CancelID.timer)

      case let .loaded(feed):
        state.feed = feed
        return .none

      case .loadFailed:
        state.loadFailed = true
        return .none

      case .retryButtonTapped:
        return self.load(&state)

      case .timerTicked:
        state.now = self.date
        return .none

      case let .heroPageChanged(page):
        state.heroPage = page
        return .none

      case let .heroTapped(id):
        return .send(.delegate(.showRelay(id)))

      case .notificationsTapped:
        return .send(.delegate(.showNotifications))

      case let .chartSongTapped(id):
        return .send(.delegate(.showSong(id)))

      case let .chartMoreTapped(id):
        guard let song = state.feed?.chart.first(where: { $0.id == id }) else { return .none }
        return .send(.delegate(.songMenu(song.track)))

      // 원본에 목적지가 없다(전체듣기 · 완성된 플리 전체듣기 · 배너) — 재생 · 화면이 생기면 잇는다
      case .chartPlayAllTapped, .completedPlayAllTapped, .bannerTapped, .delegate:
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

enum HomeDelegate: Equatable {
  case showNotifications
  case showRelay(String)
  case showSong(String)
  /// TOP 100 ··· → 곡 메뉴 시트(UI-1b)
  case songMenu(ComposeTrack)
}
