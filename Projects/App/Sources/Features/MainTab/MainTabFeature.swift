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
    var relay = RelayListFeature.State()
    var my = MyFeature.State()
    var community = CommunityFeedFeature.State()
    var search = SearchFeature.State()
    /// 릴레이 탭 화면 이동(DEC-007)
    var relayPath = StackState<RelayPath.State>()
    /// 커뮤니티 탭 화면 이동(DEC-007)
    var communityPath = StackState<CommunityPath.State>()
    /// 마이 탭 화면 이동(DEC-007)
    var myPath = StackState<MyPath.State>()
    /// 검색 탭 화면 이동(DEC-007)
    var searchPath = StackState<SearchPath.State>()
    /// 게시글 작성(UI-2b) — 큰 시트
    @Presents var compose: ComposePostFeature.State?
    /// 「노래로 답하기」 곡 검색 시트(UI-2a)와 곡을 받을 게시글 상세
    @Presents var replySongPicker: SongPickerFeature.State?
    var replySongTarget: StackElementID?
    /// 곡 공유 카드(UI-3g) — 전체 화면
    @Presents var songShare: SongShareFeature.State?

    /// 하위 화면에서는 탭 바를 숨긴다 — 원본 3c · 3b · 4d는 탭 바 없는 push 화면이다
    var hidesTabBar: Bool {
      switch self.selectedTab {
      case .relay: !self.relayPath.isEmpty
      case .community: !self.communityPath.isEmpty
      case .my: !self.myPath.isEmpty
      case .search: !self.searchPath.isEmpty
      case .home: false
      }
    }
  }

  /// 릴레이 탭에서 push되는 화면
  @Reducer(state: .equatable, action: .equatable)
  enum RelayPath {
    case detail(RelayDetailFeature)
    case vote(CardVoteFeature)
  }

  /// 커뮤니티 탭에서 push되는 화면
  @Reducer(state: .equatable, action: .equatable)
  enum CommunityPath {
    case notifications(NotificationsFeature)
    case postDetail(PostDetailFeature)
  }

  /// 마이 탭에서 push되는 화면
  @Reducer(state: .equatable, action: .equatable)
  enum MyPath {
    case editProfile(EditProfileFeature)
    case library(LibraryFeature)
    case vote(CardVoteFeature)
  }

  /// 검색 탭에서 push되는 화면
  @Reducer(state: .equatable, action: .equatable)
  enum SearchPath {
    case songDetail(SongDetailFeature)
  }

  enum Action: Equatable {
    case tabSelected(Tab)
    case relay(RelayListFeature.Action)
    case my(MyFeature.Action)
    case community(CommunityFeedFeature.Action)
    case search(SearchFeature.Action)
    case relayPath(StackActionOf<RelayPath>)
    case communityPath(StackActionOf<CommunityPath>)
    case myPath(StackActionOf<MyPath>)
    case searchPath(StackActionOf<SearchPath>)
    case songShare(PresentationAction<SongShareFeature.Action>)
    case compose(PresentationAction<ComposePostFeature.Action>)
    case replySongPicker(PresentationAction<SongPickerFeature.Action>)
  }

  var body: some ReducerOf<Self> {
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

    // 하위 화면 reducer(forEach · ifLet)보다 먼저 돌아야 해서 같은 묶음에 넣는다
    CombineReducers {
      SongNavigation()

      Reduce { state, action in
        switch action {
        case let .tabSelected(tab):
          state.selectedTab = tab
          return .none

        case .search(.delegate(.showHome)):
          state.selectedTab = .home
          return .none

        case let .relay(.delegate(.showRelay(id))):
          state.relayPath.append(.detail(RelayDetailFeature.State(relayID: id)))
          return .none

        case let .relayPath(.element(id: elementID, action: .detail(.delegate(.showVote(relayID))))):
          // 상세 제목은 줄바꿈이 있어 투표 화면 주제에서는 한 줄로 보인다
          let title = state.relayPath[id: elementID, case: \.detail]?.detail?.title ?? ""
          let topic = title.replacingOccurrences(of: "\n", with: " ")
          state.relayPath.append(.vote(CardVoteFeature.State(relayID: relayID, topic: topic)))
          return .none

        case let .relayPath(.element(id: elementID, action: .detail(.delegate(.dismiss)))),
             let .relayPath(.element(id: elementID, action: .vote(.delegate(.dismiss)))):
          state.relayPath.pop(from: elementID)
          return .none

        case .community(.delegate(.showNotifications)):
          state.communityPath.append(.notifications(NotificationsFeature.State()))
          return .none

        case let .communityPath(.element(id: elementID, action: .notifications(.delegate(.dismiss)))):
          state.communityPath.pop(from: elementID)
          return .none

        case .my(.delegate(.editProfile)):
          guard let profile = state.my.profile else { return .none }
          state.myPath.append(.editProfile(EditProfileFeature.State(profile: profile)))
          return .none

        case let .myPath(.element(id: _, action: .editProfile(.delegate(.profileUpdated(profile))))):
          // 저장하면 마이 탭 프로필 카드에 바로 반영한다
          state.my.profile = profile
          return .none

        case let .myPath(.element(id: elementID, action: .editProfile(.delegate(.dismiss)))),
             let .myPath(.element(id: elementID, action: .library(.delegate(.dismiss)))),
             let .myPath(.element(id: elementID, action: .vote(.delegate(.dismiss)))):
          state.myPath.pop(from: elementID)
          return .none

        case let .my(.delegate(.show(menu))):
          // 마이의 「내 활동」 세 메뉴는 보관함의 해당 세그먼트로(UI-5c 노트 01)
          let segment: LibrarySegment? = switch menu {
          case .myPlaylists: .playlists
          case .joinedRelays: .relays
          case .likesAndSaves: .likes
          case .notificationSettings, .serviceGuide, .noticesAndTerms, .developerMode: nil
          }
          guard let segment else { return .none }
          state.myPath.append(.library(LibraryFeature.State(segment: segment)))
          return .none

        case let .myPath(.element(id: elementID, action: .library(.delegate(.continueVoting(relayID))))):
          let topic = state.myPath[id: elementID, case: \.library]?.library?.liveRelays
            .first { $0.id == relayID }?.title ?? ""
          state.myPath.append(.vote(CardVoteFeature.State(relayID: relayID, topic: topic)))
          return .none

        case .community(.delegate(.showCompose)):
          state.compose = ComposePostFeature.State()
          return .none

        case .compose(.presented(.delegate(.dismiss))):
          state.compose = nil
          return .none

        case .compose(.presented(.delegate(.published))):
          // 올리면 시트를 닫고 피드를 새로 불러온다
          state.compose = nil
          state.community.hasLoaded = false
          return .send(.community(.onAppear))

        case let .community(.delegate(.showPost(id))):
          state.communityPath.append(.postDetail(PostDetailFeature.State(postID: id)))
          return .none

        case let .communityPath(.element(id: elementID, action: .postDetail(.delegate(.dismiss)))):
          state.communityPath.pop(from: elementID)
          return .none

        case let .communityPath(.element(id: elementID, action: .postDetail(.delegate(.pickReplySong)))):
          state.replySongTarget = elementID
          state.replySongPicker = SongPickerFeature.State()
          return .none

        case let .replySongPicker(.presented(.delegate(.add(tracks)))):
          // 댓글에는 한 곡만 붙인다 — 처음 고른 곡
          state.replySongPicker = nil
          guard let track = tracks.first, let target = state.replySongTarget else { return .none }
          state.replySongTarget = nil
          let song = Track(title: track.title, artist: track.artist)
          return .send(.communityPath(.element(id: target, action: .postDetail(.replySongPicked(song)))))

        case .replySongPicker(.presented(.delegate(.dismiss))):
          state.replySongPicker = nil
          state.replySongTarget = nil
          return .none

        case .relay, .my, .community, .search, .relayPath, .communityPath, .myPath, .compose, .replySongPicker,
             .searchPath, .songShare:
          return .none
        }
      }
    }
    .forEach(\.relayPath, action: \.relayPath)
    .forEach(\.communityPath, action: \.communityPath)
    .forEach(\.myPath, action: \.myPath)
    .forEach(\.searchPath, action: \.searchPath)
    .ifLet(\.$compose, action: \.compose) {
      ComposePostFeature()
    }
    .ifLet(\.$replySongPicker, action: \.replySongPicker) {
      SongPickerFeature()
    }
    .ifLet(\.$songShare, action: \.songShare) {
      SongShareFeature()
    }
  }
}
