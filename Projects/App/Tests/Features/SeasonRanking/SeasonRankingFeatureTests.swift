import ComposableArchitecture
@testable import WePLi
import XCTest

// UI-8f · DEC-022

@MainActor
final class SeasonRankingFeatureTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1792079276)

  func testTexts() {
    let ranking = SeasonRanking.mock(now: self.now)
    XCTAssertEqual(SeasonText.deadline(ranking.endsAt, now: self.now).prefix(4), "D-23")
    XCTAssertEqual(SeasonText.score(2340), "2,340")
    XCTAssertEqual(SeasonText.change(12), "어제보다 ▲12")
    XCTAssertEqual(SeasonText.change(-3), "어제보다 ▼3")
    XCTAssertNil(SeasonText.change(0))
    XCTAssertEqual(ranking.podium.map(\.rank), [1, 2, 3])
    XCTAssertEqual(ranking.list.map(\.rank), Array(4 ... 10))
  }

  func testList_topTenGapAndNearby() {
    let ranking = SeasonRanking.mock(now: self.now)
    XCTAssertTrue(ranking.showsGap)
    XCTAssertEqual(ranking.nearbyList.map(\.rank), [127, 128, 129])
    XCTAssertEqual(ranking.nearbyList.filter(ranking.isMe).map(\.rank), [128])
  }

  func testList_nearbyJoinsTopTenWithoutGap() {
    let base = SeasonRanking.mock(now: self.now)
    let ranking = SeasonRanking(
      seasonName: base.seasonName,
      endsAt: base.endsAt,
      me: .init(rank: 10, change: 0, pointsToTop100: nil, score: 4880),
      entries: base.entries,
      nearby: [base.entries[8], base.entries[9], .init(rank: 11, name: "a", title: nil, score: 4800)],
      hosts: []
    )
    XCTAssertFalse(ranking.showsGap)
    XCTAssertEqual(ranking.nearbyList.map(\.rank), [11])
    XCTAssertTrue(ranking.isMe(ranking.list[6]))
  }

  func testLoad_andTabs() async {
    let ranking = SeasonRanking.mock(now: self.now)
    let store = TestStore(initialState: SeasonRankingFeature.State()) { SeasonRankingFeature() } withDependencies: {
      $0.seasonRankingClient.fetch = { ranking }
      $0.date.now = self.now
    }
    await store.send(.onAppear) { $0.now = self.now }
    await store.receive(.loaded(ranking)) { $0.ranking = ranking }
    await store.send(.tabSelected(.host)) { $0.tab = .host }
  }

  func testFollow_rollsBackOnFailure() async {
    struct Failure: Error {}
    var initial = SeasonRankingFeature.State()
    initial.ranking = .mock(now: self.now)
    let store = TestStore(initialState: initial) { SeasonRankingFeature() } withDependencies: {
      $0.seasonRankingClient.setFollowing = { _, _ in throw Failure() }
    }
    await store.send(.followTapped("dlwlrma")) { $0.ranking?.hosts[1].isFollowing = true }
    await store.receive(.followFailed("dlwlrma", wasFollowing: false)) {
      $0.ranking?.hosts[1].isFollowing = false
      $0.toast = "팔로우를 바꾸지 못했어요"
    }
  }
}

extension MainTabFeatureTests {
  func testTitlesHeader_opensSeasonRanking() async {
    var initial = MainTabFeature.State()
    initial.homePath.append(.topPrediction(TopPredictionFeature.State(relayID: "first-love")))
    let store = TestStore(initialState: initial) { MainTabFeature() }
    store.exhaustivity = .off
    guard let id = store.state.homePath.ids.last else { return XCTFail("1위 예측이 있어야 한다") }
    await store.send(.homePath(.element(id: id, action: .topPrediction(.rankingTapped))))
    await store.skipReceivedActions()
    guard case .seasonRanking? = store.state.homePath.last else { return XCTFail("시즌 랭킹이 열려야 한다") }
  }
}
