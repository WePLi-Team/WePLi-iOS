import ComposableArchitecture
@testable import WePLi
import XCTest

// UI-17a · DEC-024 · DEC-025

@MainActor
final class InquiryHistoryTests: XCTestCase {
  private let samples = MockInquiries.samples

  func testStatus_kindAndUnreadDot() {
    XCTAssertEqual(self.samples.map(\.status), [.answered, .accepted, .waiting])
    XCTAssertEqual(self.samples.map(\.status.title), ["답변 완료", "받아들여짐", "답변 대기"])
    XCTAssertEqual(self.samples.map(\.kindTitle), ["1:1 문의", "이의 신청 결과", "1:1 문의"])
    XCTAssertEqual(self.samples.map(\.meta), ["릴레이 · 투표 · 2026.09.28", "게시글 · 2026.10.19", "계정 · 로그인 · 방금"])
    XCTAssertEqual(self.samples.map(\.showsUnreadDot), [true, true, false])
    // 답변 대기는 읽지 않았어도 점이 없다
    var waiting = self.samples[2]
    waiting.isRead = false
    XCTAssertFalse(waiting.showsUnreadDot)
  }

  func testRowTap_marksReadThenOpensDetail() async {
    let read = LockIsolated<[Inquiry.ID]>([])
    let store = TestStore(initialState: InquiryHistoryFeature.State(inquiries: self.samples)) {
      InquiryHistoryFeature()
    } withDependencies: {
      $0.helpCenterClient.markRead = { id in read.withValue { $0.append(id) } }
    }
    var opened = self.samples[1]
    opened.isRead = true
    await store.send(.rowTapped("a1")) { $0.inquiries?[1].isRead = true }
    await store.receive(.delegate(.showInquiry(opened)))
    XCTAssertEqual(read.value, ["a1"])
  }

  func testRowTap_readFailureRestoresDot() async {
    let store = TestStore(initialState: InquiryHistoryFeature.State(inquiries: self.samples)) {
      InquiryHistoryFeature()
    } withDependencies: {
      $0.helpCenterClient.markRead = { _ in throw CancellationError() }
    }
    store.exhaustivity = .off
    await store.send(.rowTapped("q1")) { $0.inquiries?[0].isRead = true }
    await store.receive(.readFailed("q1")) { $0.inquiries?[0].isRead = false }
  }

  func testAlreadyRead_opensWithoutCall() async {
    let store = TestStore(initialState: InquiryHistoryFeature.State(inquiries: self.samples)) {
      InquiryHistoryFeature()
    }
    await store.send(.rowTapped("q2"))
    await store.receive(.delegate(.showInquiry(self.samples[2])))
  }

  func testHelpful_optimisticAndRollback() async {
    let store = TestStore(initialState: InquiryDetailFeature.State(inquiry: self.samples[0])) {
      InquiryDetailFeature()
    } withDependencies: {
      $0.helpCenterClient.rateAnswer = { _, _ in throw CancellationError() }
    }
    await store.send(.helpfulTapped(true)) { $0.inquiry.isHelpful = true }
    await store.receive(.rateFailed(previous: nil)) {
      $0.inquiry.isHelpful = nil
      $0.toast = InquiryText.failedToast
    }
  }

  func testFollowUp_keepsCategory() async {
    let store = TestStore(initialState: InquiryDetailFeature.State(inquiry: self.samples[0])) {
      InquiryDetailFeature()
    }
    XCTAssertEqual(store.state.title, "문의 답변")
    await store.send(.followUpTapped)
    await store.receive(.delegate(.followUp(.relay)))
  }

  func testAppealResult_opensRestoredPost() async {
    let store = TestStore(initialState: InquiryDetailFeature.State(inquiry: self.samples[1])) {
      InquiryDetailFeature()
    }
    XCTAssertEqual(store.state.title, "이의 신청 결과")
    await store.send(.showPostTapped)
    await store.receive(.delegate(.showPost("p1")))
  }

