import Foundation

// REQ-050 · UI-11b · DEC-018 — 마이 › 설정 › 음악 서비스. 연결을 한곳에서 관리한다.
// 연결 상태 · 기본 서비스 · 자동 담기는 서버 값(DEC-004)

/// 연결할 수 있는 서비스와 용도 — Last.fm은 플리를 받을 수 없어 「지금 듣는 중」에만 쓴다
enum MusicConnectionService: CaseIterable, Equatable, Sendable {
  case appleMusic
  case spotify
  case youtubeMusic
  case lastFM

  var name: String {
    self.exportService?.name ?? "Last.fm"
  }

  /// 내보낼 수 있는 서비스 — Last.fm은 nil
  var exportService: ExportService? {
    switch self {
    case .appleMusic: .appleMusic
    case .spotify: .spotify
    case .youtubeMusic: .youtubeMusic
    case .lastFM: nil
    }
  }

  /// 「내보내기 · 지금 듣는 중」 · 「내보내기만」 · 「지금 듣는 중만」
  var usage: String {
    switch self {
    case .appleMusic, .spotify: "내보내기 · 지금 듣는 중"
    case .youtubeMusic: "내보내기만"
    case .lastFM: "지금 듣는 중만"
    }
  }
}

struct MusicServiceConnection: Equatable, Identifiable, Sendable {
  var id: MusicConnectionService {
    self.service
  }

  let service: MusicConnectionService
  var isConnected: Bool

  /// 「연결됨 · 내보내기 · 지금 듣는 중」 · 「내보내기만」
  var status: String {
    self.isConnected ? "연결됨 · \(self.service.usage)" : self.service.usage
  }
}

struct MusicServiceSettings: Equatable, Sendable {
  var connections: [MusicServiceConnection]
  /// 기본으로 담을 곳 — 연결된 서비스만 고를 수 있다
  var defaultService: ExportService?
  var autoExport: Bool
  let exported: [ExportedPlaylistRow]

  /// 기본으로 담을 곳 후보 — 내보낼 수 있는 서비스만(Last.fm 제외)
  var destinations: [MusicServiceConnection] {
    self.connections.filter { $0.service.exportService != nil }
  }

  /// 연결을 바꾼다. 기본 서비스가 끊기면 연결된 첫 서비스로 옮긴다(원본 동작).
  mutating func setConnected(_ service: MusicConnectionService, _ isConnected: Bool) {
    guard let index = self.connections.firstIndex(where: { $0.service == service }) else { return }
    self.connections[index].isConnected = isConnected
    let connected = self.destinations.filter(\.isConnected).compactMap(\.service.exportService)
    if let current = self.defaultService, connected.contains(current) {
      return
    }
    // 원본은 모두 끊겨도 Apple Music을 고른 채로 둔다 — 고를 곳이 없으면 비워 둔다
    self.defaultService = connected.first
  }

  func isConnected(_ service: MusicConnectionService) -> Bool {
    self.connections.first { $0.service == service }?.isConnected ?? false
  }

  func isConnected(_ service: ExportService) -> Bool {
    self.connections.first { $0.service.exportService == service }?.isConnected ?? false
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
