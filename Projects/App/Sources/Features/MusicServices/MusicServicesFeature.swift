import ComposableArchitecture
import Foundation

// REQ-050 · UI-11b · DEC-004 — 음악 서비스 설정
// 연결 해제 · 기본 서비스 · 자동 담기는 먼저 반영하고 실패하면 되돌린다.

@Reducer
struct MusicServicesFeature {
  @ObservableState
  struct State: Equatable {
    var settings: MusicServiceSettings?
    var loadFailed = false
    /// 연결하는 중인 서비스 — 그동안 같은 버튼을 다시 받지 않는다
    var connecting: ExportService?
    var toast: String?
  }

  enum Action: Equatable {
    case onAppear
    case loaded(MusicServiceSettings)
    case loadFailed
    case retryButtonTapped
    case backButtonTapped
    case connectTapped(ExportService)
    case connected(ExportService, detail: String?)
    case connectFailed(ExportService)
    case disconnectTapped(ExportService)
    case defaultSelected(ExportService)
    case autoExportToggled(Bool)
    case saveFailed(previous: MusicServiceSettings)
    case exportedTapped(ExportedPlaylistRow.ID)
    case toastDismissed
    case delegate(MusicServicesDelegate)
  }

  @Dependency(\.musicServicesClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.settings == nil else { return .none }
        return self.load(&state)
      case let .loaded(settings):
        state.settings = settings
        return .none
      case .loadFailed:
        state.loadFailed = true
        return .none
      case .retryButtonTapped:
        return self.load(&state)
      case .backButtonTapped:
        return .send(.delegate(.dismiss))
      case .connectTapped, .connected, .connectFailed, .disconnectTapped:
        return self.connection(&state, action)
      case .defaultSelected, .autoExportToggled, .saveFailed:
        return self.preference(&state, action)
      case let .exportedTapped(id):
        return .send(.delegate(.showExported(playlistID: id)))
      case .toastDismissed:
        state.toast = nil
        return .none
      case .delegate:
        return .none
      }
    }
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.loadFailed = false
    return .run { send in
      do {
        try await send(.loaded(self.client.fetch()))
      } catch {
        await send(.loadFailed)
      }
    }
  }

  // MARK: 연결 · 해제

  private func connection(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case let .connectTapped(service):
      guard state.connecting == nil, state.settings?.isConnected(service) == false else { return .none }
      state.connecting = service
      return .run { send in
        do {
          try await send(.connected(service, detail: self.client.connect(service)))
        } catch {
          await send(.connectFailed(service))
        }
      }
    case let .connected(service, detail):
      state.connecting = nil
      state.settings?.setConnected(service, true, detail: detail)
      return .none
    case let .connectFailed(service):
      state.connecting = nil
      // 원본에 없는 문구 — 디자인 확인 필요
      state.toast = "\(service.name)에 연결하지 못했어요"
      return .none
    case let .disconnectTapped(service):
      guard let previous = state.settings, previous.isConnected(service) else { return .none }
      // 미결정 — 원본은 확인 없이 바로 끊는다(이미 만든 플리는 남고 자동 반영만 멈춤)
      state.settings?.setConnected(service, false)
      return self.save(previous) { try await self.client.disconnect(service) }
    default:
      return .none
    }
  }

  // MARK: 기본 서비스 · 자동 담기

  private func preference(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case let .defaultSelected(service):
      guard let previous = state.settings, previous.isConnected(service), previous.defaultService != service else {
        return .none
      }
      state.settings?.defaultService = service
      return self.save(previous) { try await self.client.setDefault(service) }
    case let .autoExportToggled(isOn):
      guard let previous = state.settings, previous.autoExport != isOn else { return .none }
      state.settings?.autoExport = isOn
      return self.save(previous) { try await self.client.setAutoExport(isOn) }
    case let .saveFailed(previous):
      state.settings = previous
      // 원본에 없는 문구 — 디자인 확인 필요
      state.toast = "설정을 저장하지 못했어요"
      return .none
    default:
      return .none
    }
  }

  private func save(
    _ previous: MusicServiceSettings,
    _ operation: @escaping @Sendable () async throws -> Void
  ) -> Effect<Action> {
    .run { send in
      do {
        try await operation()
      } catch {
        await send(.saveFailed(previous: previous))
      }
    }
  }
}

enum MusicServicesDelegate: Equatable {
  case dismiss
  /// 내보낸 플리(UI-14m)
  case showExported(playlistID: String)
}
