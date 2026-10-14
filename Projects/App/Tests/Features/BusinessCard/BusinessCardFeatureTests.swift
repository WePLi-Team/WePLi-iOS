import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-075 · UI-2e · DEC-004

@MainActor
final class BusinessCardFeatureTests: XCTestCase {
  // 2026-10-14 15:30 UTC = 2026-10-15 00:30 KST
  private let now = Date(timeIntervalSince1970: 1791991800)
  private let song = ComposeTrack(id: "1", title: "소년, 길을 걷다", artist: "이승기")

  private func state(_ step: BusinessCardStep = .intro) -> BusinessCardFeature.State {
    var state = BusinessCardFeature.State(nickname: "김동", persona: "멜로디 메모리즈", today: self.now)
    state.step = step
    return state
  }

  func testInput_rules() {
    XCTAssertEqual(BusinessCardInput.oneLiner(String(repeating: "가", count: 25)).count, 20)
    XCTAssertEqual(BusinessCardInput.instagram(" @dong x._.2 "), "@dongx._.2")
    XCTAssertEqual(BusinessCardInput.displayInstagram("@dongx._.2"), "dongx._.2")
    XCTAssertEqual(BusinessCardInput.displayInstagram("@@a"), "@a")
    XCTAssertNil(BusinessCardInput.displayInstagram("@"))
    XCTAssertFalse(BusinessCardInput.hasText("   "))
  }

  func testCard_usesDefaultOneLinerAndSeoulDate() {
    let card = self.state().card
    XCTAssertEqual(card.oneLiner, "반갑습니다. 소통해요")
    XCTAssertEqual(card.day, "15")
    XCTAssertEqual(card.month, "OCT")
    XCTAssertNil(card.instagram)
  }

  func testSteps_requireInputAndBackKeepsValues() async {
    let store = TestStore(initialState: self.state()) {
      BusinessCardFeature()
    }

    await store.send(.startTapped) { $0.step = .song }
    // 곡을 고르기 전에는 넘어가지 않는다
    await store.send(.songConfirmed)
    await store.send(.songAreaTapped) { $0.picker = SongPickerFeature.State() }
    await store.send(.picker(.presented(.delegate(.add([self.song]))))) {
      $0.picker = nil
      $0.song = self.song
    }
    await store.send(.songConfirmed) { $0.step = .oneLiner }
    await store.send(.oneLinerConfirmed)
    await store.send(.oneLinerChanged("노래로 소통해요")) { $0.oneLiner = "노래로 소통해요" }
    await store.send(.oneLinerConfirmed) { $0.step = .instagram }
    await store.send(.backTapped) { $0.step = .oneLiner }
    XCTAssertEqual(store.state.oneLiner, "노래로 소통해요")
  }

  func testGenerate_finishesAfterProgressAndSave() async {
    let clock = TestClock()
    var initial = self.state(.instagram)
    initial.song = self.song
    initial.instagram = "@dongx._.2"
    let saved = LockIsolated<BusinessCard?>(nil)
    let store = TestStore(initialState: initial) {
      BusinessCardFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.withRandomNumberGenerator = WithRandomNumberGenerator(FixedFive())
      $0.businessCardClient.create = { card in
        saved.setValue(card)
        return "card-1"
      }
    }
    store.exhaustivity = .off

    await store.send(.instagramConfirmed) { $0.step = .generating }
    await store.receive(.saved(cardID: "card-1"))
    XCTAssertEqual(saved.value?.instagram, "dongx._.2")
    // 5%씩 20번이면 100%
    await clock.advance(by: .milliseconds(70 * 20))
    await store.skipReceivedActions()
    XCTAssertEqual(store.state.percent, 100)
    XCTAssertEqual(store.state.step, .generating)
    await clock.advance(by: BusinessCardFeature.finishDelay)
    await store.receive(.finished) { $0.step = .done }
  }

  func testGenerate_failureReturnsToInstagram() async {
    var initial = self.state(.instagram)
    initial.song = self.song
    let store = TestStore(initialState: initial) {
      BusinessCardFeature()
    } withDependencies: {
      $0.continuousClock = TestClock()
      $0.businessCardClient.create = { _ in throw URLError(.timedOut) }
    }
    store.exhaustivity = .off

    await store.send(.skipTapped) { $0.step = .generating }
    await store.receive(.saveFailed) {
      $0.step = .instagram
      $0.toast = "명함을 만들지 못했어요. 다시 시도해 주세요"
    }
  }

  func testShare_linkCopiesAndCloseDismisses() async {
    var initial = self.state(.done)
    initial.cardID = "card-1"
    initial.isShareSheetPresented = true
    let url = URL(string: "https://wepli.example/cards/card-1")
    let copied = LockIsolated<URL?>(nil)
    let store = TestStore(initialState: initial) {
      BusinessCardFeature()
    } withDependencies: {
      $0.businessCardClient.link = { _ in try XCTUnwrap(url) }
      $0.songShareClient.copy = { copied.setValue($0) }
    }

    await store.send(.shareItemTapped(.link, image: nil)) { $0.isShareSheetPresented = false }
    await store.receive(.linkCopied) { $0.toast = "링크를 복사했어요" }
    XCTAssertEqual(copied.value, url)
    await store.send(.closeTapped)
    await store.receive(.delegate(.dismiss))
  }
}

/// 늘 5%씩 오르게 하는 난수 — Int.random(in: 2...5)이 5를 고르도록 가장 큰 값을 돌려준다
private struct FixedFive: RandomNumberGenerator {
  mutating func next() -> UInt64 {
    .max
  }
}
