import ComposableArchitecture
import Foundation

// UI-17b · DEC-027 · DEC-004 — 위반 횟수 · 이용 제한은 서버가 센다. 백엔드가 정해지기 전까지 원본 예시(3회 · 7일 제한)를 돌려주는 목업이다.

struct CommunityPolicyClient {
  var standing: @Sendable () async throws -> CommunityStanding
}

extension CommunityPolicyClient: DependencyKey {
  static let mockValue = CommunityPolicyClient(standing: { .mock })
  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  static let liveValue = mockValue
  static let previewValue = mockValue
  static let testValue = CommunityPolicyClient(standing: unimplemented(
    "CommunityPolicyClient.standing",
    placeholder: .clean
  ))
}

extension DependencyValues {
  var communityPolicyClient: CommunityPolicyClient {
    get { self[CommunityPolicyClient.self] }
    set { self[CommunityPolicyClient.self] = newValue }
  }
}

extension CommunityStanding {
  /// 원본(UI-17b) 예시 — 7d의 7일 제한 = 3회
  static let mock = CommunityStanding(
    step: 3,
    appealTarget: AppealTarget(
      id: "restriction-1",
      kind: .restriction,
      title: "커뮤니티 7일 이용 제한",
      reason: "운영정책 위반 신고 누적 (욕설 · 비하 표현)"
    )
  )
}
