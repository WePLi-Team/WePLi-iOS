import ComposableArchitecture
import Foundation

// REQ-024 · DEC-004 — 백엔드가 정해지기 전까지 원본(UI-5b) 예시를 돌려주는 목업이다.

struct ArtistClient {
  var fetch: @Sendable (_ id: String) async throws -> ArtistDetail
  var setLiked: @Sendable (_ id: String, _ isLiked: Bool) async throws -> Void
}

extension ArtistClient: DependencyKey {
  static let mockValue = ArtistClient(
    fetch: { id in .mock(id: id) },
    setLiked: { _, _ in }
  )

  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  static let liveValue = mockValue
  static let previewValue = mockValue

  static let testValue = ArtistClient(
    fetch: unimplemented("ArtistClient.fetch", placeholder: .mock(id: "")),
    setLiked: unimplemented("ArtistClient.setLiked")
  )
}

extension DependencyValues {
  var artistClient: ArtistClient {
    get { self[ArtistClient.self] }
    set { self[ArtistClient.self] = newValue }
  }
}
