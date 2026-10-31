import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-080 · UI-4c

@MainActor
final class SearchFeatureTests: XCTestCase {
  // MARK: 검색 규칙

  func testNormalize_trimsDropsOneHashAndLowercases() {
    XCTAssertEqual(SearchEngine.normalize("  #Supernova "), "supernova")
    XCTAssertEqual(SearchEngine.normalize("##a"), "#a")
    XCTAssertEqual(SearchEngine.normalize("   "), "")
  }

  func testAllScope_limitsEachSection() {
    let results = SearchEngine.search("아이유", scope: .all, in: .mock)
    XCTAssertEqual(results.songs.map(\.title), ["밤편지", "Blueming", "관객이 될게 (I stan U)"])
    XCTAssertTrue(results.lists.isEmpty)
    XCTAssertTrue(results.users.isEmpty)
  }

  func testTagMatch_isExactAndCaseInsensitive() {
    let results = SearchEngine.search("#비 오는 날", scope: .all, in: .mock)
    XCTAssertEqual(results.songs.count, 3)
    // 「전체」에서 플리/릴레이는 3개까지
    XCTAssertEqual(results.lists.map(\.title), ["추위를 녹이는 음색의 보이스", "비 오는 날 듣는 플리"])
  }

  func testSingleScope_allowsTenAndHidesOthers() {
    // 「플레이리스트」는 부가정보 부분 일치로 6개
    let all = SearchEngine.search("플레이리스트", scope: .all, in: .mock)
    XCTAssertEqual(all.lists.count, 3)
    let lists = SearchEngine.search("플레이리스트", scope: .list, in: .mock)
    XCTAssertEqual(lists.lists.count, 6)
    XCTAssertTrue(lists.songs.isEmpty)
    XCTAssertTrue(lists.users.isEmpty)
  }

  func testUserSubtitle_matchesPersona() {
    XCTAssertEqual(SearchEngine.search("소셜 튠즈", scope: .user, in: .mock).users.map(\.name), ["minnie._."])
  }

  func testNoMatch_isEmpty() {
    XCTAssertTrue(SearchEngine.search("ㅁㄴㅇㄹ", scope: .all, in: .mock).isEmpty)
  }

  // MARK: 리듀서

  func testTyping_debouncesThenSearches() async {
    let clock = TestClock()
    let expected = SearchEngine.search("aespa", scope: .all, in: .mock)
    let store = TestStore(initialState: SearchFeature.State()) {
      SearchFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.searchClient.search = { query, scope in SearchEngine.search(query, scope: scope, in: .mock) }
    }

    await store.send(.binding(.set(\.query, "aes"))) {
      $0.query = "aes"
      $0.isSearching = true
    }
    await store.send(.binding(.set(\.query, "aespa"))) {
      $0.query = "aespa"
    }
    await clock.advance(by: SearchFeature.debounce)
    await store.receive(.resultsLoaded(expected)) {
      $0.isSearching = false
      $0.results = expected
    }
  }

  func testSuggestion_resetsScopeToAll() async {
    var state = SearchFeature.State()
    state.searchScope = .user
    let store = TestStore(initialState: state) {
      SearchFeature()
    } withDependencies: {
      $0.searchClient.search = { query, scope in SearchEngine.search(query, scope: scope, in: .mock) }
    }
    let expected = SearchEngine.search("카페 BGM", scope: .all, in: .mock)

    await store.send(.suggestionTapped("카페 BGM")) {
      $0.query = "카페 BGM"
      $0.searchScope = .all
      $0.isSearching = true
    }
    await store.receive(.resultsLoaded(expected)) {
      $0.isSearching = false
      $0.results = expected
    }
  }

  func testClear_keepsScope() async {
    var state = SearchFeature.State()
    state.query = "aespa"
    state.searchScope = .song
    state.results = SearchEngine.search("aespa", scope: .song, in: .mock)
    let store = TestStore(initialState: state) {
      SearchFeature()
    }

    await store.send(.clearButtonTapped) {
      $0.query = ""
      $0.results = SearchResults()
    }
    XCTAssertEqual(store.state.searchScope, .song)
  }

  func testHomeButton_switchesMainTabToHome() async {
    var state = MainTabFeature.State()
    state.selectedTab = .search
    let store = TestStore(initialState: state) {
      MainTabFeature()
    }

    await store.send(.search(.homeButtonTapped))
    await store.receive(.search(.delegate(.showHome))) {
      $0.selectedTab = .home
      $0.visitedTabs = [.search]
    }
  }
}
