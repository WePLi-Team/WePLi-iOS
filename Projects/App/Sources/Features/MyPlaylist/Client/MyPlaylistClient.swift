import ComposableArchitecture
import Foundation

// REQ-078 · DEC-004 — 백엔드가 정해지기 전까지 원본(UI-10d) 예시를 돌려주는 목업이다.

struct MyPlaylistClient {
  var fetch: @Sendable (_ id: String) async throws -> MyPlaylist
  /// 이름 · 곡 · 순서를 저장하고 서버에 저장된 결과를 돌려준다
  var save: @Sendable (_ playlist: MyPlaylist) async throws -> MyPlaylist
  var delete: @Sendable (_ id: String) async throws -> Void
}

extension MyPlaylistClient: DependencyKey {
  static let mockValue = MyPlaylistClient(
    fetch: { id in .mock(id: id) },
    save: { $0 },
    delete: { _ in }
  )

  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  static let liveValue = mockValue
  static let previewValue = mockValue

  static let testValue = MyPlaylistClient(
    fetch: unimplemented("MyPlaylistClient.fetch", placeholder: .mock(id: "")),
    save: unimplemented("MyPlaylistClient.save", placeholder: .mock(id: "")),
    delete: unimplemented("MyPlaylistClient.delete")
  )
}

extension DependencyValues {
  var myPlaylistClient: MyPlaylistClient {
    get { self[MyPlaylistClient.self] }
    set { self[MyPlaylistClient.self] = newValue }
  }
}
