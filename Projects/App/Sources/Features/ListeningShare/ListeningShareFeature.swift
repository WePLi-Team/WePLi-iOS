import ComposableArchitecture
import Foundation

// REQ-079 · UI-13a · DEC-004 — 지금 듣는 음악: 연결과 공개 범위(전체 화면)
// 1 음악 서비스 연결(하나 이상 연결해야 다음) → 2 공개 범위 → 연결했어요

@Reducer
struct ListeningShareFeature {
  @ObservableState
  struct State: Equatable {
    var nickname: String
    var step: ListeningShareStep = .connect
    var connected: Set<ListeningService> = []
    var connecting: ListeningService?
    var groups: [String] = []
    var settings = ListeningShareSettings()
    var isSaving = false
    var toast: String?

    init(nickname: String) {
      self.nickname = nickname
    }

    var canContinue: Bool {
      !self.connected.isEmpty
    }
  }

  enum Action: Equatable {
    case onAppear
    case groupsLoaded([String])
    case closeTapped
    case stepTapped(ListeningShareStep)
    case serviceTapped(ListeningService)
    case connectResult(ListeningService, Bool)
    case nextTapped
    case visibilitySelected(ListeningVisibility)
    case groupToggled(String)
    case showsRecentToggled(Bool)
    case hidesAtNightToggled(Bool)
    case doneTapped
    case saved
    case requestFailed(String)
    case toastDismissed
    case delegate(ListeningShareDelegate)
  }

  @Dependency(\.listeningShareClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.groups.isEmpty else { return .none }
        return .run { send in
          await send(.groupsLoaded((try? self.client.groups()) ?? []))
        }
      case let .groupsLoaded(groups):
        state.groups = groups
        // 원본 예시는 첫 그룹이 골라져 있다
        if state.settings.groups.isEmpty, let first = groups.first {
          state.settings.groups = [first]
        }
        return .none
      case .closeTapped:
        return .send(.delegate(.dismiss))
      case let .stepTapped(step):
        // 공개 범위는 하나 이상 연결해야 갈 수 있다
        guard step == .connect || state.canContinue else { return .none }
        state.step = step
        return .none
      case .serviceTapped, .connectResult, .nextTapped:
        return self.connection(&state, action)
      case .visibilitySelected, .groupToggled, .showsRecentToggled, .hidesAtNightToggled, .doneTapped, .saved:
        return self.visibility(&state, action)
      case let .requestFailed(message):
        state.connecting = nil
        state.isSaving = false
        state.toast = message
        return .none
      case .toastDismissed:
        state.toast = nil
        return .none
      case .groupsLoaded, .delegate:
        return .none
      }
    }
  }

  // MARK: 1 음악 서비스 연결

  private func connection(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case let .serviceTapped(service):
      guard state.connecting == nil else { return .none }
      state.connecting = service
      // 연결됨을 다시 누르면 끊는다(원본)
      if state.connected.contains(service) {
        return .run { send in
          do {
            try await self.client.disconnect(service)
            await send(.connectResult(service, false))
          } catch {
            // 원본에 없는 문구 — 디자인 확인 필요
            await send(.requestFailed("\(service.name) 연결을 끊지 못했어요"))
          }
        }
      }
      return .run { send in
        let isConnected = await (try? self.client.connect(service)) ?? false
        if isConnected {
          await send(.connectResult(service, true))
        } else {
          // 원본에 없는 문구 — 디자인 확인 필요
          await send(.requestFailed("\(service.name)에 연결하지 못했어요"))
        }
      }
    case let .connectResult(service, isConnected):
      state.connecting = nil
      if isConnected {
        state.connected.insert(service)
      } else {
        state.connected.remove(service)
      }
    case .nextTapped:
      guard state.canContinue else { return .none }
      state.step = .visibility
    default:
      break
    }
    return .none
  }

  // MARK: 2 공개 범위

  private func visibility(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case let .visibilitySelected(visibility):
      state.settings.visibility = visibility
    case let .groupToggled(group):
      if let index = state.settings.groups.firstIndex(of: group) {
        state.settings.groups.remove(at: index)
      } else {
        state.settings.groups.append(group)
      }
    case let .showsRecentToggled(isOn):
      state.settings.showsRecent = isOn
    case let .hidesAtNightToggled(isOn):
      state.settings.hidesAtNight = isOn
    case .doneTapped:
      guard !state.isSaving else { return .none }
      state.isSaving = true
      let settings = state.settings
      return .run { send in
        do {
          try await self.client.save(settings)
          await send(.saved)
        } catch {
          // 원본에 없는 문구 — 디자인 확인 필요
          await send(.requestFailed("설정을 저장하지 못했어요"))
        }
      }
    case .saved:
      state.isSaving = false
      state.step = .done
    default:
      break
    }
    return .none
  }
}

enum ListeningShareDelegate: Equatable {
  case dismiss
}
