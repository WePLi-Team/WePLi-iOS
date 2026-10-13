import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-001

@MainActor
final class MainTabFeatureTests: XCTestCase {
  func testInitialTab_isHome() {
    XCTAssertEqual(MainTabFeature.State().selectedTab, .home)
  }

  func testTabSelected_changesSelectedTab() async {
    let store = TestStore(initialState: MainTabFeature.State()) {
      MainTabFeature()
    }

    await store.send(.tabSelected(.relay)) {
      $0.selectedTab = .relay
    }
    await store.send(.tabSelected(.search)) {
      $0.selectedTab = .search
    }
  }

  func testTabs_matchDesignOrder() {
    XCTAssertEqual(MainTabFeature.Tab.allCases, [.home, .relay, .community, .my, .search])
    XCTAssertEqual(MainTabFeature.Tab.capsuleTabs, [.home, .relay, .community, .my])
    XCTAssertEqual(MainTabFeature.Tab.allCases.map(\.title), ["홈", "릴레이", "커뮤니티", "마이", "검색"])
  }
}
