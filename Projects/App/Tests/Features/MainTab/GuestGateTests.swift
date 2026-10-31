import ComposableArchitecture
@testable import WePLi
import XCTest

// DEC-032 — 손님은 둘러보기만, 투표 · 추천 등은 로그인 요청 시트

@MainActor
final class GuestGateTests: XCTestCase {
  private func guest(_ tab: MainTabFeature.Tab = .home) -> MainTabFeature.State {
    var state = MainTabFeature.State()
    state.isGuest = true
    state.selectedTab = tab
    return state
  }

  func testGuestVote_showsPromptWithoutOpeningVote() async throws {
    var initial = self.guest(.relay)
    initial.relayPath.append(.relayDetail(RelayDetailFeature.State(relayID: "first-love")))
    let store = TestStore(initialState: initial) { MainTabFeature() }
    let detailID = try XCTUnwrap(store.state.relayPath.ids.first)
    await store.send(.relayPath(.element(
      id: detailID,
      action: .relayDetail(.delegate(.showVote(relayID: "first-love")))
    ))) {
      $0.loginPrompt = .vote
    }
    XCTAssertEqual(store.state.relayPath.count, 1)
  }

  func testGuestRecommend_showsPrompt() async throws {
    var initial = self.guest(.relay)
    initial.relayPath.append(.relayDetail(RelayDetailFeature.State(relayID: "first-love")))
    let store = TestStore(initialState: initial) { MainTabFeature() }
    let detailID = try XCTUnwrap(store.state.relayPath.ids.first)
    await store.send(.relayPath(.element(id: detailID, action: .relayDetail(.recommendButtonTapped))))
    await store.receive(\.relayPath) {
      $0.loginPrompt = .recommend
    }
  }

  /// 막힌 동작은 화면 reducer에 닿지 않는다 — 테스트 Client가 불리면 실패한다
  func testGuestLikeAndPrediction_neverReachClients() async {
    let store = TestStore(initialState: self.guest(.community)) { MainTabFeature() }
    await store.send(.community(.likeTapped("p1"))) {
      $0.loginPrompt = .like
    }
    await store.send(.loginPromptDismissed) {
      $0.loginPrompt = nil
    }
    await store.send(.home(.predictionPredictTapped)) {
      $0.loginPrompt = .prediction
    }
  }

  func testGuestLogin_requestsLoginScreen() async {
    var initial = self.guest()
    initial.loginPrompt = .vote
    let store = TestStore(initialState: initial) { MainTabFeature() }
    await store.send(.guestLoginTapped) {
      $0.loginPrompt = nil
    }
    await store.receive(.delegate(.loginRequested))
  }

  func testGuest_browsingStillWorks() async {
    let store = TestStore(initialState: self.guest()) { MainTabFeature() }
    await store.send(.tabSelected(.relay)) {
      $0.selectedTab = .relay
      $0.visitedTabs = [.home]
    }
    await store.receive(\.home.onDisappear)
  }

  func testDefaultIsMember_likeNeedsLogin() {
    let action = MainTabFeature.Action.community(.likeTapped("p1"))
    XCTAssertEqual(GuestGate<EmptyReducer<MainTabFeature.State, MainTabFeature.Action>>.reason(for: action), .like)
    XCTAssertFalse(MainTabFeature.State().isGuest)
  }
}
