import ComposableArchitecture
import Foundation

// REQ-050 · UI-14l · DEC-004 — 진행 중 릴레이를 지금 순위로 먼저 담기(시트)
// 지금 TOP을 담고 → 마감 전엔 순위가 바뀔 때 반영 → 마감 때 최종 곡으로 고정된다.

@Reducer
struct LiveExportFeature {
  @ObservableState
  struct State: Equatable {
    let relayID: String
    let title: String
    let endsAt: Date
    /// 지금 순위 — 위에서부터 최대 12곡
    let songs: [ExportSong]
    var service: ExportService = .appleMusic
    var autoSync = true
    var isExporting = false
    var toast: String?

    static let songLimit = 12

    init(relayID: String, title: String, endsAt: Date, songs: [ExportSong]) {
      self.relayID = relayID
      self.title = title
      self.endsAt = endsAt
      self.songs = Array(songs.prefix(Self.songLimit))
    }
  }

  enum Action: Equatable {
    case closeTapped
    case autoSyncToggled(Bool)
    case serviceTapped
    case exportTapped
    case exported(ExportedPlaylist)
    case exportFailed
    case toastDismissed
    case delegate(LiveExportDelegate)
  }

  @Dependency(\.exportClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .closeTapped:
        return .send(.delegate(.dismiss))
      case let .autoSyncToggled(isOn):
        state.autoSync = isOn
        return .none
      case .exportTapped:
        guard !state.isExporting, !state.songs.isEmpty else { return .none }
        state.isExporting = true
        let relayID = state.relayID
        let service = state.service
        let songIDs = state.songs.map(\.id)
        let autoSync = state.autoSync
        return .run { send in
          do {
            try await send(.exported(self.client.exportLive(relayID, service, songIDs, autoSync)))
          } catch {
            await send(.exportFailed)
          }
        }
      case let .exported(playlist):
        state.isExporting = false
        return .send(.delegate(.exported(playlist)))
      case .exportFailed:
        state.isExporting = false
        // 원본에 없는 문구 — 디자인 확인 필요
        state.toast = "\(state.service.name)에 담지 못했어요. 다시 시도해 주세요"
        return .none
      case .toastDismissed:
        state.toast = nil
        return .none
      // 원본에 「담을 곳」 고르는 화면이 없다(14c와 비슷한 선택이 될 것) — 정해지면 잇는다
      case .serviceTapped, .delegate:
        return .none
      }
    }
  }
}

enum LiveExportDelegate: Equatable {
  case dismiss
  /// 담았으면 내보낸 플리(14m)로 간다
  case exported(ExportedPlaylist)
}
