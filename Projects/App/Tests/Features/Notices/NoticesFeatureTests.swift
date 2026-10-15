import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-110 · UI-7a

@MainActor
final class NoticesFeatureTests: XCTestCase {
  func testList_pinnedFirstPerTab() {
    var notices = Notice.mock
    // 고정 글이 뒤에 와도 맨 위로 올린다
    notices.append(Notice(id: "late-pin", kind: .notice, title: "고정", dateText: "", body: "", isPinned: true))
    XCTAssertEqual(notices.list(for: .notice).map(\.id), ["maintenance", "late-pin", "vote-change", "policy", "launch"])
    XCTAssertEqual(notices.list(for: .event).map(\.id), ["instagram", "chart"])
  }

  func testOpen_marksReadAndBackReturnsToList() async {
    let read = LockIsolated<[String]>([])
    var state = NoticesFeature.State()
    state.notices = Notice.mock
    let store = TestStore(initialState: state) { NoticesFeature() } withDependencies: {
      $0.noticesClient.markRead = { id in read.withValue { $0.append(id) } }
    }
    await store.send(.noticeTapped("vote-change")) {
      $0.selectedID = "vote-change"
      $0.notices?[1].isUnread = false
    }
    XCTAssertEqual(read.value, ["vote-change"])
    await store.send(.backButtonTapped) { $0.selectedID = nil }
    // 이미 읽은 글은 다시 보내지 않는다
    await store.send(.noticeTapped("policy")) { $0.selectedID = "policy" }
    await store.send(.backToListTapped) { $0.selectedID = nil }
    await store.send(.backButtonTapped)
    await store.receive(.delegate(.dismiss))
  }

  func testTab_clearsSelection() async {
    var state = NoticesFeature.State()
    state.notices = Notice.mock
    state.selectedID = "launch"
    let store = TestStore(initialState: state) { NoticesFeature() }
    await store.send(.tabSelected(.event)) {
      $0.tab = .event
      $0.selectedID = nil
    }
    XCTAssertEqual(store.state.list.first?.eventStatus, .ongoing)
  }
}
