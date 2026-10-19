import ComposableArchitecture
import Foundation
import UIKit

// REQ-111 · DEC-004 — 문의 저장 · 답변 메일은 서버가 한다. 백엔드가 정해지기 전까지 목업이다.
// 개인정보 — 이메일 · 문의 내용은 로그에 남기지 않는다.

struct HelpCenterClient {
  var inquiries: @Sendable () async throws -> [Inquiry]
  /// 답변 받을 이메일 — 미결정: 로그인 계정 이메일(Apple 숨김 이메일일 수 있음)
  var email: @Sendable () async -> String?
  var deviceInfo: @Sendable () -> InquiryDeviceInfo
  var submit: @Sendable (_ draft: InquiryDraft, _ device: InquiryDeviceInfo) async throws -> Inquiry
}

extension HelpCenterClient: DependencyKey {
  static let liveValue = HelpCenterClient(
    inquiries: {
      [Inquiry(id: "q1", title: "투표가 반영되지 않아요", category: .relay, dateText: "2026.09.28", isAnswered: true)]
    },
    // 원본 예시 이메일은 실제 주소처럼 보여 쓰지 않는다
    email: { "me@example.com" },
    deviceInfo: {
      let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
      return InquiryDeviceInfo(
        appVersion: version,
        deviceModel: UIDevice.current.model,
        systemVersion: UIDevice.current.systemVersion
      )
    },
    submit: { draft, _ in
      @Dependency(\.uuid)
      var uuid
      return Inquiry(
        id: uuid().uuidString,
        title: draft.title,
        category: draft.category ?? .other,
        dateText: "방금",
        isAnswered: false
      )
    }
  )

  static let previewValue = liveValue

  static let testValue = HelpCenterClient(
    inquiries: unimplemented("HelpCenterClient.inquiries", placeholder: []),
    email: unimplemented("HelpCenterClient.email", placeholder: nil),
    deviceInfo: { InquiryDeviceInfo(appVersion: "1.0.0", deviceModel: "iPhone", systemVersion: "26.0") },
    submit: unimplemented(
      "HelpCenterClient.submit",
      placeholder: Inquiry(id: "", title: "", category: .other, dateText: "", isAnswered: false)
    )
  )
}

extension DependencyValues {
  var helpCenterClient: HelpCenterClient {
    get { self[HelpCenterClient.self] }
    set { self[HelpCenterClient.self] = newValue }
  }
}
