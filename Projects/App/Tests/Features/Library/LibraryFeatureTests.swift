import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-077 · UI-5c

@MainActor
final class LibraryFeatureTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1800000000)

  func testDefaultSegment_isJoinedRelays() {
    XCTAssertEqual(LibraryFeature.State().segment, .relays)
    XCTAssertEqual(LibrarySegment.allCases.map(\.title), ["내 플레이리스트", "참여한 릴레이", "좋아요·저장"])
  }

  func testOnAppear_loadsAndTicks() async {
    let clock = TestClock()
    let library = Library.mock(now: self.now)
    let store = TestStore(initialState: LibraryFeature.State()) {
      LibraryFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date.now = self.now
      $0.libraryClient.fetch = { library }
    }

    await store.send(.onAppear) { $0.now = self.now }
    await store.receive(.loaded(library)) { $0.library = library }
    await clock.advance(by: .seconds(1))
    await store.receive(.timerTicked)
    await store.send(.onDisappear)
  }

  func testLiveRelayCountdown_usesClockFormat() {
    let relay = Library.mock(now: self.now).liveRelays[0]
    XCTAssertEqual(RemainingTimeFormatter.string(from: self.now, to: relay.endsAt), "1:12:34")
  }

  func testSegmentAndTaps() async {
    var state = LibraryFeature.State()
    state.library = .mock(now: self.now)
    let store = TestStore(initialState: state) {
      LibraryFeature()
    }

    await store.send(.segmentSelected(.likes)) { $0.segment = .likes }
    await store.send(.continueVotingTapped("cafe-bgm"))
    await store.receive(.delegate(.continueVoting(relayID: "cafe-bgm")))
    await store.send(.editButtonTapped)
    await store.receive(.delegate(.editPlaylists))
    await store.send(.savedPostTapped("p4"))
    await store.receive(.delegate(.showPost("p4")))
  }
}
