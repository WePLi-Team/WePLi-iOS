import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-081 · UI-4d

@MainActor
final class NotificationsFeatureTests: XCTestCase {
  private func loaded(permission: NotificationPermission = .authorized) -> NotificationsFeature.State {
    var state = NotificationsFeature.State()
    state.notifications = IdentifiedArray(uniqueElements: AppNotification.mock)
    state.permission = permission
    return state
  }

  func testOnAppear_checksPermissionAndLoads() async {
    let store = TestStore(initialState: NotificationsFeature.State()) {
      NotificationsFeature()
    } withDependencies: {
      $0.notificationsClient.permission = { .notDetermined }
      $0.notificationsClient.fetch = { AppNotification.mock }
    }

    await store.send(.onAppear) {
      $0.isLoading = true
    }
    await store.receive(.permissionChecked(.notDetermined)) {
      $0.permission = .notDetermined
    }
    await store.receive(.loaded(AppNotification.mock)) {
      $0.isLoading = false
      $0.notifications = IdentifiedArray(uniqueElements: AppNotification.mock)
    }
    XCTAssertEqual(store.state.unreadCount, 4)
    XCTAssertTrue(store.state.permission.showsPrompt)
  }

  func testTap_marksReadAndOpens() async {
    let marked = LockIsolated<[String]>([])
    let store = TestStore(initialState: self.loaded()) {
      NotificationsFeature()
    } withDependencies: {
      $0.notificationsClient.markRead = { ids in marked.withValue { $0 += ids } }
    }

    await store.send(.notificationTapped("n2")) {
      $0.notifications[id: "n2"]?.isRead = true
    }
    await store.receive(.delegate(.open("n2")))
    await store.finish()
    XCTAssertEqual(marked.value, ["n2"])
    XCTAssertEqual(store.state.unreadCount, 3)
  }

  func testTapOnRead_opensWithoutMarking() async {
    let store = TestStore(initialState: self.loaded()) {
      NotificationsFeature()
    }

    await store.send(.notificationTapped("n5"))
    await store.receive(.delegate(.open("n5")))
  }

  func testMarkAll_marksOnlyUnread() async {
    let marked = LockIsolated<[String]>([])
    let store = TestStore(initialState: self.loaded()) {
      NotificationsFeature()
    } withDependencies: {
      $0.notificationsClient.markRead = { ids in marked.setValue(ids) }
    }

    await store.send(.markAllReadButtonTapped) {
      for id in ["n1", "n2", "n3", "n4"] {
        $0.notifications[id: id]?.isRead = true
      }
    }
    await store.finish()
    XCTAssertEqual(marked.value, ["n1", "n2", "n3", "n4"])
    XCTAssertEqual(store.state.unreadCount, 0)
  }

  func testEnable_requestsPermissionWhenNotDetermined() async {
    let store = TestStore(initialState: self.loaded(permission: .notDetermined)) {
      NotificationsFeature()
    } withDependencies: {
      $0.notificationsClient.requestPermission = { true }
    }

    await store.send(.enableButtonTapped)
    await store.receive(.permissionChecked(.authorized)) {
      $0.permission = .authorized
    }
  }

  func testEnable_opensSettingsWhenDenied() async {
    let opened = LockIsolated(false)
    let store = TestStore(initialState: self.loaded(permission: .denied)) {
      NotificationsFeature()
    } withDependencies: {
      $0.notificationsClient.openSettings = { opened.setValue(true) }
    }

    await store.send(.enableButtonTapped)
    await store.finish()
    XCTAssertTrue(opened.value)
  }

  func testAvatarShape_followsKind() {
    XCTAssertTrue(AppNotification.Kind.follow.showsAvatar)
    XCTAssertFalse(AppNotification.Kind.relayClosingSoon.showsAvatar)
  }
}
