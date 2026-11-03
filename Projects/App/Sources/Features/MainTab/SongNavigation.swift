import ComposableArchitecture
import Foundation

// REQ-066 — 곡 상세의 공유 → 곡 공유 카드(UI-3g), 시트를 닫은 뒤 이어 띄우는 화면

struct SongNavigation: Reducer {
  typealias State = MainTabFeature.State
  typealias Action = MainTabFeature.Action

  @Dependency(\.date.now)
  var now

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      if case let (source, .songDetail(.delegate(.share)))? = action.pathElement {
        guard let song = state[stack: source.tab][id: source.id, case: \.songDetail]?.song else { return .none }
        state.songShare = SongShareFeature.State(card: self.card(for: song, in: state))
        return .none
      }
      switch action {
      case .songShare(.presented(.delegate(.dismiss))):
        state.songShare = nil
        return .none

      case .songShare(.presented(.delegate(.shareAsPost))):
        // 게시글로 공유하기 → 이 곡을 담은 게시글 작성
        guard let card = state.songShare?.card else { return .none }
        state.songShare = nil
        state.followUpAfterSheet = .compose(ComposeTrack(id: card.songID, title: card.title, artist: card.artist))
        return .none

      case .sheetDismissed:
        guard let followUp = state.followUpAfterSheet else { return .none }
        state.followUpAfterSheet = nil
        switch followUp {
        case let .share(card): state.songShare = SongShareFeature.State(card: card)
        case let .compose(track): state.compose = ComposePostFeature.State(tracks: [track])
        }
        return .none

      default:
        return .none
      }
    }
  }

  /// 공유 카드 — 공유자는 마이 탭에서 불러온 프로필(없으면 공유 화면이 불러온다)
  func card(for song: SongDetail, in state: State) -> SongShareCard {
    self.card(songID: song.id, title: song.title, artist: song.artist, in: state)
  }

  func card(songID: String, title: String, artist: String, in state: State) -> SongShareCard {
    SongShareCard(
      songID: songID,
      title: title,
      artist: artist,
      sharerName: state.my.profile?.nickname,
      sharerPersona: state.my.profile?.persona?.name,
      today: self.now
    )
  }
}

/// 시트를 닫은 뒤 이어서 띄울 화면
enum SongFollowUp: Equatable {
  case share(SongShareCard)
  case compose(ComposeTrack)
}
