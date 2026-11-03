import ComposableArchitecture
import Foundation

// REQ-114 · DEC-004 — 앱 버전 · 최신 버전. 최신 버전은 서버(또는 App Store) 값 — 지금은 원본 예시(1.2.0) 목업

struct AppInfoClient {
  var currentVersion: @Sendable () -> String
  var latestVersion: @Sendable () async -> String?
}

extension AppInfoClient: DependencyKey {
  static let mockValue = AppInfoClient(
    currentVersion: { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0" },
    latestVersion: { "1.2.0" }
  )
  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  static let liveValue = mockValue
  static let previewValue = mockValue
  static let testValue = AppInfoClient(
    currentVersion: { "1.0.0" },
    latestVersion: unimplemented("AppInfoClient.latestVersion", placeholder: nil)
  )
}

extension DependencyValues {
  var appInfoClient: AppInfoClient {
    get { self[AppInfoClient.self] }
    set { self[AppInfoClient.self] = newValue }
  }
}
