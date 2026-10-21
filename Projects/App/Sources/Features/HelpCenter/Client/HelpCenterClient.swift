import ComposableArchitecture
import Foundation
import UIKit

// REQ-111 · DEC-004 · DEC-025 — 문의 저장 · 답변 알림(앱 알림 · 내 문의 내역 · 원하면 이메일)은 서버가 한다.
// 백엔드가 정해지기 전까지 목업이다(내 문의 내역은 앱이 켜져 있는 동안만 기억한다). 개인정보 — 이메일 · 문의 내용은 로그에 남기지 않는다.

struct HelpCenterClient {
  var inquiries: @Sendable () async throws -> [Inquiry]
  var deviceInfo: @Sendable () async -> InquiryDeviceInfo
  var submit: @Sendable (_ draft: InquiryDraft, _ device: InquiryDeviceInfo) async throws -> Inquiry
  /// 답을 연 문의 — 읽지 않은 점을 지운다(UI-17a)
  var markRead: @Sendable (_ id: Inquiry.ID) async throws -> Void
  /// 「답변이 도움이 됐나요?」 네 · 아니요
  var rateAnswer: @Sendable (_ id: Inquiry.ID, _ isHelpful: Bool) async throws -> Void
  /// 답변 대기 중인 문의 취소
  var cancel: @Sendable (_ id: Inquiry.ID) async throws -> Void
}

extension HelpCenterClient: DependencyKey {
  static let liveValue = HelpCenterClient(
    inquiries: { MockInquiries.shared.value },
    deviceInfo: {
      let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
      // UIDevice는 MainActor 격리 — 메인에서 읽는다
      return await MainActor.run {
        InquiryDeviceInfo(
          appVersion: version,
          deviceModel: UIDevice.current.model,
          systemVersion: UIDevice.current.systemVersion
        )
      }
    },
    submit: { draft, _ in
      @Dependency(\.uuid)
      var uuid
      let inquiry = Inquiry(
        id: uuid().uuidString,
        title: draft.title,
        dateText: "방금",
        kind: .question(draft.category ?? .other, reply: nil),
        body: draft.text
      )
      MockInquiries.shared.withValue { $0.insert(inquiry, at: 0) }
      return inquiry
    },
    markRead: { id in MockInquiries.shared.withValue { $0.setRead(id, true) } },
    rateAnswer: { id, isHelpful in
      MockInquiries.shared.withValue { inquiries in
        guard let index = inquiries.firstIndex(where: { $0.id == id }) else { return }
        inquiries[index].isHelpful = isHelpful
      }
    },
    cancel: { id in MockInquiries.shared.withValue { $0.removeAll { $0.id == id } } }
  )

  static let previewValue = liveValue

  static let testValue = HelpCenterClient(
    inquiries: unimplemented("HelpCenterClient.inquiries", placeholder: []),
    deviceInfo: { InquiryDeviceInfo(appVersion: "1.0.0", deviceModel: "iPhone", systemVersion: "26.0") },
    submit: unimplemented(
      "HelpCenterClient.submit",
      placeholder: Inquiry(id: "", title: "", dateText: "", kind: .question(.other, reply: nil))
    ),
    markRead: unimplemented("HelpCenterClient.markRead"),
    rateAnswer: unimplemented("HelpCenterClient.rateAnswer"),
    cancel: unimplemented("HelpCenterClient.cancel")
  )
}

extension DependencyValues {
  var helpCenterClient: HelpCenterClient {
    get { self[HelpCenterClient.self] }
    set { self[HelpCenterClient.self] = newValue }
  }
}

/// 목업 내 문의 내역 — 원본(UI-17a) 예시 3건
enum MockInquiries {
  static let shared = LockIsolated<[Inquiry]>(Self.samples)

  static let samples: [Inquiry] = [
    Inquiry(
      id: "q1",
      title: "투표가 반영되지 않아요",
      dateText: "2026.09.28",
      kind: .question(.relay, reply: InquiryReply(
        dateText: "2026.09.29 오전 10:12",
        text: """
        안녕하세요, 위플리 운영팀이에요.
        투표는 1분마다 모아서 순위에 반영돼요. 알려주신 릴레이를 확인해 보니 투표는 정상적으로 기록되어 있었고, \
        지금은 순위에도 반영되었어요.
        기다리게 해서 죄송해요.
        """
      )),
      body: "첫 사랑 릴레이에서 투표를 했는데 순위가 그대로예요. 앱을 껐다 켜도 같아요.",
      isRead: false
    ),
    Inquiry(
      id: "a1",
      title: "비 오는 날 듣는 플리",
      dateText: "2026.10.19",
      kind: .appealResult(InquiryAppealResult(
        targetLabel: "게시글",
        postID: "p1",
        isAccepted: true,
        message: "다시 검토해 보니 운영정책 위반이 아니었어요. 게시글을 다시 보이게 했고, 이번 일로 생긴 이용 제한 기록도 지웠어요.",
        steps: [
          InquiryStep(id: 0, title: "이의 신청 접수", dateText: "10월 19일 오후 3:20"),
          InquiryStep(id: 1, title: "운영팀 다시 검토", dateText: "10월 20일 오전 9:05"),
          InquiryStep(id: 2, title: "받아들여짐 · 게시글 복구", dateText: "10월 20일 오전 11:40"),
        ]
      )),
      isRead: false
    ),
    Inquiry(
      id: "q2",
      title: "닉네임 변경이 안 돼요",
      dateText: "방금",
      kind: .question(.account, reply: nil),
      body: "닉네임을 바꾸려고 하면 이미 쓰는 이름이라고 나와요. 아무도 안 쓰는 이름 같은데 확인 부탁드려요."
    ),
  ]
}
