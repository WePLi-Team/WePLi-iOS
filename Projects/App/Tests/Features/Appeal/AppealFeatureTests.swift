import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-073 · UI-11d · DEC-024

@MainActor
final class AppealFeatureTests: XCTestCase {
  private let target = AppealTarget(id: "post-1", kind: .post, title: "비 오는 날 듣는 플리", reason: "욕설 · 비하 표현 신고 누적")

  func testTexts() {
    XCTAssertEqual(self.target.label, "대상 게시글")
    XCTAssertEqual(self.target.reasonLine, "가려진 사유 · 욕설 · 비하 표현 신고 누적")
    XCTAssertEqual(AppealStep.afterSending.map(\.detail), ["방금", "24시간 안에", "알림 · 내 문의 내역"])
  }

  func testSend_needsReasonAndTextThenShowsTimeline() async {
    let sent = LockIsolated<AppealReason?>(nil)
    let store = TestStore(initialState: AppealFeature.State(target: self.target)) { AppealFeature()
    } withDependencies: {
      $0.appealClient.submit = { _, reason, _ in sent.setValue(reason) }
    }
    // 사유 · 설명이 없으면 보내지 않는다
    await store.send(.sendTapped)
    await store.send(.reasonSelected(.missingContext)) { $0.draft.reason = .missingContext }
    await store.send(.textChanged("   ")) { $0.draft.text = "   " }
    await store.send(.sendTapped)
    let long = String(repeating: "가", count: 510)
    await store.send(.textChanged(long)) { $0.draft.text = String(repeating: "가", count: 500) }
    await store.send(.sendTapped) { $0.isSending = true }
    await store.receive(.sent) {
      $0.isSending = false
      $0.isSent = true
    }
    XCTAssertEqual(sent.value, .missingContext)
    // 보낸 뒤에는 다시 보내지 않는다
    await store.send(.sendTapped)
  }

  func testSend_alreadyAppealedShowsToast() async {
    var initial = AppealFeature.State(target: self.target)
    initial.draft = AppealDraft(reason: .other, text: "다시 봐 주세요")
    let store = TestStore(initialState: initial) { AppealFeature() } withDependencies: {
      $0.appealClient.submit = { _, _, _ in throw AppealError.alreadyAppealed }
    }
    await store.send(.sendTapped) { $0.isSending = true }
    await store.receive(.sendFailed(alreadyAppealed: true)) {
      $0.isSending = false
      $0.toast = "이미 이의 신청한 내용이에요. 결과를 알려드릴게요"
    }
  }
}
