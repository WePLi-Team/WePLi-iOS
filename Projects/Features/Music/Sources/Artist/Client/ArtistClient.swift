import ComposableArchitecture
import Foundation

// REQ-024 · DEC-004 — 백엔드가 정해지기 전까지 원본(UI-5b) 예시를 돌려주는 목업이다.

public struct ArtistClient {
  public var fetch: @Sendable (_ id: String) async throws -> ArtistDetail
  public var setLiked: @Sendable (_ id: String, _ isLiked: Bool) async throws -> Void

  public init(
    fetch: @escaping @Sendable (_ id: String) async throws -> ArtistDetail,
    setLiked: @escaping @Sendable (_ id: String, _ isLiked: Bool) async throws -> Void
  ) {
    self.fetch = fetch
    self.setLiked = setLiked
  }
}

extension ArtistClient: DependencyKey {
  public static let mockValue = ArtistClient(
    fetch: { id in .mock(id: id) },
    setLiked: { _, _ in }
  )

  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  public static let liveValue = mockValue
  public static let previewValue = mockValue

  public static let testValue = ArtistClient(
    fetch: unimplemented("ArtistClient.fetch", placeholder: .mock(id: "")),
    setLiked: unimplemented("ArtistClient.setLiked")
  )
}

public extension DependencyValues {
  var artistClient: ArtistClient {
    get { self[ArtistClient.self] }
    set { self[ArtistClient.self] = newValue }
  }
}
