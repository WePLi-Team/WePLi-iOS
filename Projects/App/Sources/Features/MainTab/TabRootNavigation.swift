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
        state.relayPath.append(.relayDetail(RelayDetailFeature.State(relayID: id)))
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
    switch delegate {
    case .showNotifications:
      state.homePath.append(.notifications(NotificationsFeature.State()))
    case let .showRelay(id):
      state.homePath.append(.relayDetail(RelayDetailFeature.State(relayID: id)))
    case let .showSong(id):
      state.homePath.append(.songDetail(SongDetailFeature.State(songID: id)))
    case let .showMyRecommendation(relayID):
      state.homePath.append(.myRecommendation(MyRecommendationFeature.State(relayID: relayID)))
    case let .showArtist(name):
      state.homePath.append(.artist(ArtistFeature.State(artistID: name)))
    case let .showPost(id):
      state.homePath.append(.postDetail(PostDetailFeature.State(postID: id)))
    case let .showPlaylist(id):
      state.homePath.append(.playlistDetail(PlaylistDetailFeature.State(playlistID: id)))
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
    }
    return .none
  }

  /// 마이 메뉴 — 「내 활동」 세 메뉴는 보관함의 해당 세그먼트로(UI-5c 노트 01)
  private func openMyMenu(_ menu: MyMenu, _ state: inout State) {
    switch menu {
    case .myPlaylists: state.myPath.append(.library(LibraryFeature.State(segment: .playlists)))
    case .joinedRelays: state.myPath.append(.library(LibraryFeature.State(segment: .relays)))
    case .likesAndSaves: state.myPath.append(.library(LibraryFeature.State(segment: .likes)))
    case .notificationSettings: state.myPath.append(.notificationSettings(NotificationSettingsFeature.State()))
    // 원본에 화면이 없다(서비스 이용 가이드 · 공지 · 개발자 모드)
    case .serviceGuide, .noticesAndTerms, .developerMode: break
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
