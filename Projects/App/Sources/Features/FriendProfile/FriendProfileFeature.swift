import ComposableArchitecture
import Foundation

// REQ-079 · UI-13g · UI-17d · DEC-010 · DEC-020 · DEC-029 — 친구 프로필(push). 팔로우 · 차단 · 좋아요 · 초대는
// 먼저 반영하고 서버가 거절하면 되돌린다(DEC-004). 신고는 접수된 뒤에 안내하고, 같은 사람은 한 번만 신고한다.

@Reducer
struct FriendProfileFeature {
  @ObservableState
  struct State: Equatable {
    let userID: String
    var profile: FriendProfile?
    var loadFailed = false
    var tab: FriendProfileTab = .posts
    var isBlocked = false
    /// 지금 듣는 중 한 줄을 누르면 여는 메뉴(재생 · 내 플리에 담기)
    var isNowPlayingMenuOpen = false
    var isSongSaved = false
    var isInviteSent = false
    var overlay: FriendProfileOverlay?
    var reportReason: ReportReason?
    /// 「기타」 사유 — 200자까지, 적어야 보낼 수 있다
    var reportDetail = ""
    var isReporting = false
    var toast: String?

    /// 사유를 골랐고, 「기타」면 사유를 적었다
    var canSubmitReport: Bool {
      guard let reason = self.reportReason, !self.isReporting else { return false }
      return reason != .other || !self.reportDetail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(userID: String) {
      self.userID = userID
    }
  }

  enum Action: Equatable {
    case onAppear
    case loaded(FriendProfile)
    case loadFailed
    case retryButtonTapped
    case backButtonTapped
    case tabSelected(FriendProfileTab)
    case followTapped
    case nowPlayingTapped
    case nowPlayingMenuDismissed
    case playNowPlayingTapped
    case saveSongTapped
    case inviteTapped
    case tasteMatchTapped
    case postLikeTapped(FriendPost.ID)
    case postTapped(FriendPost.ID)
    case playlistTapped(FriendPlaylist.ID)
    case relayTapped(FriendRelay.ID)
    case recentTapped(FriendRecentTrack.ID)
    case artistTapped(String)
    case menu(FriendProfileMenuAction)
    case rollback(FriendProfileRollback)
    case toastDismissed
    case delegate(FriendProfileDelegate)
  }

  @Dependency(\.friendProfileClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.profile == nil else { return .none }
        return self.load(&state)
      case let .loaded(profile):
        state.profile = profile
        return .none
      case .loadFailed:
        state.loadFailed = true
        return .none
      case .retryButtonTapped:
        return self.load(&state)
      case .backButtonTapped:
        return .send(.delegate(.dismiss))
      case let .menu(action):
        return self.menu(action, &state)
      case let .rollback(rollback):
        Self.apply(rollback, &state)
        return .none
      default:
        return self.local(action, &state) ?? self.social(action, &state) ?? self.open(action, state)
      }
    }
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.loadFailed = false
    let userID = state.userID
    return .run { send in
      do {
        try await send(.loaded(self.client.fetch(userID)))
      } catch {
        await send(.loadFailed)
      }
    }
  }

  /// 다른 화면으로 — 곡 · 게시글 · 플리 · 릴레이 · 가수 · 취향 궁합
  private func open(_ action: Action, _ state: State) -> Effect<Action> {
    guard let profile = state.profile else { return .none }
    switch action {
    case .tasteMatchTapped:
      guard profile.visibleTasteMatch != nil else { return .none }
      return .send(.delegate(.showTasteMatch(userID: profile.id)))
    case let .postTapped(id):
      return .send(.delegate(.showPost(id)))
    case let .playlistTapped(id):
      return .send(.delegate(.showPlaylist(id)))
    case let .relayTapped(id):
      return .send(.delegate(.showRelay(id)))
    case let .recentTapped(id):
      guard let track = profile.recent.first(where: { $0.id == id }) else { return .none }
      return .send(.delegate(.play(PlayerTrack(id: track.id, title: track.title, artist: track.artist))))
    case let .artistTapped(name):
      return .send(.delegate(.showArtist(name)))
    default:
      return .none
    }
  }
}

/// ··· 메뉴 · 차단 · 신고
enum FriendProfileMenuAction: Equatable {
  case moreTapped
  /// 메뉴 · 신고 시트를 닫았다 — 차단 확인 창으로 넘어가는 중이면 그대로 둔다
  case dismissed
  case blockCancelled
  case copyLinkTapped
  case blockTapped
  case blockConfirmed
  case unblockTapped
  case reportTapped
  case reasonSelected(ReportReason)
  case reportDetailChanged(String)
  case reportSubmitted
  case reported(FriendReport)
  /// 접수 안내 · 이미 신고함 시트의 「{이름} 님 차단하기」 → 차단 확인 창
  case reportBlockTapped
  /// 「내 문의 내역에서 보기」
  case reportHistoryTapped
}

/// 서버가 거절했을 때 되돌릴 값
enum FriendProfileRollback: Equatable {
  case follow(isFollowing: Bool, followerCount: Int)
  case blocked(isBlocked: Bool, profile: FriendProfile?)
  case postLike(FriendPost)
  case invite
  case saveSong
  case report
}

enum FriendProfileDelegate: Equatable {
  case dismiss
  case showTasteMatch(userID: String)
  case showPost(String)
  case showPlaylist(String)
  case showRelay(String)
  case showArtist(String)
  case play(PlayerTrack)
  /// 신고 결과는 내 문의 내역(UI-17a)으로 온다
  case showInquiryHistory
}
