import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-034 · UI-8b · DEC-004

@MainActor
final class SongWorldCupFeatureTests: XCTestCase {
  func testBracket_eightSongsTakeSevenMatches() {
    var bracket = WorldCupBracket(songCount: 8)
    var labels: [String] = []
    var progress: [Int] = []
    while !bracket.isFinished {
      labels.append(bracket.roundLabel)
      progress.append(Int((bracket.progress * 100).rounded()))
      bracket.pick(.bottom)
    }
    XCTAssertEqual(labels, ["8강 1 / 4", "8강 2 / 4", "8강 3 / 4", "8강 4 / 4", "4강 1 / 2", "4강 2 / 2", "결승 1 / 1"])
    XCTAssertEqual(progress, [0, 14, 29, 43, 57, 71, 86])
    // 아래쪽만 고르면 1→3→5→7, 3·7 → 7
    XCTAssertEqual(bracket.champion, 7)
  }

  func testBracket_winnersPairInWinOrder() {
    var bracket = WorldCupBracket(songCount: 8)
    for side in [WorldCupSide.top, .bottom, .top, .bottom] {
      bracket.pick(side)
    }
    XCTAssertEqual(bracket.pair?.top, 0)
    XCTAssertEqual(bracket.pair?.bottom, 3)
    XCTAssertEqual(WorldCupBracket(songCount: 5).totalMatches, 3)
  }

  func testCrowdSummary() {
    let crowd = WorldCupCrowd(topSongID: "bam", topSongTitle: "밤양갱", topPercent: 32, myChampionRank: 3)
    XCTAssertEqual(crowd.summary(championID: "bam"), "밤양갱 · 32% — 나와 같은 선택이에요!")
    XCTAssertEqual(crowd.summary(championID: "easy"), "밤양갱 · 32% (내 우승곡은 다른 사람들의 3위)")
    let unknown = WorldCupCrowd(topSongID: "bam", topSongTitle: "밤양갱", topPercent: 32, myChampionRank: nil)
    XCTAssertEqual(unknown.summary(championID: "hype"), "밤양갱 · 32% (내 우승곡은 다른 사람들의 상위권)")
  }

  func testPlay_locksDuringPickAndSubmitsChampion() async {
    let clock = TestClock()
    let submitted = LockIsolated<String?>(nil)
    let crowd = WorldCupCrowd(topSongID: "bam", topSongTitle: "밤양갱", topPercent: 32, myChampionRank: nil)
    var initial = SongWorldCupFeature.State(relayID: "summer-idol", topic: "여름")
    initial.songs = WorldCupSong.mock
    initial.bracket = WorldCupBracket(songCount: 8)
    let store = TestStore(initialState: initial) {
      SongWorldCupFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.songWorldCupClient.submit = { _, id in
        submitted.setValue(id)
        return crowd
      }
    }
    store.exhaustivity = .off

    await store.send(.sideTapped(.top)) { $0.picked = .top }
    // 넘어가기 전 다른 탭은 받지 않는다
    await store.send(.sideTapped(.bottom))
    XCTAssertEqual(store.state.picked, .top)
    await clock.advance(by: SongWorldCupFeature.advanceDelay)
    await store.receive(.advance)
    XCTAssertNil(store.state.picked)
    XCTAssertEqual(store.state.bracket.roundLabel, "8강 2 / 4")

    for _ in 0 ..< 6 {
      await store.send(.sideTapped(.top))
      await clock.advance(by: SongWorldCupFeature.advanceDelay)
      await store.receive(.advance)
    }
    XCTAssertEqual(store.state.champion?.id, "bam")
    await store.receive(.crowdLoaded(crowd))
    XCTAssertEqual(submitted.value, "bam")

    await store.send(.restartTapped)
    XCTAssertNil(store.state.champion)
    XCTAssertNil(store.state.crowd)
    XCTAssertEqual(store.state.bracket.roundLabel, "8강 1 / 4")
  }
}

@MainActor
final class SongWorldCupNavigationTests: XCTestCase {
  func testWorldCupRelay_voteOpensWorldCup() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .relay
    var detail = RelayDetail.mock(id: "summer-idol", now: Date(timeIntervalSince1970: 0))
    detail.voteFormat = .worldCup
    initial.relayPath.append(.relayDetail(RelayDetailFeature.State(relayID: "summer-idol", detail: detail)))
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    }
    store.exhaustivity = .off
    let id = initial.relayPath.ids[0]

    await store.send(.relayPath(.element(id: id, action: .relayDetail(.delegate(.showVote(relayID: "summer-idol"))))))
    guard let last = store.state.relayPath.ids.last else { return XCTFail("화면이 열리지 않음") }
    XCTAssertEqual(store.state.relayPath[id: last, case: \.worldCup]?.topic, "첫 사랑이 생각나는 노래 모음")

    await store.send(.relayPath(.element(id: last, action: .worldCup(.closeTapped))))
    await store.receive(.relayPath(.element(id: last, action: .worldCup(.delegate(.dismiss)))))
    XCTAssertEqual(store.state.relayPath.count, 1)
  }
}
