import ComposableArchitecture
import Foundation

// REQ-073 · DEC-024 — 이의 신청 저장 · 검토 · 결과 알림은 서버가 한다. 백엔드가 정해지기 전까지 목업이다.
// 개인정보 — 설명 내용은 로그에 남기지 않는다.

struct AppealClient {
  /// 이미 신청한 대상이면 AppealError.alreadyAppealed
  var submit: @Sendable (_ target: AppealTarget, _ reason: AppealReason, _ text: String) async throws -> Void
}

extension AppealClient: DependencyKey {
  static let mockValue = AppealClient(submit: { _, _, _ in })
  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  static let liveValue = mockValue
  static let previewValue = mockValue
  static let testValue = AppealClient(submit: unimplemented("AppealClient.submit"))
}

extension DependencyValues {
  var appealClient: AppealClient {
    get { self[AppealClient.self] }
    set { self[AppealClient.self] = newValue }
  }
}
