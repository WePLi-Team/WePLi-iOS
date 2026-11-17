import ComposableArchitecture
import Foundation

// REQ-114 · DEC-004 — 앱 버전 · 최신 버전. 최신 버전은 서버(또는 App Store) 값 — 지금은 원본 예시(1.2.0) 목업

public struct AppInfoClient {
  public var currentVersion: @Sendable () -> String
  public var latestVersion: @Sendable () async -> String?

  public init(
    currentVersion: @escaping @Sendable () -> String,
    latestVersion: @escaping @Sendable () async -> String?
  ) {
    self.currentVersion = currentVersion
    self.latestVersion = latestVersion
  }
}

extension AppInfoClient: DependencyKey {
  public static let mockValue = AppInfoClient(
    currentVersion: { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0" },
    latestVersion: { "1.2.0" }
  )
  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  public static let liveValue = mockValue
  public static let previewValue = mockValue
  public static let testValue = AppInfoClient(
    currentVersion: { "1.0.0" },
    latestVersion: unimplemented("AppInfoClient.latestVersion", placeholder: nil)
  )
}

public extension DependencyValues {
  var appInfoClient: AppInfoClient {
    get { self[AppInfoClient.self] }
    set { self[AppInfoClient.self] = newValue }
  }
}
