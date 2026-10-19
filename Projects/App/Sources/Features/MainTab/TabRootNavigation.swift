import ComposableArchitecture
import Foundation

// REQ-001 · DEC-007 — 탭 첫 화면에서 여는 화면
// 릴레이: 릴레이 상세 · 커뮤니티: 알림 · 게시글 상세 · 마이: 내 정보 수정 · 보관함 · 알림 설정 · 검색: 곡 · 플리 · 릴레이 · 게시글

struct TabRootNavigation: Reducer {
  typealias State = MainTabFeature.State
  typealias Action = MainTabFeature.Action

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .home(.delegate(delegate)):
        return self.openFromHome(delegate, &state)

      case let .relay(.delegate(.showRelay(id))):
        // 완성된 릴레이는 완성 플리 기준 화면(UI-14b 「8e·3c·4a의 완성된 플리가 모두 여기로」)
        let relay = state.relay.relays.first { $0.id == id }
        let isCompleted = relay.map { !$0.isLive } ?? false
        if isCompleted {
          state.relayPath.append(.completedPlaylist(CompletedPlaylistFeature.State(relayID: id)))
        } else if relay?.voteFormat == .baton {
          // 진행 중 바통 릴레이는 바통 화면(UI-8c) — 순위 · 투표가 없다
          state.relayPath.append(.batonRelay(BatonRelayFeature.State(relayID: id)))
        } else {
          state.relayPath.append(.relayDetail(RelayDetailFeature.State(relayID: id)))
        }
        return .none

      case .community(.friends(.delegate(.showListeningShare))):
        // 친구 피드의 「나」 → 연결과 공개 범위(UI-13a)
        state.listeningShare = ListeningShareFeature.State(nickname: state.my.profile?.nickname ?? "")
        return .none

      case let .community(.friends(.delegate(.showSong(id)))):
        state.communityPath.append(.songDetail(SongDetailFeature.State(songID: id)))
        return .none

      case .community(.delegate(.showNotifications)):
        state.communityPath.append(.notifications(NotificationsFeature.State()))
        return .none

      case let .community(.delegate(.showPost(id))):
        state.communityPath.append(.postDetail(PostDetailFeature.State(postID: id)))
        return .none

      case let .my(.delegate(.show(menu))):
        self.openMyMenu(menu, &state)
        return .none

      case .my(.delegate(.showAppInfo)):
        state.myPath.append(.appInfo(AppInfoFeature.State(isDeveloperModeEnabled: state.my.isDeveloperModeEnabled)))
        return .none

      case .my(.delegate(.editProfile)):
        guard let profile = state.my.profile else { return .none }
        state.myPath.append(.editProfile(EditProfileFeature.State(profile: profile)))
        return .none

      case let .search(.delegate(.showSong(id))):
        state.searchPath.append(.songDetail(SongDetailFeature.State(songID: id)))
        return .none

      case let .search(.delegate(.showList(id))):
        self.openSearchList(id, &state)
        return .none

      default:
        return .none
      }
    }
  }

  /// 홈(UI-12a) — 알림 · 릴레이 · 곡 · 곡 메뉴
  private func openFromHome(_ delegate: HomeDelegate, _ state: inout State) -> Effect<Action> {
    if let screen = Self.homeScreen(delegate) {
      state.homePath.append(screen)
      return .none
    }
    switch delegate {
    case let .switchTab(tab):
      state.selectedTab = tab
    case let .songMenu(song):
      state.songMenuSource = nil
      state.songMenu = SongMenuFeature.State(
        songID: song.id,
        title: song.title,
        artist: song.artist,
        isLiked: false,
        savesLike: true
      )
    default:
      break
    }
    return .none
  }

  /// 홈에서 push하는 화면 — 릴레이 쪽
  private static func homeScreen(_ delegate: HomeDelegate) -> MainTabFeature.Path.State? {
    switch delegate {
    case let .showRelay(id): .relayDetail(RelayDetailFeature.State(relayID: id))
    case let .showMyRecommendation(relayID): .myRecommendation(MyRecommendationFeature.State(relayID: relayID))
    case let .showCompletedPlaylist(id): .completedPlaylist(CompletedPlaylistFeature.State(relayID: id))
    case let .showPrediction(relayID): .topPrediction(TopPredictionFeature.State(relayID: relayID))
    case let .showBaton(id): .batonRelay(BatonRelayFeature.State(relayID: id))
    default: homeContentScreen(delegate)
    }
  }

  /// 홈에서 push하는 화면 — 알림 · 곡 · 아티스트 · 게시글 · 플리
  private static func homeContentScreen(_ delegate: HomeDelegate) -> MainTabFeature.Path.State? {
    switch delegate {
    case .showNotifications: .notifications(NotificationsFeature.State())
    case .showLiveTrend: .liveTrend(LiveTrendFeature.State())
    case .showDailySong: .dailySong(DailySongFeature.State())
    case let .showSong(id): .songDetail(SongDetailFeature.State(songID: id))
    case let .showArtist(name): .artist(ArtistFeature.State(artistID: name))
    case let .showPost(id): .postDetail(PostDetailFeature.State(postID: id))
    case let .showPlaylist(id): .playlistDetail(PlaylistDetailFeature.State(playlistID: id))
    default: nil
    }
  }

  /// 마이 메뉴 — 「내 활동」 세 메뉴는 보관함의 해당 세그먼트로(UI-5c 노트 01)
  private func openMyMenu(_ menu: MyMenu, _ state: inout State) {
    switch menu {
    case .myPlaylists: state.myPath.append(.library(LibraryFeature.State(segment: .playlists)))
    case .joinedRelays: state.myPath.append(.library(LibraryFeature.State(segment: .relays)))
    case .likesAndSaves: state.myPath.append(.library(LibraryFeature.State(segment: .likes)))
    case .notificationSettings: state.myPath.append(.notificationSettings(NotificationSettingsFeature.State()))
    case .musicServices: state.myPath.append(.musicServices(MusicServicesFeature.State()))
    case .serviceGuide: state.serviceGuide = ServiceGuideFeature.State()
    case .listeningShare:
      state.listeningShare = ListeningShareFeature.State(nickname: state.my.profile?.nickname ?? "")
    // 「공지 • 이용약관」은 공지(7a)로 — 약관은 앱 정보(7g, 「앱 버전」)에 있다
    case .noticesAndTerms: state.myPath.append(.notices(NoticesFeature.State()))
    case .developerMode: state.myPath.append(.appInfo(AppInfoFeature.State(isDeveloperModeEnabled: true)))
    }
  }

  /// 검색의 플리 · 릴레이 · 게시글 결과 — 부제의 종류(「릴레이리스트 · …」 · 「게시글 · …」)로 나눈다
  private func openSearchList(_ id: SearchList.ID, _ state: inout State) {
    let subtitle = state.search.results.lists.first { $0.id == id }?.subtitle ?? ""
    if subtitle.hasPrefix("릴레이리스트") {
      state.searchPath.append(.relayDetail(RelayDetailFeature.State(relayID: id)))
    } else if subtitle.hasPrefix("게시글") {
      state.searchPath.append(.postDetail(PostDetailFeature.State(postID: id)))
    } else {
      state.searchPath.append(.playlistDetail(PlaylistDetailFeature.State(playlistID: id)))
    }
  }
}
