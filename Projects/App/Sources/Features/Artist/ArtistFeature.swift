import ComposableArchitecture
import Foundation

// REQ-024 · UI-5b · DEC-004 — 아티스트

@Reducer
struct ArtistFeature {
  @ObservableState
  struct State: Equatable {
    let artistID: String
    var artist: ArtistDetail?
    var loadFailed = false

    init(artistID: String, artist: ArtistDetail? = nil) {
      self.artistID = artistID
      self.artist = artist
    }
  }

  enum Action: Equatable {
    case onAppear
    case loaded(ArtistDetail)
    case loadFailed
    case retryButtonTapped
    case backButtonTapped
    case shareButtonTapped
    case likeButtonTapped
    case likeFailed(restore: Bool)
    case playAllTapped
    case popularSongsTapped
    case songTapped(ArtistDetail.Song.ID)
    case songMenuTapped(ArtistDetail.Song.ID)
    case albumTapped(ArtistDetail.Album.ID)
    case placeTapped(ArtistDetail.Place.ID)
    case relatedArtistTapped(String)
    case delegate(ArtistDelegate)
  }

  @Dependency(\.artistClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.artist == nil else { return .none }
        return self.load(&state)

      case let .loaded(artist):
        state.artist = artist
        return .none

      case .loadFailed:
        state.loadFailed = true
        return .none

      case .retryButtonTapped:
        return self.load(&state)

      case .likeButtonTapped:
        guard let previous = state.artist?.isLiked else { return .none }
        // 먼저 반영하고 실패하면 되돌린다(DEC-004)
        state.artist?.isLiked = !previous
        let id = state.artistID
        return .run { send in
          do {
            try await self.client.setLiked(id, !previous)
          } catch {
            await send(.likeFailed(restore: previous))
          }
        }

      case let .likeFailed(restore):
        state.artist?.isLiked = restore
        return .none

      case .backButtonTapped:
        return .send(.delegate(.dismiss))

      case let .relatedArtistTapped(name):
        return .send(.delegate(.showArtist(name)))

      case let .songTapped(id):
        return .send(.delegate(.showSong(id)))

      case let .placeTapped(id):
        guard let place = state.artist?.places.first(where: { $0.id == id }) else { return .none }
        switch place.kind {
        case .playlist: return .send(.delegate(.showPlaylist(id)))
        case .post: return .send(.delegate(.showPost(id)))
        }

      // 원본에 동작이 정해지지 않은 버튼(공유 · 전체 재생 · 인기곡 전체 · 곡 메뉴 · 앨범) — 화면이 생기면 잇는다
      case .playAllTapped:
        return .send(.delegate(.playAll))

      case .shareButtonTapped, .popularSongsTapped, .songMenuTapped, .albumTapped, .delegate:
        return .none
      }
    }
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.loadFailed = false
    let id = state.artistID
    return .run { send in
      do {
        try await send(.loaded(self.client.fetch(id)))
      } catch {
        await send(.loadFailed)
      }
    }
  }
}

enum ArtistDelegate: Equatable {
  case dismiss
  /// 함께 많이 듣는 아티스트 → 다른 아티스트 화면
  case showArtist(String)
  case showSong(ArtistDetail.Song.ID)
  case showPlaylist(ArtistDetail.Place.ID)
  case showPost(ArtistDetail.Place.ID)
  /// 인기곡 전체 재생 → 미리듣기 플레이어(UI-4b)
  case playAll
}
