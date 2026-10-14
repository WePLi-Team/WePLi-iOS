import ComposableArchitecture
import Foundation

// REQ-060 · REQ-061 · REQ-063 · REQ-064 · REQ-081 — 커뮤니티 탭 이동: 알림 · 게시글 상세 · 게시글 작성 · 노래로 답하기

struct CommunityNavigation: Reducer {
  typealias State = MainTabFeature.State
  typealias Action = MainTabFeature.Action

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .community(.delegate(.showNotifications)):
        state.communityPath.append(.notifications(NotificationsFeature.State()))
        return .none

      case let .communityPath(.element(id: elementID, action: .notifications(.delegate(.dismiss)))):
        state.communityPath.pop(from: elementID)
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

      default:
        return .none
      }
    }
  }
}
