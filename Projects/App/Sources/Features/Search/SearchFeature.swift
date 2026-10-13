import ComposableArchitecture
import Foundation

// REQ-080 · UI-4c — 통합 검색 탭

@Reducer
struct SearchFeature {
  @ObservableState
  struct State: Equatable {
    var query = ""
    var searchScope: SearchScope = .all
    var recentQueries: [String] = []
    var results = SearchResults()
    var isSearching = false

    /// 정규화한 검색어가 비면 둘러보기를 보여 준다
    var hasQuery: Bool {
      !SearchEngine.normalize(self.query).isEmpty
    }

    var showsNoResults: Bool {
      self.hasQuery && !self.isSearching && self.results.isEmpty
    }
  }

  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case onAppear
    case scopeSelected(SearchScope)
    /// 최근 검색어 · 둘러보기 태그 — 검색어를 넣고 범위를 「전체」로
    case suggestionTapped(String)
    /// 지우기(X) — 검색어만 비우고 범위는 그대로
    case clearButtonTapped
    case resultsLoaded(SearchResults)
    case searchFailed
    case homeButtonTapped
    case songTapped(SearchSong.ID)
    case listTapped(SearchList.ID)
    case userTapped(SearchUser.ID)
    case delegate(Delegate)
  }

  enum Delegate: Equatable {
    /// iOS 26 하단 검색 모드의 홈 버튼
    case showHome
    case showSong(SearchSong.ID)
    case showList(SearchList.ID)
    case showUser(SearchUser.ID)
  }

  private enum CancelID {
    case search
  }

  static let debounce: Duration = .milliseconds(250)

  @Dependency(\.searchClient)
  var searchClient

  @Dependency(\.continuousClock)
  var clock

  var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .binding(\.query):
        return self.search(&state, debounced: true)

      case .binding:
        return .none

      case .onAppear:
        if state.recentQueries.isEmpty {
          state.recentQueries = self.searchClient.recentQueries()
        }
        return .none

      case let .scopeSelected(scope):
        state.searchScope = scope
        return self.search(&state, debounced: false)

      case let .suggestionTapped(text):
        state.query = text
        state.searchScope = .all
        return self.search(&state, debounced: false)

      case .clearButtonTapped:
        state.query = ""
        return self.search(&state, debounced: false)

      case let .resultsLoaded(results):
        state.isSearching = false
        state.results = results
        return .none

      case .searchFailed:
        state.isSearching = false
        state.results = SearchResults()
        return .none

      case .homeButtonTapped:
        return .send(.delegate(.showHome))

      case let .songTapped(id):
        return .send(.delegate(.showSong(id)))

      case let .listTapped(id):
        return .send(.delegate(.showList(id)))

      case let .userTapped(id):
        return .send(.delegate(.showUser(id)))

      case .delegate:
        return .none
      }
    }
  }

  private func search(_ state: inout State, debounced: Bool) -> Effect<Action> {
    guard state.hasQuery else {
      state.isSearching = false
      state.results = SearchResults()
      return .cancel(id: CancelID.search)
    }
    state.isSearching = true
    let query = state.query
    let scope = state.searchScope
    return .run { send in
      if debounced {
        try await self.clock.sleep(for: Self.debounce)
      }
      do {
        try await send(.resultsLoaded(self.searchClient.search(query, scope)))
      } catch is CancellationError {
        return
      } catch {
        await send(.searchFailed)
      }
    }
    .cancellable(id: CancelID.search, cancelInFlight: true)
  }
}
