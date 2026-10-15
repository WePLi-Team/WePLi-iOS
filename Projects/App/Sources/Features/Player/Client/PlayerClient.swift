import ComposableArchitecture
import Foundation

// REQ-022 · DEC-004 — 미리듣기 오디오. 지금은 목업이다(소리 없이 진행만 한다).
// 미결정 — 실제 미리듣기는 MusicKit 카탈로그의 previewAssets URL을 AVPlayer로 튼다(앱 서비스 설정 필요).

struct PlayerClient {
  var play: @Sendable (_ track: PlayerTrack) async -> Void
  var pause: @Sendable () async -> Void
  var resume: @Sendable () async -> Void
  /// 좋아요 — 곡 상세 · 곡 메뉴와 같은 좋아요다
  var setLiked: @Sendable (_ trackID: PlayerTrack.ID, _ isLiked: Bool) async throws -> Void
  /// 「Music에서 전체 곡 듣기」
  var openInMusic: @Sendable (_ track: PlayerTrack) async -> Void
}

extension PlayerClient: DependencyKey {
  static let liveValue = PlayerClient(
    play: { _ in },
    pause: {},
    resume: {},
    setLiked: { _, _ in },
    openInMusic: { _ in }
  )

  static let previewValue = liveValue

  static let testValue = PlayerClient(
    play: { _ in },
    pause: {},
    resume: {},
    setLiked: unimplemented("PlayerClient.setLiked"),
    openInMusic: unimplemented("PlayerClient.openInMusic")
  )
}

extension DependencyValues {
  var playerClient: PlayerClient {
    get { self[PlayerClient.self] }
    set { self[PlayerClient.self] = newValue }
  }
}
