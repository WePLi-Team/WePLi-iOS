import ComposableArchitecture
import Foundation

// REQ-079 · UI-13g · DEC-010 — 친구 프로필을 여는 곳과 프로필에서 여는 화면.
// 커뮤니티 글쓴이 · 친구 피드 · 검색 사용자 · 게시글 상세 글쓴이 → 친구 프로필(같은 탭 스택에 push)
// 프로필 「나와 취향 N% 일치」 → 취향 궁합(UI-6d) → 둘이서 플레이리스트 만들기(릴레이 만들기 UI-6a)
// 이미 신고함(UI-17d) 「내 문의 내역에서 보기」 → 고객센터(UI-7b) — 17a 내 문의 내역이 생기면 그 목록으로

struct ProfileNavigation: Reducer {
  typealias State = MainTabFeature.State
  typealias Action = MainTabFeature.Action
  typealias Path = MainTabFeature.Path

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      if let (tab, userID) = Self.rootProfile(action) {
        state[stack: tab].append(.friendProfile(FriendProfileFeature.State(userID: userID)))
        return .none
      }
      guard let (source, action) = action.pathElement else { return .none }
      switch action {
      case let .friendProfile(.delegate(.play(track))):
        return .send(.player(.play(queue: [track], startAt: 0, source: nil)))
      case let .friendProfile(.delegate(.showTasteMatch(userID))):
        // 이름은 프로필에서 받는다(취향 궁합 문구 「OO님과 …」)
        let name = state[stack: source.tab][id: source.id, case: \.friendProfile]?.profile?.name ?? ""
        state[stack: source.tab].append(.tasteMatch(TasteMatchFeature.State(userID: userID, name: name)))
        return .none
      case .tasteMatch(.delegate(.createRelay)):
        // 「둘이서 플레이리스트 만들기」 → 릴레이 만들기(UI-6a)
        state.createRelay = CreateRelayFeature.State()
        return .none
      default:
        break
      }
      if let next = Self.next(action) {
        state[stack: source.tab].append(next)
      }
      return .none
    }
  }

  /// 탭 첫 화면에서 연 프로필
  private static func rootProfile(_ action: Action) -> (MainTabFeature.Tab, String)? {
    switch action {
    case let .community(.delegate(.showProfile(id))), let .community(.friends(.delegate(.showProfile(id)))):
      (.community, id)
    case let .search(.delegate(.showUser(id))):
      (.search, id)
    default:
      nil
    }
  }

  /// 탭 스택 안에서 여는 화면 — 게시글 글쓴이 → 프로필, 프로필 → 게시글 · 플리 · 릴레이 · 가수
  private static func next(_ action: Path.Action) -> Path.State? {
    switch action {
    case let .postDetail(.delegate(.showProfile(id))):
      .friendProfile(FriendProfileFeature.State(userID: id))
    case let .friendProfile(.delegate(.showPost(id))):
      .postDetail(PostDetailFeature.State(postID: id))
    case let .friendProfile(.delegate(.showPlaylist(id))):
      .playlistDetail(PlaylistDetailFeature.State(playlistID: id))
    case let .friendProfile(.delegate(.showRelay(id))):
      .relayDetail(RelayDetailFeature.State(relayID: id))
    case let .friendProfile(.delegate(.showArtist(name))), let .tasteMatch(.delegate(.showArtist(name))):
      .artist(ArtistFeature.State(artistID: name))
    case .friendProfile(.delegate(.showInquiryHistory)):
      .helpCenter(HelpCenterFeature.State())
    default:
      nil
    }
  }
}
