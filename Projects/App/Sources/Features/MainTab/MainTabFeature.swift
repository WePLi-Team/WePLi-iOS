import ComposableArchitecture
import Foundation

// REQ-001 · UI-12d — 메인 탭: 홈 · 릴레이 · 커뮤니티 · 마이 + 검색

@Reducer
struct MainTabFeature {
  enum Tab: String, CaseIterable, Equatable {
    case home
    case relay
    case community
    case my
    case search

    /// iOS 26 글래스 캡슐에 들어가는 탭(검색은 따로 떠 있는 원형 버튼)
    static let capsuleTabs: [Tab] = [.home, .relay, .community, .my]

    var title: String {
      switch self {
      case .home: "홈"
      case .relay: "릴레이"
      case .community: "커뮤니티"
      case .my: "마이"
      case .search: "검색"
      }
    }

    /// Figma 아이콘(home · stars · message · profile · search)에 가까운 SF Symbol
    var systemImage: String {
      switch self {
      case .home: "house"
      case .relay: "sparkles"
      case .community: "bubble.left"
      case .my: "person"
      case .search: "magnifyingglass"
      }
    }
  }

  @ObservableState
  struct State: Equatable {
    var selectedTab: Tab = .home
    var home = HomeFeature.State()
    var relay = RelayListFeature.State()
    var my = MyFeature.State()
    var community = CommunityFeedFeature.State()
    var search = SearchFeature.State()
    /// 홈 탭 화면 이동(DEC-007)
    var homePath = StackState<Path.State>()
    /// 릴레이 탭 화면 이동(DEC-007)
    var relayPath = StackState<Path.State>()
    /// 커뮤니티 탭 화면 이동(DEC-007)
    var communityPath = StackState<Path.State>()
    /// 마이 탭 화면 이동(DEC-007)
    var myPath = StackState<Path.State>()
    /// 검색 탭 화면 이동(DEC-007)
    var searchPath = StackState<Path.State>()
    /// 게시글 작성(UI-2b) — 큰 시트
    @Presents var compose: ComposePostFeature.State?
    /// 「노래로 답하기」 곡 검색 시트(UI-2a)와 곡을 받을 게시글 상세
    @Presents var replySongPicker: SongPickerFeature.State?
    var replySongTarget: PathSource?
    /// 곡 공유 카드(UI-3g) — 전체 화면
    @Presents var songShare: SongShareFeature.State?
    /// 곡 메뉴 시트(UI-1b)와 시트를 연 곡 상세
    @Presents var songMenu: SongMenuFeature.State?
    /// 명함 만들기(UI-2e) — 전체 화면
    @Presents var businessCard: BusinessCardFeature.State?
    /// 서비스 이용 가이드(UI-7f) — 전체 화면
    @Presents var serviceGuide: ServiceGuideFeature.State?
    /// 릴레이리스트 만들기(UI-6a) — 시트
    @Presents var createRelay: CreateRelayFeature.State?
    /// 내 음악 앱으로 내보내기(UI-14c–14o) — 시트
    @Presents var exportFlow: ExportFlowFeature.State?
    /// 미리듣기 플레이어 — 미니 플레이어(UI-4a)와 지금 재생 중(UI-4b)이 함께 쓴다
    var player = PlayerFeature.State()
    /// 진행 중 릴레이 먼저 담기(UI-14l) — 시트와 시트를 연 릴레이 상세
    @Presents var liveExport: LiveExportFeature.State?
    var liveExportSource: PathSource?
    var songMenuSource: PathSource?

    /// 하위 화면에서는 탭 바를 숨긴다 — 원본 3c · 3b · 4d는 탭 바 없는 push 화면이다
    var hidesTabBar: Bool {
      switch self.selectedTab {
      case .relay: !self.relayPath.isEmpty
      case .community: !self.communityPath.isEmpty
      case .my: !self.myPath.isEmpty
      case .search: !self.searchPath.isEmpty
      case .home: !self.homePath.isEmpty
      }
    }
  }

  /// 탭에서 push되는 화면 — 모든 탭이 같은 목록을 쓰고, 스택은 탭마다 따로 둔다(DEC-007)
  @Reducer(state: .equatable, action: .equatable)
  enum Path {
    case relayDetail(RelayDetailFeature)
    case vote(CardVoteFeature)
    case worldCup(SongWorldCupFeature)
    case batonRelay(BatonRelayFeature)
    case liveTrend(LiveTrendFeature)
    case myRecommendation(MyRecommendationFeature)
    case topPrediction(TopPredictionFeature)
    case completedPlaylist(CompletedPlaylistFeature)
    case exportedPlaylist(ExportedPlaylistFeature)
    case notifications(NotificationsFeature)
    case postDetail(PostDetailFeature)
    case editProfile(EditProfileFeature)
    case library(LibraryFeature)
    case notificationSettings(NotificationSettingsFeature)
    case musicServices(MusicServicesFeature)
    case notices(NoticesFeature)
    case appInfo(AppInfoFeature)
    case myPlaylist(MyPlaylistFeature)
    case songDetail(SongDetailFeature)
    case artist(ArtistFeature)
    case playlistDetail(PlaylistDetailFeature)
  }

