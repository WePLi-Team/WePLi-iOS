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
  /// 플레이리스트를 만들고 담는다
  var createPlaylist: @Sendable (_ service: ExportService, _ name: String, _ songIDs: [String]) async throws -> Void
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
    createPlaylist: { _, _, _ in },
    setAutoExport: { _, _ in },
    copy: { text in await MainActor.run { UIPasteboard.general.string = text } }
  )

  static let previewValue = liveValue

  static let testValue = ExportClient(
    isConnected: unimplemented("ExportClient.isConnected", placeholder: false),
    connect: unimplemented("ExportClient.connect", placeholder: false),
    match: unimplemented("ExportClient.match", placeholder: AsyncStream { $0.finish() }),
    createPlaylist: unimplemented("ExportClient.createPlaylist"),
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
