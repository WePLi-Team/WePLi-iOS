import ComposableArchitecture
import Foundation

// REQ-023 · REQ-022 · UI-2d v2 · DEC-004 — 곡 상세

@Reducer
struct SongDetailFeature {
  @ObservableState
  struct State: Equatable {
    let songID: String
    var song: SongDetail?
    var loadFailed = false
    var isPlaying = false
    /// 미리듣기 위치(초, 0–30)
    var position = 0

    init(songID: String, song: SongDetail? = nil) {
      self.songID = songID
      self.song = song
    }
  }

  enum Action: Equatable {
    case onAppear
    case onDisappear
    case loaded(SongDetail)
    case loadFailed
    case retryButtonTapped
    case previewButtonTapped
    case previewTicked
    case likeButtonTapped
    case likeFailed(restore: Bool)
    case backButtonTapped
    case shareButtonTapped
    case moreButtonTapped
    case artistTapped
    case albumTapped
    case commentsTapped
    case addToPlaylistTapped
    case recommendTapped
    case openInMusicTapped
    case relayTapped(SongDetail.Relay.ID)
    case relatedSongTapped(SongDetail.RelatedSong.ID)
    case relatedPlayTapped(SongDetail.RelatedSong.ID)
    case otherAlbumTapped(SongDetail.OtherAlbum.ID)
    case delegate(Delegate)
  }

  enum Delegate: Equatable {
    case dismiss
    case share(songID: String)
    case more(songID: String)
    /// 아티스트 (UI-5b)
    case showArtist
    case showAlbum
    case showComments(songID: String)
    /// 곡 추가 시트 (UI-9e)
    case addToPlaylist(songID: String)
    /// 「릴레이에 추천」(2d v2) — 원본에 다음 화면이 없어 목적지 미결정
    case recommendToRelay(songID: String)
    /// 이 곡이 올라간 릴레이 → 릴레이 상세(UI-3c)
    case showRelay(SongDetail.Relay.ID)
    /// 함께 들으면 좋은 곡의 재생 아이콘 → 미리듣기 플레이어(UI-4b)
    case playRelated(SongDetail.RelatedSong.ID)
    /// Apple Music 앱에서 전체 곡 듣기
    case openInMusic(songID: String)
    case showSong(SongDetail.RelatedSong.ID)
    case showOtherAlbum(SongDetail.OtherAlbum.ID)
  }

  private enum CancelID {
    case preview
  }

  @Dependency(\.songDetailClient)
  var client

  @Dependency(\.continuousClock)
  var clock

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.song == nil else { return .none }
        return self.load(&state)

      case .onDisappear:
        state.isPlaying = false
        return .cancel(id: CancelID.preview)

      case let .loaded(song):
        state.song = song
        return .none

      case .loadFailed:
        state.loadFailed = true
        return .none

      case .retryButtonTapped:
        return self.load(&state)

      case .previewButtonTapped:
        // 일시정지하면 위치를 그대로 두고, 다시 누르면 이어서 듣는다
        if state.isPlaying {
          state.isPlaying = false
          return .cancel(id: CancelID.preview)
        }
        state.isPlaying = true
        return .run { send in
          for await _ in self.clock.timer(interval: .seconds(1)) {
            await send(.previewTicked)
          }
        }
        .cancellable(id: CancelID.preview, cancelInFlight: true)

      case .previewTicked:
        state.position += 1
        guard state.position >= SongPreview.length else { return .none }
        // 30초가 끝나면 멈추고 처음으로
        state.isPlaying = false
        state.position = 0
        return .cancel(id: CancelID.preview)

      case .likeButtonTapped:
        guard let previous = state.song?.isLiked else { return .none }
        self.setLiked(!previous, in: &state)
        let id = state.songID
        return .run { send in
          do {
            try await self.client.setLiked(id, !previous)
          } catch {
            await send(.likeFailed(restore: previous))
          }
        }

      case let .likeFailed(restore):
        self.setLiked(restore, in: &state)
        return .none

      case .backButtonTapped:
        return .send(.delegate(.dismiss))

      case .shareButtonTapped:
        return .send(.delegate(.share(songID: state.songID)))

      case .moreButtonTapped:
        return .send(.delegate(.more(songID: state.songID)))

      case .artistTapped:
        return .send(.delegate(.showArtist))

      case .albumTapped:
        return .send(.delegate(.showAlbum))

      case .commentsTapped:
        return .send(.delegate(.showComments(songID: state.songID)))

      case .addToPlaylistTapped:
        return .send(.delegate(.addToPlaylist(songID: state.songID)))

      case .recommendTapped:
        return .send(.delegate(.recommendToRelay(songID: state.songID)))

      case let .relayTapped(id):
        return .send(.delegate(.showRelay(id)))

      case let .relatedPlayTapped(id):
        // 곡 상세 미리듣기와 겹치지 않게 멈춘다
        state.isPlaying = false
        return .merge(.cancel(id: CancelID.preview), .send(.delegate(.playRelated(id))))

      case .openInMusicTapped:
        return .send(.delegate(.openInMusic(songID: state.songID)))

      case let .relatedSongTapped(id):
        return .send(.delegate(.showSong(id)))

      case let .otherAlbumTapped(id):
        return .send(.delegate(.showOtherAlbum(id)))

      case .delegate:
        return .none
      }
    }
  }

  private func setLiked(_ isLiked: Bool, in state: inout State) {
    guard var song = state.song, song.isLiked != isLiked else { return }
    song.isLiked = isLiked
    song.likeCount += isLiked ? 1 : -1
    state.song = song
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.loadFailed = false
    let id = state.songID
    return .run { send in
      do {
        try await send(.loaded(self.client.fetch(id)))
      } catch {
        await send(.loadFailed)
      }
    }
  }
}
