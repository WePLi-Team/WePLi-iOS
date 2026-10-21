import Foundation

// REQ-111 · UI-7b · UI-17a — 고객센터 · 내 문의 내역. FAQ 답변은 원본 예시(정책 문구는 확인 필요)

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
    HelpFAQ(id: 4, question: "계정을 삭제하려면 어떻게 하나요?", answer: "마이 › 계정 관리 › 회원 탈퇴에서 바로 삭제할 수 있어요."),
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

/// 내 문의 내역 한 건 — 1:1 문의 답변과 이의 신청 결과가 한 목록에 온다(UI-17a · DEC-024 · DEC-025)
struct Inquiry: Equatable, Identifiable, Sendable {
  enum Kind: Equatable, Sendable {
    /// 1:1 문의 — 답변이 없으면 답변 대기
    case question(InquiryCategory, reply: InquiryReply?)
    /// 이의 신청 결과(UI-11d)
    case appealResult(InquiryAppealResult)
  }

  let id: String
  let title: String
  /// 「2026.09.28」 · 「방금」
  let dateText: String
  var kind: Kind
  /// 내가 보낸 내용
  var body = ""
  var isRead = true
  /// 「답변이 도움이 됐나요?」 — 네 true · 아니요 false
  var isHelpful: Bool?

  var status: InquiryStatus {
    switch self.kind {
    case let .question(_, reply): reply == nil ? .waiting : .answered
    case let .appealResult(result): result.isAccepted ? .accepted : .rejected
    }
  }

  var isAppealResult: Bool {
    if case .appealResult = self.kind {
      return true
    }
    return false
  }

  /// 「1:1 문의」 · 「이의 신청 결과」
  var kindTitle: String {
    switch self.kind {
    case .question: "1:1 문의"
    case .appealResult: "이의 신청 결과"
    }
  }

  /// 「릴레이 · 투표 · 2026.09.28」 · 「게시글 · 2026.10.19」
  var meta: String {
    switch self.kind {
    case let .question(category, _): "\(category.title) · \(self.dateText)"
    case let .appealResult(result): "\(result.targetLabel) · \(self.dateText)"
    }
  }

  /// 읽지 않은 점 — 답을 받았고 아직 열지 않았을 때만(원본)
  var showsUnreadDot: Bool {
    !self.isRead && self.status != .waiting
  }
}

enum InquiryStatus: Equatable, Sendable {
  case answered
  case accepted
  case rejected
  case waiting

  var title: String {
    switch self {
    case .answered: "답변 완료"
    case .accepted: "받아들여짐"
    // 원본에 없는 상태 — 디자인 확인 필요
    case .rejected: "받아들여지지 않음"
    case .waiting: "답변 대기"
    }
  }
}

/// 위플리 운영팀 답변
struct InquiryReply: Equatable, Sendable {
  /// 「2026.09.29 오전 10:12」 — 서버 값
  let dateText: String
  let text: String
}

/// 이의 신청 결과 — 결과 · 설명 · 진행 기록은 서버가 정한다(DEC-004)
struct InquiryAppealResult: Equatable, Sendable {
  /// 「게시글」 · 「이용 제한」
  let targetLabel: String
  /// 결과를 보고 열 내 게시글 — 이용 제한 대상이면 없다
  let postID: String?
  let isAccepted: Bool
  let message: String
  let steps: [InquiryStep]

  var headline: String {
    // 받아들여지지 않은 결과는 원본에 없는 문구 — 디자인 확인 필요
    self.isAccepted ? "이의 신청이 받아들여졌어요" : "이의 신청이 받아들여지지 않았어요"
  }
}

/// 진행 기록 한 줄 — 「이의 신청 접수」 · 「10월 19일 오후 3:20」
struct InquiryStep: Equatable, Identifiable, Sendable {
  let id: Int
  let title: String
  let dateText: String
}

extension [Inquiry] {
  /// 읽음 표시 — 먼저 반영하고 실패하면 되돌린다
  mutating func setRead(_ id: Inquiry.ID, _ isRead: Bool) {
    guard let index = self.firstIndex(where: { $0.id == id }) else { return }
    self[index].isRead = isRead
  }
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
