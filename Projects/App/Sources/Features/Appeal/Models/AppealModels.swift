import Foundation

// REQ-073 · UI-11d · DEC-024 — 이의 신청. 게시글 · 이용 제한마다 1번, 24시간 안에 결과(알림 · 내 문의 내역).
// 결과가 뒤집히면 서버가 바로 복구하고 제한 기록을 지운다(DEC-004)

/// 이의 신청 대상 — 7e 가려진 글 · 7d 이용 제한
struct AppealTarget: Equatable, Sendable {
  enum Kind: Equatable, Sendable {
    case post
    case restriction
  }

  let id: String
  let kind: Kind
  /// 「비 오는 날 듣는 플리」 · 「커뮤니티 7일 이용 제한」
  let title: String
  /// 「욕설 · 비하 표현 신고 누적」
  let reason: String

  /// 「대상 게시글」 — 이용 제한 대상은 원본에 없어 같은 꼴로 둔다
  var label: String {
    switch self.kind {
    case .post: "대상 게시글"
    case .restriction: "대상 이용 제한"
    }
  }

  /// 「가려진 사유 · …」 · 「제한 사유 · …」
  var reasonLine: String {
    switch self.kind {
    case .post: "가려진 사유 · \(self.reason)"
    case .restriction: "제한 사유 · \(self.reason)"
    }
  }
}

enum AppealReason: CaseIterable, Equatable, Sendable {
  case different
  case missingContext
  case other

  var title: String {
    switch self {
    case .different: "신고 내용과 달라요"
    case .missingContext: "맥락이 빠졌어요"
    case .other: "기타"
    }
  }
}

struct AppealDraft: Equatable, Sendable {
  static let textLimit = 500

  var reason: AppealReason?
  var text = ""

  var canSend: Bool {
    self.reason != nil && !self.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}

enum AppealError: Error, Equatable {
  /// 이미 이의 신청한 대상 — 건마다 1번(DEC-024)
  case alreadyAppealed
}

/// 보낸 뒤 진행 상태 — 접수 → 검토 중 → 결과 안내
struct AppealStep: Equatable, Identifiable, Sendable {
  enum Phase: Equatable, Sendable {
    case done
    case current
    case upcoming
  }

  let id: Int
  let title: String
  let detail: String
  let phase: Phase

  static let afterSending: [AppealStep] = [
    AppealStep(id: 0, title: "접수 완료", detail: "방금", phase: .done),
    // 원본 「보통 24시간 이내」 — 정한 기준(24시간 안에)에 맞춤
    AppealStep(id: 1, title: "운영팀 검토 중", detail: "24시간 안에", phase: .current),
    // 결과는 알림 · 내 문의 내역으로 간다(DEC-024 · DEC-025)
    AppealStep(id: 2, title: "결과 안내", detail: "알림 · 내 문의 내역", phase: .upcoming),
  ]
}
