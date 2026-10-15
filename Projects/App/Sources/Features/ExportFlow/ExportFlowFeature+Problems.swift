import ComposableArchitecture
import Foundation

// UI-14f 구독이 없을 때 · 14n 문제가 생겼을 때(끊김 · 연결 만료 · 이미 담음)
// 어떤 경우든 이미 담긴 곡은 남기고, 멈춘 곳부터 잇는다.

extension ExportFlowFeature {
  /// 곡 맞추기 전에 Apple Music 구독을 확인한다(14f 노트 「허용 후 구독 상태를 확인」)
  func beginExport(_ state: inout State) -> Effect<Action> {
    guard state.service == .appleMusic else { return self.startMatching(&state) }
    return .run { send in
      await send(.subscriptionChecked(self.client.hasSubscription()))
    }
  }

  func subscriptionStep(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case let .subscriptionChecked(hasSubscription):
      guard hasSubscription else {
        state.step = .subscriptionNeeded
        return .none
      }
      return self.startMatching(&state)
    case .subscriptionOfferTapped:
      state.showsSubscriptionOffer = true
    case let .subscriptionOfferChanged(isPresented):
      state.showsSubscriptionOffer = isPresented
    case .otherServiceTapped:
      // 다른 서비스로 담으면 처음부터 — 멈춘 플리는 그 서비스에 그대로 남는다
      state.pendingSongIDs = []
      state.addedCount = 0
      state.playlistID = nil
      state.updatesExisting = false
      state.step = .service
    case .copyListTapped:
      state.step = .copyList
    default:
      break
    }
    return .none
  }

  func stopped(_ state: inout State, _ error: ExportError) -> Effect<Action> {
    switch error {
    case let .interrupted(playlistID, added):
      state.playlistID = playlistID
      state.addedCount += added
      state.step = .problem(.interrupted)
    case let .expired(playlistID, added):
      state.playlistID = playlistID ?? state.playlistID
      state.addedCount += added
      state.connected.remove(state.service)
      state.step = .problem(.expired)
    }
    return .none
  }

  func problemStep(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case .resumeTapped:
      return self.resume(&state)
    case .reconnectTapped:
      return self.connect(&state)
    case .problemLaterTapped:
      // 미결정 — 연결이 돌아오면 이어서 담고 알리는 동작(NWPathMonitor · 로컬 알림)은 실제 연동 때 만든다
      return .send(.delegate(.dismiss))
    case let .reExportSelected(choice):
      state.reExport = choice
      return .none
    case .reExportContinueTapped:
      guard case let .problem(.alreadyExported(record)) = state.step else { return .none }
      state.service = record.service
      guard state.reExport == .update else {
        state.updatesExisting = false
        state.step = .settings
        return .none
      }
      // 기존 플리를 최종 순위로 맞춘다 — 곡을 다시 맞추고 확인받은 뒤 바꾼다
      state.updatesExisting = true
      state.playlistID = record.playlistID
      state.connected.insert(record.service)
      return self.beginExport(&state)
    default:
      return .none
    }
  }

  /// 멈춘 곳부터 — 만든 플리가 있으면 이어 담고, 없으면 새로 만든다
  func resume(_ state: inout State) -> Effect<Action> {
    let remaining = state.remainingSongIDs
    guard !state.isAdding, !remaining.isEmpty else { return .none }
    let target: ExportTarget = state.playlistID.map { .append(playlistID: $0) } ?? .new(name: state.exportName)
    return self.send(&state, to: target, songIDs: remaining)
  }
}
