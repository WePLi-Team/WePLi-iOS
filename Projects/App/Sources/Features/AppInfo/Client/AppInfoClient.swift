import ComposableArchitecture
import Foundation

// REQ-114 · DEC-004 — 앱 버전 · 최신 버전. 최신 버전은 서버(또는 App Store) 값 — 지금은 원본 예시(1.2.0) 목업

struct AppInfoClient {
  var currentVersion: @Sendable () -> String
  var latestVersion: @Sendable () async -> String?
}

extension AppInfoClient: DependencyKey {
  static let liveValue = AppInfoClient(
    currentVersion: { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0" },
    latestVersion: { "1.2.0" }
  )
  static let previewValue = liveValue
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
