import ComposableArchitecture
import Foundation
import UIKit

// REQ-050 · DEC-004 — 음악 서비스 연동. 지금은 목업이다.
// 미결정 — 실제 연동은 Apple Developer의 MusicKit 앱 서비스 · Spotify 앱 등록(확장 이용 승인) · YouTube Data API 할당량이 필요하다.

struct ExportClient {
  /// 연결돼 있으면 연결 단계(14e · 14g)를 건너뛴다
  var isConnected: @Sendable (_ service: ExportService) async -> Bool
  /// Apple Music 접근 허용(시스템 알림) · Spotify · Google 로그인
  var connect: @Sendable (_ service: ExportService) async throws -> Bool
  /// 곡마다 맞춘 결과를 차례로 돌려준다
  var match: @Sendable (_ service: ExportService, _ songs: [ExportSong]) -> AsyncStream<ExportMatchEvent>
  /// Apple Music 구독 — 없으면 보관함에 플리를 만들 수 없다(14f)
  var hasSubscription: @Sendable () async -> Bool
  /// 플레이리스트를 만들거나(새로) 이미 담은 플리에 곡을 이어 담는다 · 최종 순위로 맞춘다. 플리 id를 돌려준다.
  /// 중간에 멈추면 `ExportError`로 담긴 곡 수를 알린다(14n).
  var addSongs: @Sendable (_ service: ExportService, _ target: ExportTarget, _ songIDs: [String]) async throws -> String
  /// 진행 중 릴레이를 지금 TOP으로 먼저 담는다(14l) — 자동 반영을 켜면 마감까지 순위 변동을 반영한다
  var exportLive: @Sendable (
    _ relayID: String,
    _ service: ExportService,
    _ songIDs: [String],
    _ autoSync: Bool
  ) async throws -> ExportedPlaylist
  var fetchExported: @Sendable (_ playlistID: String) async throws -> ExportedPlaylist
  var setSync: @Sendable (_ playlistID: String, _ isOn: Bool) async throws -> Void
  var setAutoExport: @Sendable (_ service: ExportService, _ isOn: Bool) async -> Void
  var copy: @Sendable (_ text: String) async -> Void
}

struct ExportMatchEvent: Equatable, Sendable {
  let songID: String
  let match: ExportMatch
}

