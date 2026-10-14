import ComposableArchitecture
import Foundation
import UIKit
import UserNotifications

// REQ-081 — 알림 목록 · 읽음은 백엔드가 정해지기 전까지 목업. 권한은 iOS 실제 API를 쓴다.

struct NotificationsClient {
  var fetch: @Sendable () async throws -> [AppNotification]
  var markRead: @Sendable (_ ids: [AppNotification.ID]) async throws -> Void
  var permission: @Sendable () async -> NotificationPermission
  /// 시스템 권한 창을 띄운다. 허용하면 true
  var requestPermission: @Sendable () async throws -> Bool
  /// 이미 거절했으면 설정 앱의 이 앱 알림 화면을 연다
  var openSettings: @Sendable () async -> Void
}

extension NotificationsClient: DependencyKey {
  static let liveValue = NotificationsClient(
    fetch: { AppNotification.mock },
    markRead: { _ in },
    permission: {
      let settings = await UNUserNotificationCenter.current().notificationSettings()
      switch settings.authorizationStatus {
      case .authorized, .provisional, .ephemeral: return .authorized
      case .denied: return .denied
      case .notDetermined: return .notDetermined
      @unknown default: return .notDetermined
      }
    },
    requestPermission: {
      try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    },
    openSettings: {
      await MainActor.run {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
      }
    }
  )

  static let previewValue = NotificationsClient(
    fetch: { AppNotification.mock },
    markRead: { _ in },
    permission: { .notDetermined },
    requestPermission: { true },
    openSettings: {}
  )

  static let testValue = NotificationsClient(
    fetch: unimplemented("NotificationsClient.fetch", placeholder: []),
    markRead: unimplemented("NotificationsClient.markRead"),
    permission: unimplemented("NotificationsClient.permission", placeholder: .authorized),
    requestPermission: unimplemented("NotificationsClient.requestPermission", placeholder: false),
    openSettings: unimplemented("NotificationsClient.openSettings")
  )
}

extension DependencyValues {
  var notificationsClient: NotificationsClient {
    get { self[NotificationsClient.self] }
    set { self[NotificationsClient.self] = newValue }
  }
}

extension AppNotification {
  /// 원본(UI-4d) 예시 6건 — 알림 문구는 예시(원본 노트 03)
  static let mock: [AppNotification] = [
    AppNotification(
      id: "n1",
      group: .today,
      kind: .relayClosingSoon,
      text: "‘손님들이 물어보는 카페 BGM’ 완성까지 1시간 남았어요. 마지막 투표에 참여해보세요.",
      timeText: "방금",
      actionTitle: "투표하기",
      isRead: false,
      relayID: "cafe-bgm"
    ),
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
    AppNotification(
      id: "n3",
      group: .today,
      kind: .comment,
      text: "boyoung0212_official님이 댓글을 남겼어요: 오~ 이거 듣고 나니까 진짜 봄이 온 기분ㅋㅋ",
      timeText: "2시간 전",
      actionTitle: nil,
      isRead: false
    ),
    AppNotification(
      id: "n4",
      group: .today,
      kind: .like,
      text: "chuuuuu__님 외 23명이 내 게시글을 좋아해요.",
      timeText: "3시간 전",
      actionTitle: nil,
      isRead: false
    ),
    AppNotification(
      id: "n5",
      group: .thisWeek,
      kind: .relayCompleted,
      text: "‘첫 사랑이 생각나는 노래 모음’ 릴레이리스트가 완성되었어요 🎉",
      timeText: "2일 전",
      actionTitle: "듣기",
      isRead: true,
      relayID: "first-love"
    ),
    AppNotification(
      id: "n6",
      group: .thisWeek,
      kind: .follow,
      text: "woogi님이 나를 팔로우하기 시작했어요.",
      timeText: "4일 전",
      actionTitle: "맞팔로우",
      isRead: true
    ),
  ]
}
