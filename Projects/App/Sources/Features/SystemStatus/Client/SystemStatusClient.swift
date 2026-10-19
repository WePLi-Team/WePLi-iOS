import ComposableArchitecture
import Foundation
import Network

// REQ-112 · DEC-014 · DEC-004 — 서버 설정 · 네트워크 · 오늘 하루 보지 않기. 서버 설정은 백엔드가 정해지기 전까지 목업이다.

struct SystemStatusClient {
  var config: @Sendable () async throws -> SystemConfig
  var appVersion: @Sendable () -> String
  /// 연결이 바뀔 때마다 오프라인인지 알려준다
  var offlineUpdates: @Sendable () -> AsyncStream<Bool>
  /// 이 이벤트를 숨긴 날(Asia/Seoul 「yyyy-MM-dd」)
  var hiddenEventDay: @Sendable (_ eventID: String) -> String?
  var hideEvent: @Sendable (_ eventID: String, _ day: String) -> Void
  /// 미결정 — App Store 앱 주소
  var openAppStore: @Sendable () async -> Void
}

extension SystemStatusClient: DependencyKey {
  static let liveValue = SystemStatusClient(
    // 목업은 막는 상태 없이 이벤트 팝업만 둔다
    config: {
      SystemConfig(event: .init(
        id: "instagram-open",
        title: "위플리\n인스타그램\nOPEN!",
        body: "감성 가득한 일상 보러 오세요. 10월 31일까지 팔로우하면 추첨으로 선물을 드려요."
      ))
    },
    appVersion: { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0" },
    offlineUpdates: {
      AsyncStream { continuation in
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { continuation.yield($0.status != .satisfied) }
        monitor.start(queue: DispatchQueue(label: "wepli.network"))
        continuation.onTermination = { _ in monitor.cancel() }
      }
    },
    hiddenEventDay: { UserDefaults.standard.string(forKey: "wepli.event.hidden.\($0)") },
    hideEvent: { UserDefaults.standard.set($1, forKey: "wepli.event.hidden.\($0)") },
    openAppStore: {}
  )

  static let previewValue = liveValue

  static let testValue = SystemStatusClient(
    config: unimplemented("SystemStatusClient.config", placeholder: SystemConfig()),
    appVersion: { "1.0.0" },
    offlineUpdates: { AsyncStream { $0.finish() } },
    hiddenEventDay: { _ in nil },
    hideEvent: unimplemented("SystemStatusClient.hideEvent"),
    openAppStore: unimplemented("SystemStatusClient.openAppStore")
  )
}

extension DependencyValues {
  var systemStatusClient: SystemStatusClient {
    get { self[SystemStatusClient.self] }
    set { self[SystemStatusClient.self] = newValue }
  }
}
