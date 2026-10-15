import Foundation

// REQ-050 · UI-11b — 마이 › 설정 › 음악 서비스. 연결 상태 · 기본 서비스 · 자동 담기는 서버 값(DEC-004)

struct MusicServiceConnection: Equatable, Identifiable, Sendable {
  var id: ExportService {
    self.service
  }

  let service: ExportService
  var isConnected: Bool
  /// 「iCloud 보관함」 · 계정 이름
  var detail: String?

  /// 「연결됨 · iCloud 보관함」 · 「연결 안 됨」
  var status: String {
    guard self.isConnected else { return "연결 안 됨" }
    return self.detail.map { "연결됨 · \($0)" } ?? "연결됨"
  }
}

struct MusicServiceSettings: Equatable, Sendable {
  var connections: [MusicServiceConnection]
  /// 기본으로 담을 곳 — 연결된 서비스만 고를 수 있다
  var defaultService: ExportService?
  var autoExport: Bool
  let exported: [ExportedPlaylistRow]

  /// 연결을 바꾼다. 기본 서비스가 끊기면 연결된 첫 서비스로 옮긴다(원본 동작).
  mutating func setConnected(_ service: ExportService, _ isConnected: Bool, detail: String? = nil) {
    guard let index = self.connections.firstIndex(where: { $0.service == service }) else { return }
    self.connections[index].isConnected = isConnected
    self.connections[index].detail = isConnected ? detail : nil
    let connected = self.connections.filter(\.isConnected).map(\.service)
    if let current = self.defaultService, connected.contains(current) {
      return
    }
    // 원본은 모두 끊겨도 Apple Music을 고른 채로 둔다 — 고를 곳이 없으면 비워 둔다
    self.defaultService = connected.first
  }

  func isConnected(_ service: ExportService) -> Bool {
    self.connections.first { $0.service == service }?.isConnected ?? false
  }
}

/// 내보낸 플레이리스트 한 줄 — 누르면 내보낸 플리(UI-14m)
struct ExportedPlaylistRow: Equatable, Identifiable, Sendable {
  enum SyncState: Equatable, Sendable {
    case syncing
    case paused
    case done

    var title: String {
      switch self {
      case .syncing: "자동 반영 중"
      // 원본 11b에는 없는 상태 — 14m 「자동 반영 멈춤」과 같은 말
      case .paused: "자동 반영 멈춤"
      case .done: "완료"
      }
    }
  }

  /// 내보낸 플리 id
  let id: String
  let title: String
  let service: ExportService
  /// 「오늘」 · 「09.30」
  let dateText: String
  let state: SyncState
}
