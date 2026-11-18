import ComposableArchitecture
import Foundation

// REQ-050 · DEC-004 — 백엔드가 정해지기 전까지 원본(UI-11b) 예시를 돌려주는 목업이다.
// 미결정 — 실제 연결은 MusicKit 권한(14e) · Spotify · Google 로그인(14g) · Last.fm 로그인을 쓴다.

public struct MusicServicesClient {
  public var fetch: @Sendable () async throws -> MusicServiceSettings
  public var connect: @Sendable (_ service: MusicConnectionService) async throws -> Void
  /// 끊어도 이미 만든 플리는 남고 자동 반영만 멈춘다(11b 노트)
  public var disconnect: @Sendable (_ service: MusicConnectionService) async throws -> Void
  public var setDefault: @Sendable (_ service: ExportService) async throws -> Void
  public var setAutoExport: @Sendable (_ isOn: Bool) async throws -> Void

  public init(
    fetch: @escaping @Sendable () async throws -> MusicServiceSettings,
    connect: @escaping @Sendable (_ service: MusicConnectionService) async throws -> Void,
    disconnect: @escaping @Sendable (_ service: MusicConnectionService) async throws -> Void,
    setDefault: @escaping @Sendable (_ service: ExportService) async throws -> Void,
    setAutoExport: @escaping @Sendable (_ isOn: Bool) async throws -> Void
  ) {
    self.fetch = fetch
    self.connect = connect
    self.disconnect = disconnect
    self.setDefault = setDefault
    self.setAutoExport = setAutoExport
  }
}

extension MusicServicesClient: DependencyKey {
  public static let mockValue = MusicServicesClient(
    fetch: { .mock },
    connect: { _ in },
    disconnect: { _ in },
    setDefault: { _ in },
    setAutoExport: { _ in }
  )

  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  public static let liveValue = mockValue
  public static let previewValue = mockValue

  public static let testValue = MusicServicesClient(
    fetch: unimplemented("MusicServicesClient.fetch", placeholder: .mock),
    connect: unimplemented("MusicServicesClient.connect"),
    disconnect: unimplemented("MusicServicesClient.disconnect"),
    setDefault: unimplemented("MusicServicesClient.setDefault"),
    setAutoExport: unimplemented("MusicServicesClient.setAutoExport")
  )
}

public extension DependencyValues {
  var musicServicesClient: MusicServicesClient {
    get { self[MusicServicesClient.self] }
    set { self[MusicServicesClient.self] = newValue }
  }
}

public extension MusicServiceSettings {
  /// 원본(UI-11b) 예시
  static let mock = MusicServiceSettings(
    connections: [
      MusicServiceConnection(service: .appleMusic, isConnected: true),
      MusicServiceConnection(service: .spotify, isConnected: true),
      MusicServiceConnection(service: .youtubeMusic, isConnected: false),
      MusicServiceConnection(service: .lastFM, isConnected: false),
    ],
    defaultService: .appleMusic,
    autoExport: true,
    exported: [
      ExportedPlaylistRow(
        id: "cafe-bgm",
        title: "손님들이 물어보는 카페 BGM",
        service: .spotify,
        dateText: "오늘",
        state: .syncing
      ),
      ExportedPlaylistRow(
        id: "summer-work",
        title: "졸릴 때 잠 깨는 청량맛 노동요",
        service: .appleMusic,
        dateText: "09.30",
        state: .done
      ),
      ExportedPlaylistRow(
        id: "first-love",
        title: "첫 사랑이 생각나는 노래 모음",
        service: .appleMusic,
        dateText: "09.12",
        state: .done
      ),
    ]
  )
}
