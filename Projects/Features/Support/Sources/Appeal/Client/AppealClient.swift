import ComposableArchitecture
import Foundation
import WePLiSharedModels

// REQ-073 · DEC-024 — 이의 신청 저장 · 검토 · 결과 알림은 서버가 한다. 백엔드가 정해지기 전까지 목업이다.
// 개인정보 — 설명 내용은 로그에 남기지 않는다.

public struct AppealClient {
  /// 이미 신청한 대상이면 AppealError.alreadyAppealed
  public var submit: @Sendable (_ target: AppealTarget, _ reason: AppealReason, _ text: String) async throws -> Void

  public typealias Submit = @Sendable (_ target: AppealTarget, _ reason: AppealReason, _ text: String) async throws
    -> Void

  public init(submit: @escaping Submit) {
    self.submit = submit
  }
}

extension AppealClient: DependencyKey {
  public static let mockValue = AppealClient(submit: { _, _, _ in })
  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  public static let liveValue = mockValue
  public static let previewValue = mockValue
  public static let testValue = AppealClient(submit: unimplemented("AppealClient.submit"))
}

public extension DependencyValues {
  var appealClient: AppealClient {
    get { self[AppealClient.self] }
    set { self[AppealClient.self] = newValue }
  }
}