extension ExportClient: DependencyKey {
  static let liveValue = ExportClient(
    isConnected: { $0 == .appleMusic },
    connect: { _ in true },
    match: { _, songs in
      AsyncStream { continuation in
        let task = Task {
          @Dependency(\.continuousClock)
          var clock
          for song in songs {
            // 원본 목업은 곡마다 0.45초
            try? await clock.sleep(for: .milliseconds(450))
            continuation.yield(ExportMatchEvent(songID: song.id, match: ExportSample.match(for: song.id)))
          }
          continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
      }
    },
    hasSubscription: { true },
    addSongs: { _, target, _ in
      switch target {
      case .new: "playlist-\(UUID().uuidString)"
      case let .append(id), let .replace(id): id
      }
    },
    exportLive: { relayID, service, _, autoSync in
      @Dependency(\.date.now)
      var now
      var playlist = ExportedPlaylist.mock(
        id: "live-\(relayID)",
        relayID: relayID,
        title: "손님들이 물어보는 카페 BGM",
        service: service,
        endsAt: now.addingTimeInterval(2 * 86400 + 4 * 3600)
      )
      playlist.isSyncOn = autoSync
      return playlist
    },
    fetchExported: { id in
      @Dependency(\.date.now)
      var now
      // 음악 서비스 설정(11b)의 「내보낸 플레이리스트」 예시와 맞춘다 — 완료된 플리는 마감이 없다
      let row = MusicServiceSettings.mock.exported.first { $0.id == id }
      return .mock(
        id: id,
        relayID: row?.id ?? "cafe-bgm",
        title: row?.title ?? "손님들이 물어보는 카페 BGM",
        service: row?.service ?? .appleMusic,
        endsAt: row?.state == .done ? nil : now.addingTimeInterval(2 * 86400 + 4 * 3600)
      )
    },
    setSync: { _, _ in },
    setAutoExport: { _, _ in },
    copy: { text in await MainActor.run { UIPasteboard.general.string = text } }
  )

  static let previewValue = liveValue

  static let testValue = ExportClient(
    isConnected: unimplemented("ExportClient.isConnected", placeholder: false),
    connect: unimplemented("ExportClient.connect", placeholder: false),
    match: unimplemented("ExportClient.match", placeholder: AsyncStream { $0.finish() }),
    hasSubscription: unimplemented("ExportClient.hasSubscription", placeholder: true),
    addSongs: unimplemented("ExportClient.addSongs", placeholder: ""),
    exportLive: unimplemented("ExportClient.exportLive", placeholder: .mock(
      id: "",
      relayID: "",
      title: "",
      service: .appleMusic,
      endsAt: nil
    )),
    fetchExported: unimplemented("ExportClient.fetchExported", placeholder: .mock(
      id: "",
      relayID: "",
      title: "",
      service: .appleMusic,
      endsAt: nil
    )),
    setSync: unimplemented("ExportClient.setSync"),
    setAutoExport: unimplemented("ExportClient.setAutoExport"),
    copy: unimplemented("ExportClient.copy")
  )
}

extension DependencyValues {
  var exportClient: ExportClient {
    get { self[ExportClient.self] }
    set { self[ExportClient.self] = newValue }
  }
}

/// 원본(UI-14h · 14j) 예시 결과 — 그대만 있다면은 같은 음원이 없고, Small girl은 다른 앨범 버전
enum ExportSample {
  /// 원본 12곡 — 내가 투표한 곡은 1 · 3 · 5 · 7 · 10위
  static let songs: [ExportSong] = [
    ExportSong(id: "supernova", title: "Supernova", artist: "aespa", recommender: "", isVoted: true),
    ExportSong(id: "how-sweet", title: "How Sweet", artist: "NewJeans", recommender: ""),
    ExportSong(id: "hype", title: "Hype Boy", artist: "NewJeans", recommender: "", isVoted: true),
    ExportSong(id: "easy", title: "EASY", artist: "LE SSERAFIM (르세라핌)", recommender: ""),
    ExportSong(id: "heya", title: "해야 (HEYA)", artist: "IVE (아이브)", recommender: "", isVoted: true),
    ExportSong(id: "love119", title: "Love 119", artist: "RIIZE", recommender: ""),
    ExportSong(id: "tws", title: "첫 만남은 계획대로 되지 않아", artist: "TWS (투어스)", recommender: "", isVoted: true),
    ExportSong(id: "nerd", title: "그대만 있다면 (여름날 우리 X 너드커넥션)", artist: "너드커넥션", recommender: "minnie._."),
    ExportSong(id: "bam", title: "밤양갱", artist: "비비 (BIBI)", recommender: ""),
    ExportSong(id: "small-girl", title: "Small girl (feat. 도경수)", artist: "이영지", recommender: "", isVoted: true),
    ExportSong(id: "sonagi", title: "소나기", artist: "이클립스 (ECLIPSE)", recommender: ""),
    ExportSong(id: "rhapsody", title: "비의 랩소디", artist: "임재현", recommender: ""),
  ]

  static let alternatives: [ExportAlternative] = [
    ExportAlternative(id: "live", title: "그대만 있다면 (Live)", detail: "너드커넥션 · 라이브 앨범 · 4:31"),
    ExportAlternative(id: "acoustic", title: "그대만 있다면 (Acoustic Ver.)", detail: "너드커넥션 · 싱글 · 3:58"),
    ExportAlternative(id: "inst", title: "그대만 있다면 (Inst.)", detail: "너드커넥션 · 연주곡 · 4:05"),
  ]

  static func match(for songID: String) -> ExportMatch {
    switch songID {
    case "nerd": .needsCheck(alternatives: self.alternatives)
    case "small-girl": .otherVersion
    default: .found
    }
  }
}
