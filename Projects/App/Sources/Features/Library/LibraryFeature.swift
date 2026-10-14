import ComposableArchitecture
import Foundation

// REQ-077 · UI-5c — 보관함(내 활동)

@Reducer
struct LibraryFeature {
  @ObservableState
  struct State: Equatable {
    var segment: LibrarySegment
    var library: Library?
    var loadFailed = false
    var now = Date()

    /// 마이의 메뉴에 맞는 세그먼트로 연다(원본 기본값은 「참여한 릴레이」)
    init(segment: LibrarySegment = .relays) {
      self.segment = segment
    }
  }

  enum Action: Equatable {
    case onAppear
    case onDisappear
    case loaded(Library)
    case loadFailed
    case retryButtonTapped
    case timerTicked
    case segmentSelected(LibrarySegment)
    case editButtonTapped
    case backButtonTapped
    case newPlaylistTapped
    case playlistTapped(LibraryPlaylist.ID)
    case continueVotingTapped(LibraryLiveRelay.ID)
    case relayTapped(String)
    case likedSongTapped(String)
    case savedPostTapped(LibrarySavedPost.ID)
    case delegate(Delegate)
  }

  enum Delegate: Equatable {
    case dismiss
    /// 내 플레이리스트 편집 (UI-10d)
    case editPlaylists
    case createPlaylist
    case showPlaylist(LibraryPlaylist.ID)
    /// 카드 투표 (UI-3b)
    case continueVoting(relayID: String)
    case showRelay(String)
    case showSong(title: String)
    case showPost(LibrarySavedPost.ID)
  }

  private enum CancelID {
    case timer
  }

  @Dependency(\.libraryClient)
  var client

  @Dependency(\.continuousClock)
  var clock

  @Dependency(\.date.now)
  var now

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.now = self.now
        let timer: Effect<Action> = .run { send in
          for await _ in self.clock.timer(interval: .seconds(1)) {
            await send(.timerTicked)
          }
        }
        .cancellable(id: CancelID.timer, cancelInFlight: true)
        return state.library == nil ? .merge(self.load(&state), timer) : timer

      case .onDisappear:
        return .cancel(id: CancelID.timer)

      case let .loaded(library):
        state.library = library
        return .none

      case .loadFailed:
        state.loadFailed = true
        return .none

      case .retryButtonTapped:
        return self.load(&state)

      case .timerTicked:
        state.now = self.now
        return .none

      case let .segmentSelected(segment):
        state.segment = segment
        return .none

      case .editButtonTapped:
        return .send(.delegate(.editPlaylists))

      case .backButtonTapped:
        return .send(.delegate(.dismiss))

      case .newPlaylistTapped:
        return .send(.delegate(.createPlaylist))

      case let .playlistTapped(id):
        return .send(.delegate(.showPlaylist(id)))

      case let .continueVotingTapped(id):
        return .send(.delegate(.continueVoting(relayID: id)))

      case let .relayTapped(id):
        return .send(.delegate(.showRelay(id)))

      case let .likedSongTapped(title):
        return .send(.delegate(.showSong(title: title)))

      case let .savedPostTapped(id):
        return .send(.delegate(.showPost(id)))

      case .delegate:
        return .none
      }
    }
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.loadFailed = false
    return .run { send in
      do {
        try await send(.loaded(self.client.fetch()))
      } catch {
        await send(.loadFailed)
      }
    }
  }
}
