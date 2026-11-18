import ComposableArchitecture
import Foundation

// REQ-078 · DEC-004 — 백엔드가 정해지기 전까지 원본(UI-10d) 예시를 돌려주는 목업이다.

public struct MyPlaylistClient {
  public var fetch: @Sendable (_ id: String) async throws -> MyPlaylist
  /// 이름 · 곡 · 순서를 저장하고 서버에 저장된 결과를 돌려준다
  public var save: @Sendable (_ playlist: MyPlaylist) async throws -> MyPlaylist
  public var delete: @Sendable (_ id: String) async throws -> Void

  public init(
    fetch: @escaping @Sendable (_ id: String) async throws -> MyPlaylist,
    save: @escaping @Sendable (_ playlist: MyPlaylist) async throws -> MyPlaylist,
    delete: @escaping @Sendable (_ id: String) async throws -> Void
  ) {
    self.fetch = fetch
    self.save = save
    self.delete = delete
  }
}

extension MyPlaylistClient: DependencyKey {
  public static let mockValue = MyPlaylistClient(
    fetch: { id in .mock(id: id) },
    save: { $0 },
    delete: { _ in }
  )

  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  public static let liveValue = mockValue
  public static let previewValue = mockValue

  public static let testValue = MyPlaylistClient(
    fetch: unimplemented("MyPlaylistClient.fetch", placeholder: .mock(id: "")),
    save: unimplemented("MyPlaylistClient.save", placeholder: .mock(id: "")),
    delete: unimplemented("MyPlaylistClient.delete")
  )
}

public extension DependencyValues {
  var myPlaylistClient: MyPlaylistClient {
    get { self[MyPlaylistClient.self] }
    set { self[MyPlaylistClient.self] = newValue }
  }
}
