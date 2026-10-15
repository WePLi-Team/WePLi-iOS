import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-035 · UI-8c · UI-11c

@MainActor
final class BatonRelayFeatureTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1800000000)

  private func loaded(turn: BatonRelay.Turn = .invited(passer: "chuuuuu__")) -> BatonRelayFeature.State {
    var state = BatonRelayFeature.State(relayID: "rainy-night")
    var relay = BatonRelay.mock(id: "rainy-night")
    relay.turn = turn
    state.relay = relay
    state.now = self.now
    return state
  }

  func testClockAndCounts() {
    XCTAssertEqual(
      BatonText.clock(from: self.now, to: self.now.addingTimeInterval(23 * 3600 + 41 * 60 + 12)),
      "23:41:12"
    )
    XCTAssertEqual(BatonText.clock(from: self.now, to: self.now.addingTimeInterval(-5)), "0:00:00")
    let relay = BatonRelay.mock(id: "r")
    XCTAssertEqual(relay.count, 4)
    XCTAssertEqual(relay.myPosition, 5)
    XCTAssertEqual(relay.total, 8)
  }

  func testAccept_startsTurnThenShowsChain() async {
    let endsAt = self.now.addingTimeInterval(BatonText.turnLength)
    let store = TestStore(initialState: self.loaded()) { BatonRelayFeature() } withDependencies: {
      $0.batonRelayClient.accept = { _ in endsAt }
    }
    XCTAssertTrue(store.state.showsInvite)
    await store.send(.acceptTapped) { $0.isSending = true }
    await store.receive(.accepted(endsAt: endsAt)) {
      $0.isSending = false
      $0.relay?.turn = .mine(endsAt: endsAt)
    }
    // 받은 뒤에도 11c에서 「곡 고르러 가기」를 눌러야 8c로 간다
    XCTAssertTrue(store.state.showsInvite)
    await store.send(.goPickTapped) { $0.showsChain = true }
    XCTAssertFalse(store.state.showsInvite)
  }

  func testSkip() async {
    let store = TestStore(initialState: self.loaded()) { BatonRelayFeature() } withDependencies: {
      $0.batonRelayClient.skip = { _ in }
    }
    await store.send(.skipTapped) { $0.isSending = true }
    await store.receive(.skipped) {
      $0.isSending = false
      $0.relay?.turn = .skipped
    }
    // 넘긴 뒤에는 받을 수 없다
    await store.send(.acceptTapped)
  }

  func testPass_needsSongAndKeyword() async {
    var state = self.loaded(turn: .mine(endsAt: self.now.addingTimeInterval(3600)))
    state.showsChain = true
    let relay = BatonRelay.mock(id: "rainy-night")
    let passed = relay.passed(pickID: "palette", keyword: "#여행")
    let store = TestStore(initialState: state) { BatonRelayFeature() } withDependencies: {
      $0.batonRelayClient.pass = { _, _, _ in passed }
    }
    await store.send(.passTapped)
    await store.send(.pickTapped("palette")) { $0.pickID = "palette" }
    XCTAssertFalse(store.state.canPass)
    await store.send(.keywordTapped("#여행")) { $0.keyword = "#여행" }
    await store.send(.passTapped) { $0.isSending = true }
    await store.receive(.passed(passed)) {
      $0.isSending = false
      $0.relay = passed
    }
    XCTAssertEqual(store.state.relay?.count, 5)
    XCTAssertEqual(store.state.relay?.chain.last?.keywordFrom, "#바다 이어받음")
    XCTAssertEqual(store.state.relay?.runners.map(\.state)[4 ... 5], [.done, .now])
  }
}

extension MainTabFeatureTests {
  func testRelayTab_liveBatonRelayOpensBatonScreen() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .relay
    initial.relay.relays = [
      Relay(
        id: "rainy-night",
        title: "비 오는 밤 이어달리기",
        voteFormat: .baton,
        participantCount: 8,
        status: .live(endsAt: .distantFuture),
        isMine: true
      ),
    ]
    let store = TestStore(initialState: initial) { MainTabFeature() }
    store.exhaustivity = .off
    await store.send(.relay(.delegate(.showRelay("rainy-night"))))
    guard case .batonRelay? = store.state.relayPath.last else { return XCTFail("바통 화면이 열려야 한다") }
  }
}
