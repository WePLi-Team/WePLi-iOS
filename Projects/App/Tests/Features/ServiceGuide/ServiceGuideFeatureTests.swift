import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-113 · UI-7f

@MainActor
final class ServiceGuideFeatureTests: XCTestCase {
  func testNext_goesThroughFourPagesThenCloses() async {
    let store = TestStore(initialState: ServiceGuideFeature.State()) { ServiceGuideFeature() }
    XCTAssertEqual(ServiceGuidePage.all.map(\.title), ["주제가 열려요", "어울리는 곡을 추천해요", "투표로 순위를 정해요", "플레이리스트가 완성돼요"])
    await store.send(.nextTapped) { $0.page = 1 }
    await store.send(.nextTapped) { $0.page = 2 }
    await store.send(.nextTapped) { $0.page = 3 }
    XCTAssertTrue(store.state.isLastPage)
    await store.send(.nextTapped)
    await store.receive(.delegate(.dismiss))
  }

  func testPageChanged_ignoresOutOfRange() async {
    let store = TestStore(initialState: ServiceGuideFeature.State()) { ServiceGuideFeature() }
    await store.send(.pageChanged(2)) { $0.page = 2 }
    await store.send(.pageChanged(9))
  }
}

extension MainTabFeatureTests {
  func testServiceGuideMenu_opensFullScreenAndCloses() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .my
    let store = TestStore(initialState: initial) { MainTabFeature() }
    store.exhaustivity = .off
    await store.send(.my(.menuTapped(.serviceGuide)))
    await store.receive(.my(.delegate(.show(.serviceGuide))))
    XCTAssertNotNil(store.state.serviceGuide)
    await store.send(.serviceGuide(.presented(.closeTapped)))
    await store.receive(.serviceGuide(.presented(.delegate(.dismiss))))
    XCTAssertNil(store.state.serviceGuide)
  }
}
