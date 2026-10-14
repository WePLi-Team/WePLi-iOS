import ComposableArchitecture
import Foundation

// REQ-023 · UI-1b 곡 메뉴 시트 — 곡 상세 ··· 에서 열고, 행마다 목적지로 잇는다
// 아티스트 정보 보기 → 아티스트(UI-5b) · 인스타그램 · 스크린샷 → 공유 카드(UI-3g, 원본 노트 03) · 게시글로 공유하기 → 게시글 작성

struct SongMenuNavigation: Reducer {
  typealias State = MainTabFeature.State
  typealias Action = MainTabFeature.Action
  typealias Path = MainTabFeature.Path

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      if let (source, pathAction) = action.pathElement {
        return self.fromDetail(pathAction, source, &state)
      }
      switch action {
      case .songMenu(.presented(.delegate(.toggleLike))):
        guard let source = state.songMenuSource else { return .none }
        return .send(.path(source, .songDetail(.likeButtonTapped)))

      case .songMenu(.presented(.delegate(.dismiss))):
        self.close(&state)
        return .none

      case let .songMenu(.presented(.delegate(.selected(item)))):
        return self.route(item, &state)

      default:
        return .none
      }
    }
  }

  /// 곡 상세 ··· → 시트, 곡 상세가 좋아요를 되돌리면 열린 시트도 맞춘다
  private func fromDetail(_ action: Path.Action, _ source: PathSource, _ state: inout State) -> Effect<Action> {
    switch action {
    case .songDetail(.delegate(.more)):
      guard let song = state[stack: source.tab][id: source.id, case: \.songDetail]?.song else { return .none }
      state.songMenuSource = source
      state.songMenu = SongMenuFeature.State(
        songID: song.id,
        title: song.title,
        artist: song.artist,
        isLiked: song.isLiked
      )
    case let .songDetail(.likeFailed(restore)) where source == state.songMenuSource:
      state.songMenu?.isLiked = restore
    default:
      break
    }
    return .none
  }

  private func route(_ item: SongMenuItem, _ state: inout State) -> Effect<Action> {
    guard let source = state.songMenuSource,
          let song = state[stack: source.tab][id: source.id, case: \.songDetail]?.song
    else { return .none }
    switch item {
    case .artist:
      self.close(&state)
      state[stack: source.tab].append(.artist(ArtistFeature.State(artistID: song.artist)))
      return .none

    case .instagram, .screenshot:
      let card = SongNavigation().card(for: song, in: state)
      self.close(&state)
      return SongNavigation().presentAfterSheet(.share(card))

    case .shareAsPost:
      self.close(&state)
      return SongNavigation().presentAfterSheet(.compose(ComposeTrack(
        id: song.id,
        title: song.title,
        artist: song.artist
      )))

    case .info:
      // 이미 곡 상세에서 연 시트라 닫기만 한다
      self.close(&state)
      return .none

    // 원본에 목적지 화면이 없다(가사 · 플리 추가) — 화면이 생기면 잇는다. 링크는 시트가 처리한다.
    case .lyrics, .addToPlaylist, .link:
      return .none
    }
  }

  private func close(_ state: inout State) {
    state.songMenu = nil
    state.songMenuSource = nil
  }
}
