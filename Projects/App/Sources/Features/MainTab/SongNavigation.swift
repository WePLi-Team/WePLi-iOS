import ComposableArchitecture
import Foundation

// REQ-023 · REQ-066 — 곡 상세(UI-2d)와 곡 공유 카드(UI-3g)로 가는 이동
// 지금은 검색 탭의 노래 결과에서 연다. 다른 탭의 곡 행은 각 기능 이슈에서 잇는다.

struct SongNavigation: Reducer {
  typealias State = MainTabFeature.State
  typealias Action = MainTabFeature.Action

  @Dependency(\.date.now)
  var now

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .search(.delegate(.showSong(id))):
        state.searchPath.append(.songDetail(SongDetailFeature.State(songID: id)))
        return .none

      case let .searchPath(.element(id: elementID, action: .songDetail(.delegate(.dismiss)))):
        state.searchPath.pop(from: elementID)
        return .none

      case let .searchPath(.element(id: elementID, action: .songDetail(.delegate(.share)))):
        guard let song = state.searchPath[id: elementID, case: \.songDetail]?.song else { return .none }
        state.songShare = SongShareFeature.State(card: SongShareCard(
          songID: song.id,
          title: song.title,
          artist: song.artist,
          sharerName: state.my.profile?.nickname,
          sharerPersona: state.my.profile?.persona?.name,
          today: self.now
        ))
        return .none

      case .songShare(.presented(.delegate(.dismiss))):
        state.songShare = nil
        return .none

      case .songShare(.presented(.delegate(.shareAsPost))):
        // 게시글로 공유하기 → 이 곡을 담은 게시글 작성
        guard let card = state.songShare?.card else { return .none }
        state.songShare = nil
        state.compose = ComposePostFeature.State(
          tracks: [ComposeTrack(id: card.songID, title: card.title, artist: card.artist)]
        )
        return .none

      default:
        return .none
      }
    }
  }
}
