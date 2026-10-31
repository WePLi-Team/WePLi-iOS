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
    /// 한 번이라도 고른 탭 — 고른 적 없는 탭은 그리지 않아 앱 시작 때 모든 탭이 불러오지 않는다
    var visitedTabs: Set<Tab> = []
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
    /// 지금 듣는 음악 — 연결과 공개 범위(UI-13a) · 전체 화면
    @Presents var listeningShare: ListeningShareFeature.State?
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
    /// 「먼저 둘러볼게요」로 들어온 손님(DEC-032) — 계정이 있어야 하는 동작은 로그인을 요청한다
    var isGuest = false
    /// 손님이 투표 · 추천 등을 눌렀을 때 띄우는 로그인 요청 시트
    var loginPrompt: GuestPromptReason?

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
  @Reducer
  enum Path {
    case relayDetail(RelayDetailFeature)
    case vote(CardVoteFeature)
    case worldCup(SongWorldCupFeature)
    case batonRelay(BatonRelayFeature)
    case liveTrend(LiveTrendFeature)
    case dailySong(DailySongFeature)
    case myRecommendation(MyRecommendationFeature)
    case topPrediction(TopPredictionFeature)
    case seasonRanking(SeasonRankingFeature)
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
    case helpCenter(HelpCenterFeature)
    case inquiryHistory(InquiryHistoryFeature)
    case inquiryDetail(InquiryDetailFeature)
    case myPlaylist(MyPlaylistFeature)
    case songDetail(SongDetailFeature)
    case artist(ArtistFeature)
    case playlistDetail(PlaylistDetailFeature)
    case friendProfile(FriendProfileFeature)
    case tasteMatch(TasteMatchFeature)
    case communityPolicy(CommunityPolicyFeature)
    case hiddenPost(HiddenPostFeature)
    case accountManagement(AccountManagementFeature)
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
    case listeningShare(PresentationAction<ListeningShareFeature.Action>)
    case createRelay(PresentationAction<CreateRelayFeature.Action>)
    case exportFlow(PresentationAction<ExportFlowFeature.Action>)
    case liveExport(PresentationAction<LiveExportFeature.Action>)
    case player(PlayerFeature.Action)
    /// 시트가 닫히는 동안 다음 화면을 띄우면 무시되므로 잠시 뒤에 띄운다
    case presentAfterSheet(SongFollowUp)
    case compose(PresentationAction<ComposePostFeature.Action>)
    case replySongPicker(PresentationAction<SongPickerFeature.Action>)
    /// 로그인 요청 시트 「계속 둘러보기」 · 닫기
    case loginPromptDismissed
    /// 로그인 요청 시트 · 마이 탭 손님 화면의 「로그인하기」
    case guestLoginTapped
    case delegate(MainTabDelegate)
  }

  var body: some ReducerOf<Self> {
    GuestGate(base: self.navigation)
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
      .ifLet(\.$listeningShare, action: \.listeningShare) {
        ListeningShareFeature()
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
        ProfileNavigation()
        InquiryNavigation()
        Reduce { state, action in
          switch action {
          case let .tabSelected(tab):
            Self.select(tab, &state)

          case .search(.delegate(.showHome)):
            Self.select(.home, &state)

          default:
            .none
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

extension MainTabFeature {
  /// 탭 바꾸기 — 탭은 겹쳐 두고 숨기기만 해서 숨긴 탭은 onDisappear가 불리지 않는다.
  /// 홈의 실시간 타이머는 여기서 멈추고, 돌아오면(위에 push된 화면이 없을 때) 다시 켠다.
  static func select(_ tab: Tab, _ state: inout State) -> Effect<Action> {
    let previous = state.selectedTab
    guard tab != previous else { return .none }
    state.visitedTabs.insert(previous)
    let isReturning = state.visitedTabs.contains(tab)
    state.selectedTab = tab
    if previous == .home {
      return .send(.home(.onDisappear))
    }
    if tab == .home, isReturning, state.homePath.isEmpty {
      return .send(.home(.onAppear))
    }
    return .none
  }
}

enum MainTabDelegate: Equatable {
  /// 탈퇴 신청 뒤 로그아웃(UI-7c) — 앱 루트가 로그인 화면으로 돌아간다
  case signedOut
  /// 손님이 「로그인하기」를 눌렀을 때 — 앱 루트가 로그인 화면으로 보낸다(DEC-032)
  case loginRequested
}

extension MainTabFeature.Path.State: Equatable {}
extension MainTabFeature.Path.Action: Equatable {}
