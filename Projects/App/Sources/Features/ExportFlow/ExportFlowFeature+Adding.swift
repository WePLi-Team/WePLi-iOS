import ComposableArchitecture
import Foundation

// UI-14i → 14k — 확인한 곡을 한 번에 담는다. 이미 담은 플리를 맞출 때는 그 플리를 바꾼다.

extension ExportFlowFeature {
  // MARK: 14i → 14k 담기

  func addStep(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case .confirmTapped:
      return self.add(&state, songIDs: state.exportSongIDs)
    case .addFoundOnlyTapped:
      // 「확인할 곡은 빼고 N곡만 담기」
      return self.add(&state, songIDs: state.foundSongs.map(\.id))
    case let .added(playlistID):
      state.isAdding = false
      state.playlistID = playlistID
      state.addedCount = state.pendingSongIDs.count
      state.step = .done
      return .none
    case let .addStopped(error):
      state.isAdding = false
      return self.stopped(&state, error)
    case .addFailed:
      state.isAdding = false
      // 원본에 없는 문구 — 끊김 · 만료가 아닌 실패
      state.toast = "\(state.service.name)에 담지 못했어요. 다시 시도해 주세요"
      return .none
    default:
      return .none
    }
  }

  func add(_ state: inout State, songIDs: [String]) -> Effect<Action> {
    guard !state.isAdding, !songIDs.isEmpty else { return .none }
    state.pendingSongIDs = songIDs
    state.addedCount = 0
    if state.updatesExisting, let playlistID = state.playlistID {
      return self.send(&state, to: .replace(playlistID: playlistID), songIDs: songIDs)
    }
    state.playlistID = nil
    return self.send(&state, to: .new(name: state.exportName), songIDs: songIDs)
  }

  func send(_ state: inout State, to target: ExportTarget, songIDs: [String]) -> Effect<Action> {
    state.isAdding = true
    let service = state.service
    return .run { send in
      do {
        try await send(.added(playlistID: self.client.addSongs(service, target, songIDs)))
      } catch let error as ExportError {
        await send(.addStopped(error))
      } catch {
        await send(.addFailed)
      }
    }
  }
}
