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
    var toast: String?
    /// 내 최애 가수 PLAY — 재생 중이면 일시정지 모양
    var isFavoriteArtistPlaying = false
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
    case myRecommendationTapped(HomeMyRecommendation.ID)
    case votingRelayTapped(HomeVotingRelay.ID)
    case predictionOptionTapped(HomePrediction.Option.ID)
    case predictionLoaded([HomePrediction.Option])
    case predictionFailed
    case liveTicked
    case liveListeningLoaded(HomeLiveListening)
    case liveSongTapped(HomeLiveListening.Song.ID)
    case friendTapped(HomeFriendListening.ID)
    case toastDismissed
    case todayPickTapped(HomeTodayPick.ID)
    case timeOfDaySongTapped(HomeChartSong.ID)
    case favoriteArtistTapped
    case favoriteArtistPlayTapped
    case favoriteSongTapped(HomeChartSong.ID)
    case popularPostTapped(HomePopularPost.ID)
    case popularArtistTapped(String)
    case playlistTapped(HomePlaylistCard.ID)
    case videoTapped(HomeVideo.ID)
    case newUserActionTapped(HomeNewUserAction)
    case delegate(HomeDelegate)
  }

  /// 지금 위플리에서 듣는 중 — 원본은 5초마다 수가 바뀐다
  static let liveInterval: Duration = .seconds(5)

  private enum CancelID {
    case timer
    case live
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
        let live = Effect<Action>.run { send in
          for await _ in self.clock.timer(interval: Self.liveInterval) {
            await send(.liveTicked)
          }
        }
        .cancellable(id: CancelID.live, cancelInFlight: true)
        guard state.feed == nil else { return .merge(timer, live) }
        return .merge(self.load(&state), timer, live)

      case .onDisappear:
        return .merge(.cancel(id: CancelID.timer), .cancel(id: CancelID.live))

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

      // 원본에 목적지가 없다(전체듣기 · 완성된 플리 전체듣기 · 배너 · 친구) — 재생 · 화면이 생기면 잇는다
      case .chartPlayAllTapped, .completedPlayAllTapped, .bannerTapped, .friendTapped, .delegate:
        return .none

      default:
        return self.participation(action, &state)
      }
    }
  }

  /// 내 참여 · 사람 섹션(#102)
  private func participation(_ action: Action, _ state: inout State) -> Effect<Action> {
    switch action {
    case let .myRecommendationTapped(id):
      guard let item = state.feed?.myRecommendations.first(where: { $0.id == id }) else { return .none }
      return .send(.delegate(.showMyRecommendation(relayID: item.relayID)))

    case let .votingRelayTapped(id):
      return .send(.delegate(.showRelay(id)))

    case let .liveSongTapped(id):
      return .send(.delegate(.showSong(id)))

    case .predictionOptionTapped, .predictionLoaded, .predictionFailed:
      return self.prediction(action, &state)

    case .liveTicked, .liveListeningLoaded:
      return self.liveListening(action, &state)

    case .toastDismissed:
      state.toast = nil
      return .none

    default:
      return self.discovery(action, &state)
    }
  }

  /// 발견 · 내 취향 섹션(#103) — 이름으로 분명한 목적지만 잇는다
  private func discovery(_ action: Action, _ state: inout State) -> Effect<Action> {
    switch action {
    case let .todayPickTapped(id), let .timeOfDaySongTapped(id), let .favoriteSongTapped(id):
      return .send(.delegate(.showSong(id)))

    case .favoriteArtistTapped:
      guard let artist = state.feed?.favoriteArtist else { return .none }
      return .send(.delegate(.showArtist(artist.name)))

    case let .popularArtistTapped(name):
      return .send(.delegate(.showArtist(name)))

    case .favoriteArtistPlayTapped:
      state.isFavoriteArtistPlaying.toggle()
      return .none

    case let .popularPostTapped(id):
      return .send(.delegate(.showPost(id)))

    case let .playlistTapped(id):
      return .send(.delegate(.showPlaylist(id)))

    // 새 사용자 안내 — 첫 곡 추천은 릴레이 탭, 친구 찾기는 검색 탭으로(원본에 목적지 없음)
    case .newUserActionTapped(.recommendFirstSong):
      return .send(.delegate(.switchTab(.relay)))

    case .newUserActionTapped(.findFriends):
      return .send(.delegate(.switchTab(.search)))

    default:
      return .none
    }
  }

  /// 지금 위플리에서 듣는 중 — 5초마다 서버 수를 다시 받는다
  private func liveListening(_ action: Action, _ state: inout State) -> Effect<Action> {
    switch action {
    case .liveTicked:
      guard state.feed != nil else { return .none }
      return .run { send in
        if let live = try? await self.client.fetchLiveListening() {
          await send(.liveListeningLoaded(live))
        }
      }

    case let .liveListeningLoaded(live):
      state.feed?.liveListening = live
      return .none

    default:
      return .none
    }
  }

  /// 1위 예측 — 한 번만 고른다(8d). 먼저 반영하고 실패하면 되돌린다(DEC-004)
  private func prediction(_ action: Action, _ state: inout State) -> Effect<Action> {
    switch action {
    case let .predictionOptionTapped(id):
      // 한 번만 고른다 — 바꿀 수 없다(8d)
      guard let prediction = state.feed?.prediction, prediction.pickedID == nil else { return .none }
      state.feed?.prediction?.pickedID = id
      let relayID = prediction.relayID
      return .run { send in
        do {
          try await send(.predictionLoaded(self.client.predict(relayID, id)))
        } catch {
          await send(.predictionFailed)
        }
      }

    case let .predictionLoaded(options):
      state.feed?.prediction?.options = options
      return .none

    case .predictionFailed:
      state.feed?.prediction?.pickedID = nil
      // 원본에 없는 문구 — 디자인 확인 필요
      state.toast = "예측을 저장하지 못했어요. 다시 골라 주세요"
      return .none

    default:
      return .none
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
  /// 내 추천곡 → 내 추천곡 실시간 순위(UI-8a)
  case showMyRecommendation(relayID: String)
  case showArtist(String)
  case showPost(String)
  case showPlaylist(String)
  case switchTab(MainTabFeature.Tab)
}

/// 새 사용자 안내 버튼(원본 newUser)
enum HomeNewUserAction: Equatable, Sendable {
  case recommendFirstSong
  case findFriends
  case pickFavoriteArtist
  case listenTop100
}
