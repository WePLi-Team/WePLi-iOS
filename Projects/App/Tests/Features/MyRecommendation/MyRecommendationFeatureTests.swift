import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-038 · UI-8a · DEC-004

@MainActor
final class MyRecommendationFeatureTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1791991800)

  func testTexts_followTimeline() {
    let start = RelayStanding.mock(relayID: "r", step: 0, now: self.now)
    let easy = try? XCTUnwrap(start.heroSong)
    XCTAssertEqual(easy?.title, "EASY")
    XCTAssertEqual(start.rank(of: "easy"), 3)
    XCTAssertEqual(easy.map { StandingText.gap(start, song: $0) }, "2위까지 86점")
    XCTAssertEqual(StandingText.score(2120), "2,120")
    XCTAssertEqual(StandingText.move(RankChange(startRank: 3, rank: 3)), "변동 없음")
    XCTAssertEqual(StandingText.move(RankChange(startRank: 3, rank: 1)), "▲2 · 오늘")
    XCTAssertEqual(RankChange(startRank: 1, rank: 2).text, "▼1")
    XCTAssertEqual(StandingText.remaining(until: start.endsAt, now: self.now), "실시간 순위 · 1일 12시간 남음")

    let top = RelayStanding.mock(relayID: "r", step: 7, now: self.now)
    XCTAssertEqual(top.rank(of: "easy"), 1)
    XCTAssertEqual(top.heroSong.map { StandingText.gap(top, song: $0) }, "1위 유지 중")
  }

  func testReversal_onlyWhenMySongRises() {
    let step0 = RelayStanding.mock(relayID: "r", step: 0, now: self.now)
    let step1 = RelayStanding.mock(relayID: "r", step: 1, now: self.now)
    let step2 = RelayStanding.mock(relayID: "r", step: 2, now: self.now)
    let step7 = RelayStanding.mock(relayID: "r", step: 7, now: self.now)
    XCTAssertNil(MyRecommendationFeature.reversal(from: nil, to: step0))
    XCTAssertNil(MyRecommendationFeature.reversal(from: step0, to: step1))
    let second = MyRecommendationFeature.reversal(from: step1, to: step2)
    XCTAssertEqual(second?.title, "역전!")
    XCTAssertEqual(second?.body, "내가 추천한 ‘EASY’가 2위로 올랐어요")
    XCTAssertEqual(MyRecommendationFeature.reversal(from: step2, to: step7)?.title, "1위 탈환!")
  }

  func testPolling_showsBannerThenHides() async {
    let clock = TestClock()
    let step = LockIsolated(1)
    let now = self.now
    let store = TestStore(initialState: MyRecommendationFeature.State(relayID: "r")) {
      MyRecommendationFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date.now = now
      $0.myRecommendationClient.fetchStanding = { relayID in
        step.withValue { value in
          defer { value += 1 }
          return RelayStanding.mock(relayID: relayID, step: value, now: now)
        }
      }
    }
    store.exhaustivity = .off

    await store.send(.onAppear)
    await store.skipReceivedActions()
    XCTAssertEqual(store.state.standing?.rank(of: "easy"), 3)
    XCTAssertNil(store.state.banner)

    await clock.advance(by: MyRecommendationFeature.refreshInterval)
    await store.skipReceivedActions()
    XCTAssertEqual(store.state.banner?.rank, 2)

    await clock.advance(by: MyRecommendationFeature.bannerDuration)
    await store.skipReceivedActions()
    XCTAssertNil(store.state.banner)
    await store.send(.onDisappear)
  }

  func testRefreshFailure_keepsLastStanding() async {
    var initial = MyRecommendationFeature.State(relayID: "r")
    initial.standing = .mock(relayID: "r", step: 0, now: self.now)
    let store = TestStore(initialState: initial) {
      MyRecommendationFeature()
    } withDependencies: {
      $0.myRecommendationClient.fetchStanding = { _ in throw URLError(.timedOut) }
    }

    await store.send(.refreshTicked)
    await store.receive(.loadFailed)
    XCTAssertFalse(store.state.loadFailed)
  }
}

@MainActor
final class MyRecommendationNavigationTests: XCTestCase {
  func testRankChangedNotification_opensMyRecommendation() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .community
    var notifications = NotificationsFeature.State()
    notifications.notifications = [
      AppNotification(
        id: "n2",
        group: .today,
        kind: .rankChanged,
        text: "내가 추천한 ‘EASY’가 3위로 올랐어요.",
        timeText: "24분 전",
        actionTitle: nil,
        isRead: false,
        relayID: "first-love"
      ),
    ]
    initial.communityPath.append(.notifications(notifications))
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    }
    store.exhaustivity = .off
    let id = initial.communityPath.ids[0]

    await store.send(.communityPath(.element(id: id, action: .notifications(.delegate(.open("n2"))))))
    guard let last = store.state.communityPath.ids.last else { return XCTFail("화면이 열리지 않음") }
    XCTAssertEqual(store.state.communityPath[id: last, case: \.myRecommendation]?.relayID, "first-love")
  }
}
