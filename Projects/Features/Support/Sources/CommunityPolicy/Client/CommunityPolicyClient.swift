import ComposableArchitecture
import Foundation
import WePLiSharedModels

// UI-17b · DEC-027 · DEC-004 — 위반 횟수 · 이용 제한은 서버가 센다. 백엔드가 정해지기 전까지 원본 예시(3회 · 7일 제한)를 돌려주는 목업이다.

public struct CommunityPolicyClient {
  public var standing: @Sendable () async throws -> CommunityStanding

  public init(standing: @escaping @Sendable () async throws -> CommunityStanding) {
    self.standing = standing
  }
}

extension CommunityPolicyClient: DependencyKey {
  public static let mockValue = CommunityPolicyClient(standing: { .mock })
  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  public static let liveValue = mockValue
  public static let previewValue = mockValue
  public static let testValue = CommunityPolicyClient(standing: unimplemented(
    "CommunityPolicyClient.standing",
    placeholder: .clean
  ))
}

public extension DependencyValues {
  var communityPolicyClient: CommunityPolicyClient {
    get { self[CommunityPolicyClient.self] }
    set { self[CommunityPolicyClient.self] = newValue }
  }
}

public extension CommunityStanding {
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
