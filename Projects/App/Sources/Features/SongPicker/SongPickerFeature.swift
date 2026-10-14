import ComposableArchitecture
import Foundation

// REQ-062 · UI-2a — 곡 검색 · 선택

@Reducer
struct SongPickerFeature {
  @ObservableState
  struct State: Equatable {
    var query = ""
    var recent: [String] = []
    var trending: [String] = []
    var results: [ComposeTrack] = []
    var isSearching = false
    /// 고른 곡 id — 트레이에는 결과 순서대로 보인다
    var selectedIDs: Set<ComposeTrack.ID> = []
    /// 이번 시트에서 고른 곡 정보(검색어를 바꿔도 남는다)
    var selectedTracks: [ComposeTrack] = []
    var toast: String?

    var hasQuery: Bool {
      ComposeInput.hasText(self.query)
    }
  }

  enum Action: Equatable {
    case onAppear
    case queryChanged(String)
    /// 최근 검색어 · 급상승 검색어 — 바로 검색하고 최근 검색어에 넣는다
    case suggestionTapped(String)
    case clearQueryTapped
    case removeRecentTapped(String)
    case clearRecentTapped
    case resultsLoaded([ComposeTrack])
    case searchFailed
    case trackToggled(ComposeTrack.ID)
    case addButtonTapped
    case toastDismissed
    case cancelButtonTapped
    case delegate(Delegate)
  }

  enum Delegate: Equatable {
    case add([ComposeTrack])
    case dismiss
  }

  private enum CancelID {
    case search
  }

  static let debounce: Duration = .milliseconds(250)

  @Dependency(\.composeClient)
  var client

  @Dependency(\.continuousClock)
  var clock

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        if state.recent.isEmpty, state.trending.isEmpty {
          state.recent = self.client.recentSearches()
          state.trending = self.client.trendingSearches()
        }
        return state.hasQuery ? self.search(&state, debounced: false) : .none

      case let .queryChanged(text):
        state.query = text
        return self.search(&state, debounced: true)

      case let .suggestionTapped(term):
        state.query = term
        state.recent = RecentSearches.adding(term, to: state.recent)
        return self.search(&state, debounced: false)

      case .clearQueryTapped:
        state.query = ""
        return self.search(&state, debounced: false)

      case let .removeRecentTapped(term):
        state.recent.removeAll { $0 == term }
        return .none

      case .clearRecentTapped:
        state.recent = []
        return .none

      case let .resultsLoaded(tracks):
        state.isSearching = false
        state.results = tracks
        return .none

      case .searchFailed:
        state.isSearching = false
        state.results = []
        return .none

      case let .trackToggled(id):
        if state.selectedIDs.remove(id) != nil {
          state.selectedTracks.removeAll { $0.id == id }
        } else if let track = state.results.first(where: { $0.id == id }) {
          state.selectedIDs.insert(id)
          state.selectedTracks.append(track)
        }
        return .none

      case .addButtonTapped:
        let tracks = state.selectedTracks
        guard !tracks.isEmpty else { return .none }
        // 추가하면 선택만 비우고 검색어는 그대로 둔다(UI-2a)
        state.selectedIDs = []
        state.selectedTracks = []
        state.toast = "\(tracks.count)곡을 게시글에 추가했어요"
        return .send(.delegate(.add(tracks)))

      case .toastDismissed:
        state.toast = nil
        return .none

      case .cancelButtonTapped:
        return .send(.delegate(.dismiss))

      case .delegate:
        return .none
      }
    }
  }

  private func search(_ state: inout State, debounced: Bool) -> Effect<Action> {
    guard state.hasQuery else {
      state.isSearching = false
      state.results = []
      return .cancel(id: CancelID.search)
    }
    state.isSearching = true
    let query = state.query
    return .run { send in
      if debounced {
        try await self.clock.sleep(for: Self.debounce)
      }
      do {
        try await send(.resultsLoaded(self.client.searchTracks(query)))
      } catch is CancellationError {
        return
      } catch {
        await send(.searchFailed)
      }
    }
    .cancellable(id: CancelID.search, cancelInFlight: true)
  }
}
