import ComposableArchitecture
import Foundation

// REQ-079 · DEC-004 — 지금 듣는 음악 연결 · 공개 범위. 백엔드가 정해지기 전까지 목업이다.
// 미결정 — 실제 연결은 MusicKit 권한 · Spotify 로그인 · Last.fm 로그인(서비스별 개발자 등록 필요)

struct ListeningShareClient {
  /// 내 그룹 이름(특정 그룹 칩) — 원본 예시: 우리 넷 · 밴드부 · 점심 메이트
  var groups: @Sendable () async throws -> [String]
  var connect: @Sendable (_ service: ListeningService) async throws -> Bool
  var disconnect: @Sendable (_ service: ListeningService) async throws -> Void
  var save: @Sendable (_ settings: ListeningShareSettings) async throws -> Void
}

extension ListeningShareClient: DependencyKey {
  static let liveValue = ListeningShareClient(
    groups: { ["우리 넷", "밴드부", "점심 메이트"] },
    connect: { _ in true },
    disconnect: { _ in },
    save: { _ in }
  )

  static let previewValue = liveValue

  static let testValue = ListeningShareClient(
    groups: unimplemented("ListeningShareClient.groups", placeholder: []),
    connect: unimplemented("ListeningShareClient.connect", placeholder: false),
    disconnect: unimplemented("ListeningShareClient.disconnect"),
    save: unimplemented("ListeningShareClient.save")
  )
}

extension DependencyValues {
  var listeningShareClient: ListeningShareClient {
    get { self[ListeningShareClient.self] }
    set { self[ListeningShareClient.self] = newValue }
  }
}
