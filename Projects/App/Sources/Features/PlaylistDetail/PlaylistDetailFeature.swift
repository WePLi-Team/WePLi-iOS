import ComposableArchitecture
import Foundation

// REQ-025 · UI-3d · DEC-004 — 플레이리스트 상세

@Reducer
struct PlaylistDetailFeature {
  @ObservableState
  struct State: Equatable {
    let playlistID: String
    var playlist: PlaylistDetail?
    var loadFailed = false
    /// 소개글 펼침 — 처음에는 두 줄로 접는다
    var isIntroductionExpanded = false

    init(playlistID: String, playlist: PlaylistDetail? = nil) {
      self.playlistID = playlistID
      self.playlist = playlist
    }
  }

  enum Action: Equatable {
    case onAppear
    case loaded(PlaylistDetail)
    case loadFailed
    case retryButtonTapped
    case introductionTapped
    case saveButtonTapped
    case saveFailed(restore: Bool)
    case playButtonTapped
    case shuffleButtonTapped
    case backButtonTapped
    case moreButtonTapped
    case trackTapped(PlaylistDetail.Track.ID)
    case trackMoreTapped(PlaylistDetail.Track.ID)
    case artistTapped(PlaylistDetail.Artist.ID)
    case delegate(Delegate)
  }

  enum Delegate: Equatable {
    case dismiss
    case play(playlistID: String, shuffled: Bool)
    case more(playlistID: String)
    case showTrack(PlaylistDetail.Track.ID)
    case trackMenu(PlaylistDetail.Track.ID)
    /// 아티스트 (UI-5b)
    case showArtist(PlaylistDetail.Artist.ID)
  }

  @Dependency(\.playlistDetailClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.playlist == nil else { return .none }
        return self.load(&state)

      case let .loaded(playlist):
        state.playlist = playlist
        return .none

      case .loadFailed:
        state.loadFailed = true
        return .none

      case .retryButtonTapped:
        return self.load(&state)

      case .introductionTapped:
        state.isIntroductionExpanded.toggle()
        return .none

      case .saveButtonTapped:
        guard let previous = state.playlist?.isSaved else { return .none }
        state.playlist?.isSaved = !previous
        let id = state.playlistID
        return .run { send in
          do {
            try await self.client.setSaved(id, !previous)
          } catch {
            await send(.saveFailed(restore: previous))
          }
        }

      case let .saveFailed(restore):
        state.playlist?.isSaved = restore
        return .none

      case .playButtonTapped:
        return .send(.delegate(.play(playlistID: state.playlistID, shuffled: false)))

      case .shuffleButtonTapped:
        return .send(.delegate(.play(playlistID: state.playlistID, shuffled: true)))

      case .backButtonTapped:
        return .send(.delegate(.dismiss))

      case .moreButtonTapped:
        return .send(.delegate(.more(playlistID: state.playlistID)))

      case let .trackTapped(id):
        return .send(.delegate(.showTrack(id)))

      case let .trackMoreTapped(id):
        return .send(.delegate(.trackMenu(id)))

      case let .artistTapped(id):
        return .send(.delegate(.showArtist(id)))

      case .delegate:
        return .none
      }
    }
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.loadFailed = false
    let id = state.playlistID
    return .run { send in
      do {
        try await send(.loaded(self.client.fetch(id)))
      } catch {
        await send(.loadFailed)
      }
    }
  }
}
