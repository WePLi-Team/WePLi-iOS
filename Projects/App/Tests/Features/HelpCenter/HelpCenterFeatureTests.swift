import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-111 · UI-7b

@MainActor
final class HelpCenterFeatureTests: XCTestCase {
  func testFAQ_secondOpenByDefaultAndToggles() async {
    let store = TestStore(initialState: HelpCenterFeature.State()) { HelpCenterFeature() }
    XCTAssertEqual(store.state.openFAQs, [1])
    await store.send(.faqTapped(0)) { $0.openFAQs = [0, 1] }
    await store.send(.faqTapped(1)) { $0.openFAQs = [0] }
  }

  func testDraft_limitsAndValidation() async {
    let store = TestStore(initialState: HelpCenterFeature.State()) { HelpCenterFeature() }
    await store.send(.composeTapped) { $0.isComposing = true }
    await store.send(.textChanged("   ")) { $0.draft.text = "   " }
    XCTAssertFalse(store.state.draft.canSend)
    await store.send(.categorySelected(.relay)) { $0.draft.category = .relay }
    XCTAssertFalse(store.state.draft.canSend)
    let long = String(repeating: "가", count: 1005)
    await store.send(.textChanged(long)) { $0.draft.text = String(repeating: "가", count: 1000) }
    XCTAssertTrue(store.state.draft.canSend)
    XCTAssertEqual(store.state.draft.title.count, 24)
    let photo = Data([1])
    await store.send(.photosPicked([photo, photo])) { $0.draft.photos = [photo, photo] }
    await store.send(.photosPicked([photo, photo])) { $0.draft.photos = [photo, photo, photo] }
    await store.send(.photoRemoved(0)) { $0.draft.photos = [photo, photo] }
    // 닫아도 쓰던 내용은 남는다
    await store.send(.composeDismissed) { $0.isComposing = false }
    XCTAssertEqual(store.state.draft.category, .relay)
  }

  func testSend_addsPendingInquiryOnTop() async {
    var state = HelpCenterFeature.State()
    state.inquiries = [Inquiry(
      id: "q1",
      title: "투표가 반영되지 않아요",
      category: .relay,
      dateText: "2026.09.28",
      isAnswered: true
    )]
    state.isComposing = true
    state.draft.category = .community
    state.draft.text = "게시글이 안 올라가요"
    let inquiry = Inquiry(id: "q2", title: "게시글이 안 올라가요", category: .community, dateText: "방금", isAnswered: false)
    let device = LockIsolated<InquiryDeviceInfo?>(nil)
    let store = TestStore(initialState: state) { HelpCenterFeature() } withDependencies: {
      $0.helpCenterClient.submit = { _, info in
        device.setValue(info)
        return inquiry
      }
    }
    await store.send(.sendTapped) { $0.isSending = true }
    await store.receive(.sent(inquiry)) {
      $0.isSending = false
      $0.inquiries.insert(inquiry, at: 0)
      $0.draft = InquiryDraft()
      $0.isComposing = false
      $0.toast = "문의를 보냈어요. 답변은 이메일로도 알려드려요"
    }
    XCTAssertEqual(device.value?.appVersion, "1.0.0")
  }
}

extension MainTabFeatureTests {
  func testHelpCenterMenu_opensHelpCenter() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .my
    let store = TestStore(initialState: initial) { MainTabFeature() }
    store.exhaustivity = .off
    await store.send(.my(.menuTapped(.helpCenter)))
    await store.receive(.my(.delegate(.show(.helpCenter))))
    guard case .helpCenter? = store.state.myPath.last else { return XCTFail("고객센터가 열려야 한다") }
  }
}
