import ComposableArchitecture
import Foundation

// REQ-023 · REQ-024 · REQ-066 — 곡 상세(UI-2d) · 아티스트(UI-5b) · 곡 공유 카드(UI-3g)로 가는 이동
// 지금은 검색 탭의 노래 결과에서 연다. 다른 탭의 곡 행은 각 기능 이슈에서 잇는다.

struct SongNavigation: Reducer {
  typealias State = MainTabFeature.State
  typealias Action = MainTabFeature.Action

  @Dependency(\.date.now)
  var now

  @Dependency(\.continuousClock)
  var clock

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .search(.delegate(.showSong(id))):
        state.searchPath.append(.songDetail(SongDetailFeature.State(songID: id)))
        return .none

      case let .searchPath(.element(id: elementID, action: .songDetail(.delegate(.showArtist)))):
        // 곡 상세의 가수 이름 → 아티스트(원본 노트 01)
        guard let artist = state.searchPath[id: elementID, case: \.songDetail]?.song?.artist else { return .none }
        state.searchPath.append(.artist(ArtistFeature.State(artistID: artist)))
        return .none

      case let .searchPath(.element(id: _, action: .artist(.delegate(.showArtist(name))))):
        state.searchPath.append(.artist(ArtistFeature.State(artistID: name)))
        return .none

      case let .searchPath(.element(id: _, action: .artist(.delegate(.showSong(songID))))):
        state.searchPath.append(.songDetail(SongDetailFeature.State(songID: songID)))
        return .none

      case let .searchPath(.element(id: elementID, action: .artist(.delegate(.dismiss)))),
           let .searchPath(.element(id: elementID, action: .songDetail(.delegate(.dismiss)))):
        state.searchPath.pop(from: elementID)
        return .none

      case let .searchPath(.element(id: elementID, action: .songDetail(.delegate(.share)))):
        guard let song = state.searchPath[id: elementID, case: \.songDetail]?.song else { return .none }
        state.songShare = SongShareFeature.State(card: self.card(for: song, in: state))
        return .none

      case .songShare(.presented(.delegate(.dismiss))):
        state.songShare = nil
        return .none

      case .songShare(.presented(.delegate(.shareAsPost))):
        // 게시글로 공유하기 → 이 곡을 담은 게시글 작성
        guard let card = state.songShare?.card else { return .none }
        state.songShare = nil
        return self.presentAfterSheet(.compose(ComposeTrack(id: card.songID, title: card.title, artist: card.artist)))

      case let .presentAfterSheet(.share(card)):
        state.songShare = SongShareFeature.State(card: card)
        return .none

      case let .presentAfterSheet(.compose(track)):
        state.compose = ComposePostFeature.State(tracks: [track])
        return .none

      default:
        return .none
      }
    }
  }

  /// 공유 카드 — 공유자는 마이 탭에서 불러온 프로필(없으면 공유 화면이 불러온다)
  func card(for song: SongDetail, in state: State) -> SongShareCard {
    SongShareCard(
      songID: song.id,
      title: song.title,
      artist: song.artist,
      sharerName: state.my.profile?.nickname,
      sharerPersona: state.my.profile?.persona?.name,
      today: self.now
    )
  }

  func presentAfterSheet(_ followUp: SongFollowUp) -> Effect<Action> {
    .run { send in
      try await self.clock.sleep(for: .milliseconds(450))
      await send(.presentAfterSheet(followUp))
    }
  }
}

/// 시트를 닫은 뒤 이어서 띄울 화면
enum SongFollowUp: Equatable {
  case share(SongShareCard)
  case compose(ComposeTrack)
}
