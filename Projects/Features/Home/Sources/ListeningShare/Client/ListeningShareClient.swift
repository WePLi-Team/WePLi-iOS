import ComposableArchitecture
import Foundation

// REQ-079 · DEC-004 — 지금 듣는 음악 연결 · 공개 범위. 백엔드가 정해지기 전까지 목업이다.
// 미결정 — 실제 연결은 MusicKit 권한 · Spotify 로그인 · Last.fm 로그인(서비스별 개발자 등록 필요)

public struct ListeningShareClient {
  /// 내 그룹 이름(특정 그룹 칩) — 원본 예시: 우리 넷 · 밴드부 · 점심 메이트
  public var groups: @Sendable () async throws -> [String]
  public var connect: @Sendable (_ service: ListeningService) async throws -> Bool
  public var disconnect: @Sendable (_ service: ListeningService) async throws -> Void
  public var save: @Sendable (_ settings: ListeningShareSettings) async throws -> Void

  public init(
    groups: @escaping @Sendable () async throws -> [String],
    connect: @escaping @Sendable (_ service: ListeningService) async throws -> Bool,
    disconnect: @escaping @Sendable (_ service: ListeningService) async throws -> Void,
    save: @escaping @Sendable (_ settings: ListeningShareSettings) async throws -> Void
  ) {
    self.groups = groups
    self.connect = connect
    self.disconnect = disconnect
    self.save = save
  }
}

extension ListeningShareClient: DependencyKey {
  public static let mockValue = ListeningShareClient(
    groups: { ["우리 넷", "밴드부", "점심 메이트"] },
    connect: { _ in true },
    disconnect: { _ in },
    save: { _ in }
  )

  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  public static let liveValue = mockValue
  public static let previewValue = mockValue

  public static let testValue = ListeningShareClient(
    groups: unimplemented("ListeningShareClient.groups", placeholder: []),
    connect: unimplemented("ListeningShareClient.connect", placeholder: false),
    disconnect: unimplemented("ListeningShareClient.disconnect"),
    save: unimplemented("ListeningShareClient.save")
  )
}

public extension DependencyValues {
  var listeningShareClient: ListeningShareClient {
    get { self[ListeningShareClient.self] }
    set { self[ListeningShareClient.self] = newValue }
  }
}