  enum Action: Equatable {
    case tabSelected(Tab)
    case home(HomeFeature.Action)
    case relay(RelayListFeature.Action)
    case my(MyFeature.Action)
    case community(CommunityFeedFeature.Action)
    case search(SearchFeature.Action)
    case homePath(StackActionOf<Path>)
    case relayPath(StackActionOf<Path>)
    case communityPath(StackActionOf<Path>)
    case myPath(StackActionOf<Path>)
    case searchPath(StackActionOf<Path>)
    case songShare(PresentationAction<SongShareFeature.Action>)
    case songMenu(PresentationAction<SongMenuFeature.Action>)
    case businessCard(PresentationAction<BusinessCardFeature.Action>)
    case serviceGuide(PresentationAction<ServiceGuideFeature.Action>)
    case createRelay(PresentationAction<CreateRelayFeature.Action>)
    case exportFlow(PresentationAction<ExportFlowFeature.Action>)
    case liveExport(PresentationAction<LiveExportFeature.Action>)
    case player(PlayerFeature.Action)
    /// 시트가 닫히는 동안 다음 화면을 띄우면 무시되므로 잠시 뒤에 띄운다
    case presentAfterSheet(SongFollowUp)
    case compose(PresentationAction<ComposePostFeature.Action>)
    case replySongPicker(PresentationAction<SongPickerFeature.Action>)
  }

  var body: some ReducerOf<Self> {
    self.navigation
      .ifLet(\.$compose, action: \.compose) {
        ComposePostFeature()
      }
      .ifLet(\.$replySongPicker, action: \.replySongPicker) {
        SongPickerFeature()
      }
      .ifLet(\.$songShare, action: \.songShare) {
        SongShareFeature()
      }
      .ifLet(\.$songMenu, action: \.songMenu) {
        SongMenuFeature()
      }
      .ifLet(\.$businessCard, action: \.businessCard) {
        BusinessCardFeature()
      }
      .ifLet(\.$serviceGuide, action: \.serviceGuide) {
        ServiceGuideFeature()
      }
      .ifLet(\.$createRelay, action: \.createRelay) {
        CreateRelayFeature()
      }
      .ifLet(\.$exportFlow, action: \.exportFlow) {
        ExportFlowFeature()
      }
      .ifLet(\.$liveExport, action: \.liveExport) {
        LiveExportFeature()
      }
  }

  /// 탭 화면 · 탭별 이동. Xcode 16.2가 한 식으로는 타입을 제때 못 맞춰 탭마다 reducer를 나눈다.
  private var navigation: some ReducerOf<Self> {
    CombineReducers {
      self.tabs
      // 하위 화면 reducer(forEach · ifLet)보다 먼저 돌아야 해서 같은 묶음에 넣는다
      CombineReducers {
        TabRootNavigation()
        SheetNavigation()
        ContentNavigation()
        SongNavigation()
        SongMenuNavigation()
        PlaybackNavigation()
        Reduce { state, action in
          switch action {
          case let .tabSelected(tab):
            state.selectedTab = tab
            return .none

          case .search(.delegate(.showHome)):
            state.selectedTab = .home
            return .none

          default:
            return .none
          }
        }
      }
      .forEach(\.homePath, action: \.homePath)
      .forEach(\.relayPath, action: \.relayPath)
      .forEach(\.communityPath, action: \.communityPath)
      .forEach(\.myPath, action: \.myPath)
      .forEach(\.searchPath, action: \.searchPath)
    }
  }

  private var tabs: some ReducerOf<Self> {
    CombineReducers {
      Scope(state: \.home, action: \.home) {
        HomeFeature()
      }
      Scope(state: \.relay, action: \.relay) {
        RelayListFeature()
      }
      Scope(state: \.my, action: \.my) {
        MyFeature()
      }
      Scope(state: \.community, action: \.community) {
        CommunityFeedFeature()
      }
      Scope(state: \.search, action: \.search) {
        SearchFeature()
      }
      Scope(state: \.player, action: \.player) {
        PlayerFeature()
      }
    }
  }
}
