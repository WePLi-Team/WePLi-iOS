import ComposableArchitecture
import Foundation

// REQ-112 · UI-7d · DEC-014 — 앱 시작 때 서버 설정을 받아, 겹치면 강제 업데이트 > 점검 > 오프라인 > 이용 제한 > 이벤트 하나만 보인다.

@Reducer
struct SystemStatusFeature {
  @ObservableState
  struct State: Equatable {
    var config: SystemConfig?
    var isOffline = false
    var restriction: CommunityRestriction?
    /// 이번 실행에서 닫은 이벤트 · 이용 제한 안내
    var closedEventID: String?
    var closedRestriction = false
    var eventHiddenToday = false
    var retryCount = 0
    var now = Date()
    var appVersion = ""
    /// 이용 제한 시트에서 연 이의 신청(UI-11d)
    @Presents var appeal: AppealFeature.State?

    /// 겹치면 강제 업데이트 > 점검 > 오프라인 > 이용 제한 > 이벤트(DEC-014)
    var status: SystemStatus? {
      if let update = SystemStatus.forceUpdate(self.config, appVersion: self.appVersion) {
        return update
      }
      if let maintenance = self.config?.maintenance, self.now < maintenance.endsAt {
        return .maintenance(maintenance)
      }
      if self.isOffline {
        return .offline
      }
      if let restriction = self.restriction, !self.closedRestriction, self.now < restriction.until {
        return .restricted(restriction)
      }
      guard let event = self.config?.event, !self.eventHiddenToday, self.closedEventID != event.id else { return nil }
      return .event(event)
    }
  }

  enum Action: Equatable {
    case launched
    case configLoaded(SystemConfig)
    case offlineChanged(Bool)
    case retryTapped
    case updateTapped
    case restrictionReceived(CommunityRestriction)
    case restrictionClosed
    case appealTapped
    case appeal(PresentationAction<AppealFeature.Action>)
    case eventClosed
    case eventHiddenToday
  }

  enum CancelID {
    case network
  }

  @Dependency(\.systemStatusClient)
  var client

  @Dependency(\.date.now)
  var date

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .launched:
        state.now = self.date
        state.appVersion = self.client.appVersion()
        return .merge(self.loadConfig(), self.watchNetwork())
      case let .configLoaded(config):
        state.config = config
        if let event = config.event {
          state.eventHiddenToday = self.client.hiddenEventDay(event.id) == SystemStatusText.dayKey(self.date)
        }
        return .none
      case let .offlineChanged(isOffline):
        state.isOffline = isOffline
        state.now = self.date
        return .none
      case .retryTapped:
        // 연결은 네트워크 감지가 알려준다 — 설정을 다시 받아 점검 · 업데이트도 다시 본다
        state.retryCount += 1
        state.now = self.date
        return self.loadConfig()
      case .updateTapped:
        return .run { _ in await self.client.openAppStore() }
      case let .restrictionReceived(restriction):
        state.restriction = restriction
        state.closedRestriction = false
        state.now = self.date
        return .none
      case .restrictionClosed:
        state.closedRestriction = true
        state.appeal = nil
        return .none
      case .appealTapped:
        guard let restriction = state.restriction else { return .none }
        state.appeal = AppealFeature.State(target: restriction.appealTarget)
        return .none
      case .appeal(.presented(.delegate(.dismiss))):
        state.appeal = nil
        return .none
      case .appeal:
        return .none
      case .eventClosed:
        state.closedEventID = state.config?.event?.id
        return .none
      case .eventHiddenToday:
        guard let event = state.config?.event else { return .none }
        state.eventHiddenToday = true
        let day = SystemStatusText.dayKey(self.date)
        return .run { _ in self.client.hideEvent(event.id, day) }
      }
    }
    .ifLet(\.$appeal, action: \.appeal) { AppealFeature() }
  }

  private func loadConfig() -> Effect<Action> {
    .run { send in
      // 설정을 못 받으면 막지 않는다(오프라인은 네트워크 감지가 따로 알려준다)
      if let config = try? await self.client.config() {
        await send(.configLoaded(config))
      }
    }
  }

  private func watchNetwork() -> Effect<Action> {
    .run { send in
      for await isOffline in self.client.offlineUpdates() {
        await send(.offlineChanged(isOffline))
      }
    }
    .cancellable(id: CancelID.network, cancelInFlight: true)
  }
}
