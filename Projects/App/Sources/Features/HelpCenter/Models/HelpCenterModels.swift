import Foundation

// REQ-111 · UI-7b — 고객센터. FAQ 답변은 원본 예시(정책 문구는 확인 필요)

struct HelpFAQ: Equatable, Identifiable, Sendable {
  let id: Int
  let question: String
  let answer: String

  /// 원본(UI-7b) 5개
  static let all: [HelpFAQ] = [
    HelpFAQ(
      id: 0,
      question: "투표는 몇 번까지 할 수 있나요?",
      answer: "릴레이리스트마다 상위 10곡에 대해 곡마다 한 번씩 ‘어울려요 / 별로예요’를 고를 수 있어요. 마감 전까지는 다시 바꿀 수 있어요."
    ),
    HelpFAQ(id: 1, question: "추천한 곡이 목록에 안 보여요", answer: "이미 누군가 추천한 곡이면 새로 추가되지 않고, 기존 곡에 점수가 더해져요."),
    HelpFAQ(
      id: 2,
      question: "전체 곡은 들을 수 없나요?",
      answer: "위플리에서는 30초 미리듣기를 제공해요. 전체 곡은 ‘Music에서 듣기’를 눌러 Apple Music 앱에서 들을 수 있어요."
    ),
    HelpFAQ(id: 3, question: "닉네임과 성향을 바꾸고 싶어요", answer: "마이 › 내 정보 수정에서 언제든 바꿀 수 있어요."),
    // 탈퇴 유예 14일(UI-7c · 17e) — 원본 「바로 삭제할 수 있어요」를 맞춤
    HelpFAQ(
      id: 4,
      question: "계정을 삭제하려면 어떻게 하나요?",
      answer: "마이 › 계정 관리 › 회원 탈퇴에서 신청할 수 있어요. 14일 안에 다시 로그인하면 되살릴 수 있고, 14일이 지나면 모든 정보가 삭제돼요."
    ),
  ]
}

enum InquiryCategory: CaseIterable, Equatable, Hashable, Sendable {
  case account
  case relay
  case community
  case playback
  case other

  var title: String {
    switch self {
    case .account: "계정 · 로그인"
    case .relay: "릴레이 · 투표"
    case .community: "커뮤니티"
    case .playback: "재생 · Apple Music"
    case .other: "기타"
    }
  }
}

struct Inquiry: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  let category: InquiryCategory
  /// 「2026.09.28」 · 「방금」
  let dateText: String
  var isAnswered: Bool
}

struct InquiryDraft: Equatable, Sendable {
  static let textLimit = 1000
  static let photoLimit = 3
  /// 문의 내역 제목 길이(원본 24자)
  static let titleLength = 24
  /// 이메일 칸(원본 80자)
  static let emailLimit = 80

  var category: InquiryCategory?
  var text = ""
  /// 고른 사진(JPEG)
  var photos: [Data] = []
  /// 「이메일로도 받기」 — 기본은 앱 알림 · 내 문의 내역(DEC-025). Apple 숨김 이메일로는 답변이 안 갈 수 있어 직접 적는다
  var wantsEmail = false
  var email = ""

  /// 보낼 이메일 — 켰고 비어 있지 않을 때만
  var replyEmail: String? {
    let email = self.email.trimmingCharacters(in: .whitespacesAndNewlines)
    return self.wantsEmail && !email.isEmpty ? email : nil
  }

  /// 원본: 이메일 칸은 보내기 조건에 들지 않는다
  var canSend: Bool {
    self.category != nil && !self.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var title: String {
    String(self.text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.titleLength))
  }
}

/// 자동 첨부 — 앱 버전 · 기기 모델 · iOS 버전
struct InquiryDeviceInfo: Equatable, Sendable {
  let appVersion: String
  let deviceModel: String
  let systemVersion: String
}
