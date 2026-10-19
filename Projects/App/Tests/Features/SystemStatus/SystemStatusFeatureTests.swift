import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-112 · UI-7d · DEC-014

@MainActor
final class SystemStatusFeatureTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1792079276)

  private var event: SystemConfig.Event {
    SystemConfig.Event(id: "e", title: "위플리", body: "본문")
  }

  private var restriction: CommunityRestriction {
    CommunityRestriction(reason: "신고 누적", days: 7, until: self.now.addingTimeInterval(7 * 86400), scope: "게시글")
  }

  func testPriority_updateThenMaintenanceThenOfflineThenRestrictionThenEvent() {
    let update = SystemConfig.Update(latest: "1.2.0", reason: "투표 방식이 바뀌어서 업데이트가 필요해요.")
    let maintenance = SystemConfig.Maintenance(
      window: "10월 15일 02:00 – 05:00",
      endsAt: self.now.addingTimeInterval(4800)
    )
    var state = SystemStatusFeature.State()
    state.config = SystemConfig(minimumVersion: "1.2.0", update: update, maintenance: maintenance, event: self.event)
    state.appVersion = "1.0.0"
    state.now = self.now
    state.isOffline = true
    state.restriction = self.restriction
    XCTAssertEqual(state.status, .forceUpdate(current: "1.0.0", update))
    state.config?.minimumVersion = "1.0.0"
    XCTAssertEqual(state.status, .maintenance(maintenance))
    state.config?.maintenance = nil
    XCTAssertEqual(state.status, .offline)
    state.isOffline = false
    XCTAssertEqual(state.status, .restricted(self.restriction))
    state.closedRestriction = true
    XCTAssertEqual(state.status, .event(self.event))
    XCTAssertEqual(SystemStatusText.remaining(from: self.now, to: maintenance.endsAt), "약 1시간 20분")
  }

  func testEvent_hideTodayStoresSeoulDay() async {
    let stored = LockIsolated<String?>(nil)
    let event = self.event
    let store = TestStore(initialState: SystemStatusFeature.State()) { SystemStatusFeature() } withDependencies: {
      $0.date.now = self.now
      $0.systemStatusClient.config = { SystemConfig(event: event) }
      $0.systemStatusClient.hideEvent = { _, day in stored.setValue(day) }
    }
    await store.send(.launched) {
      $0.now = self.now
      $0.appVersion = "1.0.0"
    }
    await store.receive(.configLoaded(SystemConfig(event: self.event))) { $0.config = SystemConfig(event: self.event) }
    XCTAssertEqual(store.state.status, .event(self.event))
    await store.send(.eventHiddenToday) { $0.eventHiddenToday = true }
    XCTAssertNil(store.state.status)
    XCTAssertEqual(stored.value, "2026-10-16")
  }

  func testEvent_alreadyHiddenToday() async {
    let event = self.event
    let store = TestStore(initialState: SystemStatusFeature.State()) { SystemStatusFeature() } withDependencies: {
      $0.date.now = self.now
      $0.systemStatusClient.config = { SystemConfig(event: event) }
      $0.systemStatusClient.hiddenEventDay = { _ in "2026-10-16" }
    }
    await store.send(.launched) {
      $0.now = self.now
      $0.appVersion = "1.0.0"
    }
    await store.receive(.configLoaded(SystemConfig(event: self.event))) {
      $0.config = SystemConfig(event: self.event)
      $0.eventHiddenToday = true
    }
    XCTAssertNil(store.state.status)
  }

  func testRestriction_canBeClosed() async {
    let store = TestStore(initialState: SystemStatusFeature.State()) { SystemStatusFeature() } withDependencies: {
      $0.date.now = self.now
    }
    await store.send(.restrictionReceived(self.restriction)) {
      $0.restriction = self.restriction
      $0.now = self.now
    }
    XCTAssertEqual(store.state.status, .restricted(self.restriction))
    await store.send(.restrictionClosed) { $0.closedRestriction = true }
    XCTAssertNil(store.state.status)
  }
}
