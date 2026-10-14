import ComposableArchitecture
import Foundation

// REQ-061 · REQ-064 · REQ-075 — 탭 위에 뜨는 시트 · 전체 화면: 게시글 작성 · 노래로 답하기 곡 검색 · 명함 만들기

struct SheetNavigation: Reducer {
  typealias State = MainTabFeature.State
  typealias Action = MainTabFeature.Action

  @Dependency(\.date.now)
  var now

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
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

      case let .replySongPicker(.presented(.delegate(.add(tracks)))):
        // 댓글에는 한 곡만 붙인다 — 처음 고른 곡
        state.replySongPicker = nil
        guard let track = tracks.first, let target = state.replySongTarget else { return .none }
        state.replySongTarget = nil
        let song = Track(title: track.title, artist: track.artist)
        return .send(.path(target, .postDetail(.replySongPicked(song))))

      case .replySongPicker(.presented(.delegate(.dismiss))):
        state.replySongPicker = nil
        state.replySongTarget = nil
        return .none

      case .my(.delegate(.showBusinessCard)):
        // 미결정 — 명함이 이미 있으면 내 명함(UI-11e)으로 보낸다(11e 노트). 11e가 없어 지금은 늘 만들기로 연다.
        state.businessCard = BusinessCardFeature.State(
          nickname: state.my.profile?.nickname ?? "",
          persona: state.my.profile?.persona?.name,
          today: self.now
        )
        return .none

      case .businessCard(.presented(.delegate(.dismiss))):
        state.businessCard = nil
        return .none

      default:
        return .none
      }
    }
  }
}
