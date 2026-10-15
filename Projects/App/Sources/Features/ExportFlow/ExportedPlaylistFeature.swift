import ComposableArchitecture
import Foundation

// REQ-050 · UI-14m · DEC-004 — 내보낸 플리 · 변경 기록(push)
// 자동 반영 멈추기 · 다시 켜기는 먼저 반영하고 실패하면 되돌린다.

@Reducer
struct ExportedPlaylistFeature {
  @ObservableState
  struct State: Equatable {
    let playlistID: String
    var playlist: ExportedPlaylist?
    var loadFailed = false
    var toast: String?

    init(playlistID: String, playlist: ExportedPlaylist? = nil) {
      self.playlistID = playlistID
      self.playlist = playlist
    }
  }

  enum Action: Equatable {
    case onAppear
    case loaded(ExportedPlaylist)
    case loadFailed
    case retryButtonTapped
    case backButtonTapped
    case syncToggleTapped
    case syncFailed(restore: Bool)
    case syncNowTapped
    case openInServiceTapped
    case toastDismissed
    case delegate(ExportedPlaylistDelegate)
  }

  @Dependency(\.exportClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.playlist == nil else { return .none }
        return self.load(&state)
      case let .loaded(playlist):
        state.playlist = playlist
        return .none
      case .loadFailed:
        state.loadFailed = true
        return .none
      case .retryButtonTapped:
        return self.load(&state)
      case .backButtonTapped:
        return .send(.delegate(.dismiss))
      case .syncToggleTapped:
        guard let isOn = state.playlist?.isSyncOn else { return .none }
        state.playlist?.isSyncOn = !isOn
        let id = state.playlistID
        return .run { send in
          do {
            try await self.client.setSync(id, !isOn)
          } catch {
            await send(.syncFailed(restore: isOn))
          }
        }
      case let .syncFailed(restore):
        state.playlist?.isSyncOn = restore
        // 원본에 없는 문구 — 디자인 확인 필요
        state.toast = "자동 반영을 바꾸지 못했어요"
        return .none
      case .toastDismissed:
        state.toast = nil
        return .none
      // 원본에 동작이 없다(지금 반영하기 · 서비스에서 열기) — 실제 연동 때 잇는다
      case .syncNowTapped, .openInServiceTapped, .delegate:
        return .none
      }
    }
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.loadFailed = false
    let id = state.playlistID
    return .run { send in
      do {
        try await send(.loaded(self.client.fetchExported(id)))
      } catch {
        await send(.loadFailed)
      }
    }
  }
}

enum ExportedPlaylistDelegate: Equatable {
  case dismiss
}
