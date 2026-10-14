import ComposableArchitecture
import Foundation

// REQ-070 — 백엔드가 정해지기 전까지 프로필은 목업이다(AGENTS.md 「미결정」).

struct MyClient {
  var fetchProfile: @Sendable () async throws -> MyProfile
  var appVersion: @Sendable () -> String
}

extension MyClient: DependencyKey {
  static let liveValue = MyClient(
    fetchProfile: { .mock },
    appVersion: {
      Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    }
  )

  static let previewValue = MyClient(
    fetchProfile: { .mock },
    appVersion: { "1.0.0" }
  )

  static let testValue = MyClient(
    fetchProfile: unimplemented("MyClient.fetchProfile", placeholder: .mock),
    appVersion: unimplemented("MyClient.appVersion", placeholder: "1.0.0")
  )
}

extension DependencyValues {
  var myClient: MyClient {
    get { self[MyClient.self] }
    set { self[MyClient.self] = newValue }
  }
}

extension MyProfile {
  /// 가짜 데이터 — 원본 예시의 이메일 대신 example.com을 쓴다.
  static let mock = MyProfile(
    nickname: "김동",
    email: "wepli.user@example.com",
    persona: .sentimentalSymphony,
    bio: "노래를 들으며 공부하는 걸 좋아하고 여러 사람들과 같이 듣는 걸 좋아하는 학생입니다:)"
  )
}
