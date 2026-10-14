import ComposableArchitecture
import Foundation

// REQ-082 · UI-5d · DEC-004 — 알림 설정

@Reducer
struct NotificationSettingsFeature {
  @ObservableState
  struct State: Equatable {
    var settings: NotificationSettings?
    var loadFailed = false
    var toast: String?
  }

  enum Action: Equatable {
    case onAppear
    case loaded(NotificationSettings)
    case loadFailed
    case pushToggled(Bool)
    case settingToggled(NotificationSetting, Bool)
    case saved(NotificationSettings)
    case saveFailed(restore: NotificationSettings)
    case quietHoursTapped
    case toastDismissed
    case backButtonTapped
    case delegate(Delegate)
  }

  enum Delegate: Equatable {
    case dismiss
    /// 알림 받지 않는 시간 고르기
    case editQuietHours
  }

  private enum CancelID {
    case save
  }

  @Dependency(\.notificationSettingsClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.settings == nil else { return .none }
        state.loadFailed = false
        return .run { send in
          do {
            try await send(.loaded(self.client.fetch()))
          } catch {
            await send(.loadFailed)
          }
        }

      case let .loaded(settings):
        state.settings = settings
        return .none

      case .loadFailed:
        state.loadFailed = true
        return .none

      case let .pushToggled(isOn):
        guard var settings = state.settings else { return .none }
        let previous = settings
        // 하위 값은 그대로 두고 전체만 끈다(UI-5d)
        settings.isPushEnabled = isOn
        return self.save(settings, previous: previous, in: &state)

      case let .settingToggled(setting, isOn):
        guard var settings = state.settings, settings.isPushEnabled else { return .none }
        let previous = settings
        if isOn {
          settings.enabled.insert(setting)
        } else {
          settings.enabled.remove(setting)
        }
        return self.save(settings, previous: previous, in: &state)

      case let .saved(settings):
        state.settings = settings
        return .none

      case let .saveFailed(restore):
        state.settings = restore
        // 원본에 없는 문구 — 디자인 확인 필요
        state.toast = "설정을 저장하지 못했어요. 잠시 후 다시 시도해 주세요"
        return .none

      case .quietHoursTapped:
        return .send(.delegate(.editQuietHours))

      case .toastDismissed:
        state.toast = nil
        return .none

      case .backButtonTapped:
        return .send(.delegate(.dismiss))

      case .delegate:
        return .none
      }
    }
  }

  /// 화면에 먼저 반영하고 서버에 저장한다. 연달아 바꾸면 마지막 저장만 남긴다.
  private func save(
    _ settings: NotificationSettings,
    previous: NotificationSettings,
    in state: inout State
  ) -> Effect<Action> {
    state.settings = settings
    return .run { send in
      do {
        try await send(.saved(self.client.save(settings)))
      } catch is CancellationError {
        return
      } catch {
        await send(.saveFailed(restore: previous))
      }
    }
    .cancellable(id: CancelID.save, cancelInFlight: true)
  }
}
