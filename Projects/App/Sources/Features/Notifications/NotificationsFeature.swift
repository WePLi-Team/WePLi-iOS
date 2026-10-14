import ComposableArchitecture
import Foundation
import OSLog

// REQ-081 · UI-4d — 알림

@Reducer
struct NotificationsFeature {
  @ObservableState
  struct State: Equatable {
    var notifications: IdentifiedArrayOf<AppNotification> = []
    var permission: NotificationPermission = .authorized
    var isLoading = false
    var loadFailed = false

    /// 종 아이콘 배지 수
    var unreadCount: Int {
      self.notifications.filter { !$0.isRead }.count
    }

    func items(in group: AppNotification.Group) -> [AppNotification] {
      self.notifications.filter { $0.group == group }
    }
  }

  enum Action: Equatable {
    case onAppear
    case loaded([AppNotification])
    case loadFailed
    case permissionChecked(NotificationPermission)
    case enableButtonTapped
    case notificationTapped(AppNotification.ID)
    case markAllReadButtonTapped
    case backButtonTapped
    case delegate(Delegate)
  }

  enum Delegate: Equatable {
    case dismiss
    /// 알림이 가리키는 화면으로 — 각 화면이 연결되면 상위에서 처리
    case open(AppNotification.ID)
  }

  @Dependency(\.notificationsClient)
  var client

  private static let logger = Logger(subsystem: "com.wepli", category: "Notifications")

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.loadFailed = false
        state.isLoading = state.notifications.isEmpty
        return .run { send in
          await send(.permissionChecked(self.client.permission()))
          do {
            try await send(.loaded(self.client.fetch()))
          } catch {
            await send(.loadFailed)
          }
        }

      case let .loaded(items):
        state.isLoading = false
        state.notifications = IdentifiedArray(uniqueElements: items)
        return .none

      case .loadFailed:
        state.isLoading = false
        state.loadFailed = true
        return .none

      case let .permissionChecked(permission):
        state.permission = permission
        return .none

      case .enableButtonTapped:
        // iOS 권한 창은 한 번 거절하면 다시 띄울 수 없어 설정 앱으로 보낸다
        if state.permission == .denied {
          return .run { _ in await self.client.openSettings() }
        }
        return .run { send in
          let granted = await (try? self.client.requestPermission()) ?? false
          await send(.permissionChecked(granted ? .authorized : .denied))
        }

      case let .notificationTapped(id):
        guard state.notifications[id: id] != nil else { return .none }
        let wasUnread = state.notifications[id: id]?.isRead == false
        state.notifications[id: id]?.isRead = true
        let open: Effect<Action> = .send(.delegate(.open(id)))
        return wasUnread ? .merge(self.markRead([id]), open) : open

      case .markAllReadButtonTapped:
        let ids = state.notifications.filter { !$0.isRead }.map(\.id)
        guard !ids.isEmpty else { return .none }
        for id in ids {
          state.notifications[id: id]?.isRead = true
        }
        return self.markRead(ids)

      case .backButtonTapped:
        return .send(.delegate(.dismiss))

      case .delegate:
        return .none
      }
    }
  }

  /// 읽음은 화면에 먼저 반영한다. 서버 반영 실패는 다음 불러오기 때 서버 값으로 맞춰지므로 기록만 남긴다.
  private func markRead(_ ids: [AppNotification.ID]) -> Effect<Action> {
    .run { _ in
      do {
        try await self.client.markRead(ids)
      } catch {
        Self.logger.error("알림 읽음 처리 실패: \(ids.count, privacy: .public)건")
      }
    }
  }
}
