import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-101 · UI-6c

@MainActor
final class DailySongFeatureTests: XCTestCase {
  /// 2026-10-16 00:47:56 KST
  private let now = Date(timeIntervalSince1970: 1792079276)

  func testTexts_useSeoulTime() {
    XCTAssertEqual(DailySongText.dateTitle(self.now), "10월 16일의 질문")
    let midnight = DailySongText.nextMidnight(after: self.now)
    XCTAssertEqual(DailySongText.remaining(from: self.now, to: midnight), "23:12:04 남음")
    XCTAssertEqual(DailySongText.remaining(from: midnight.addingTimeInterval(5), to: midnight), "00:00:00 남음")
    let question = DailyQuestion.mock(now: self.now)
    XCTAssertEqual(question.top.map { question.percent($0) }, [33, 24, 21])
  }

  func testAnswer_pickSongThenServerCountReplaces() async {
    var state = DailySongFeature.State()
    state.question = .mock(now: self.now)
    var served = DailyQuestion.mock(now: self.now)
    served.myAnswer = .init(title: "비와 당신", artist: "이무진")
    served.answerCount = 2482
    let store = TestStore(initialState: state) { DailySongFeature() } withDependencies: {
      $0.dailySongClient.answer = { [served] _, _ in served }
    }
    await store.send(.pickTapped) { $0.picker = SongPickerFeature.State() }
    let track = ComposeTrack(id: "t", title: "비와 당신", artist: "이무진")
    await store.send(.picker(.presented(.delegate(.add([track]))))) {
      $0.picker = nil
      $0.question?.myAnswer = .init(title: "비와 당신", artist: "이무진")
      $0.isSending = true
    }
    await store.receive(.answered(served)) {
      $0.isSending = false
      $0.question = served
    }
    XCTAssertTrue(store.state.hasAnswered)
  }

  func testAnswerFailure_restoresPrevious() async {
    struct Failure: Error {}
    var state = DailySongFeature.State()
    state.question = .mock(now: self.now)
    state.picker = SongPickerFeature.State()
    let store = TestStore(initialState: state) { DailySongFeature() } withDependencies: {
      $0.dailySongClient.answer = { _, _ in throw Failure() }
    }
    let track = ComposeTrack(id: "t", title: "밤양갱", artist: "비비 (BIBI)")
    await store.send(.picker(.presented(.delegate(.add([track]))))) {
      $0.picker = nil
      $0.question?.myAnswer = .init(title: "밤양갱", artist: "비비 (BIBI)")
      $0.isSending = true
    }
    await store.receive(.answerFailed(nil)) {
      $0.isSending = false
      $0.question?.myAnswer = nil
      $0.toast = "답하지 못했어요. 다시 시도해 주세요"
    }
  }
}

extension MainTabFeatureTests {
  func testHomeTodayHeader_opensDailySong() async {
    var initial = MainTabFeature.State()
    initial.home.feed = .mock(now: Date(timeIntervalSince1970: 1800000000))
    let store = TestStore(initialState: initial) { MainTabFeature() }
    store.exhaustivity = .off
    await store.send(.home(.todayHeaderTapped))
    await store.skipReceivedActions()
    guard case .dailySong? = store.state.homePath.last else { return XCTFail("오늘의 한 곡이 열려야 한다") }
  }
}