  func testCancel_confirmThenDelegate() async {
    let cancelled = LockIsolated<Inquiry.ID?>(nil)
    let store = TestStore(initialState: InquiryDetailFeature.State(inquiry: self.samples[2])) {
      InquiryDetailFeature()
    } withDependencies: {
      $0.helpCenterClient.cancel = { cancelled.setValue($0) }
    }
    store.exhaustivity = .off
    await store.send(.cancelTapped)
    XCTAssertNotNil(store.state.cancelDialog)
    await store.send(.cancelDialog(.presented(.confirm))) { $0.isCancelling = true }
    await store.receive(.cancelled) { $0.isCancelling = false }
    await store.receive(.delegate(.cancelled("q2")))
    XCTAssertEqual(cancelled.value, "q2")
  }

  func testCancel_onlyWhileWaiting() async {
    let store = TestStore(initialState: InquiryDetailFeature.State(inquiry: self.samples[0])) {
      InquiryDetailFeature()
    }
    await store.send(.cancelTapped)
  }
}

extension MainTabFeatureTests {
  private func myTabWithHelpCenter() -> MainTabFeature.State {
    var initial = MainTabFeature.State()
    initial.selectedTab = .my
    initial.myPath.append(.helpCenter(HelpCenterFeature.State(inquiries: MockInquiries.samples)))
    return initial
  }

  func testHelpCenterInquiry_opensDetailAndFollowUpReturnsToComposer() async throws {
    // 지연 효과가 sleep을 걸기 전에 advance하면 CI에서 놓친다 → 바로 지나가는 시계
    let clock = ImmediateClock()
    let store = TestStore(initialState: self.myTabWithHelpCenter()) { MainTabFeature() } withDependencies: {
      $0.helpCenterClient.markRead = { _ in }
      $0.continuousClock = clock
    }
    store.exhaustivity = .off
    let helpID = try XCTUnwrap(store.state.myPath.ids.first)
    await store.send(.myPath(.element(id: helpID, action: .helpCenter(.inquiryTapped("q1")))))
    await store.receive(\.myPath)
    await store.receive(\.myPath)
    guard case let .inquiryDetail(detail)? = store.state.myPath.last else { return XCTFail("문의 상세가 열려야 한다") }
    XCTAssertTrue(detail.inquiry.isRead)
    let detailID = try XCTUnwrap(store.state.myPath.ids.last)
    await store.send(.myPath(.element(id: detailID, action: .inquiryDetail(.followUpTapped))))
    await store.receive(\.myPath)
    XCTAssertEqual(store.state.myPath.count, 1)
    await store.receive(\.myPath)
    let help = store.state.myPath[id: helpID, case: \.helpCenter]
    XCTAssertEqual(help?.isComposing, true)
    XCTAssertEqual(help?.draft.category, .relay)
  }

  func testInquiryCancel_popsAndRemovesFromHelpCenter() async throws {
    var initial = self.myTabWithHelpCenter()
    initial.myPath.append(.inquiryDetail(InquiryDetailFeature.State(inquiry: MockInquiries.samples[2])))
    let store = TestStore(initialState: initial) { MainTabFeature() }
    store.exhaustivity = .off
    let helpID = try XCTUnwrap(store.state.myPath.ids.first)
    let detailID = try XCTUnwrap(store.state.myPath.ids.last)
    await store.send(.myPath(.element(id: detailID, action: .inquiryDetail(.delegate(.cancelled("q2"))))))
    await store.receive(\.myPath)
    XCTAssertEqual(store.state.myPath.count, 1)
    let help = store.state.myPath[id: helpID, case: \.helpCenter]
    XCTAssertEqual(help?.inquiries.map(\.id), ["q1", "a1"])
    XCTAssertEqual(help?.toast, InquiryText.cancelledToast)
  }

  func testInquiryHistoryEmptyCompose_opensHelpCenterComposer() async throws {
    var initial = MainTabFeature.State()
    initial.selectedTab = .my
    initial.myPath.append(.inquiryHistory(InquiryHistoryFeature.State(inquiries: [])))
    let store = TestStore(initialState: initial) { MainTabFeature() }
    store.exhaustivity = .off
    let historyID = try XCTUnwrap(store.state.myPath.ids.first)
    await store.send(.myPath(.element(id: historyID, action: .inquiryHistory(.composeTapped))))
    await store.receive(\.myPath)
    guard case let .helpCenter(help)? = store.state.myPath.last else { return XCTFail("고객센터가 열려야 한다") }
    XCTAssertTrue(help.isComposing)
  }
}
