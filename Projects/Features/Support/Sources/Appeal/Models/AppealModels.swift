import Foundation

// REQ-073 · UI-11d · DEC-024 — 이의 신청. 게시글 · 이용 제한마다 1번, 24시간 안에 결과(알림 · 내 문의 내역).
// 결과가 뒤집히면 서버가 바로 복구하고 제한 기록을 지운다(DEC-004)

public enum AppealReason: CaseIterable, Equatable, Sendable {
  case different
  case missingContext
  case other

  public var title: String {
    switch self {
    case .different: "신고 내용과 달라요"
    case .missingContext: "맥락이 빠졌어요"
    case .other: "기타"
    }
  }
}

public struct AppealDraft: Equatable, Sendable {
  public static let textLimit = 500

  public var reason: AppealReason?
  public var text = ""

  public var canSend: Bool {
    self.reason != nil && !self.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  public init(reason: AppealReason? = nil, text: String = "") {
    self.reason = reason
    self.text = text
  }
}

public enum AppealError: Error, Equatable {
  /// 이미 이의 신청한 대상 — 건마다 1번(DEC-024)
  case alreadyAppealed
}

/// 보낸 뒤 진행 상태 — 접수 → 검토 중 → 결과 안내
public struct AppealStep: Equatable, Identifiable, Sendable {
  public enum Phase: Equatable, Sendable {
    case done
    case current
    case upcoming
  }

  public let id: Int
  public let title: String
  public let detail: String
  public let phase: Phase

  public static let afterSending: [AppealStep] = [
    AppealStep(id: 0, title: "접수 완료", detail: "방금", phase: .done),
    // 원본 「보통 24시간 이내」 — 정한 기준(24시간 안에)에 맞춤
    AppealStep(id: 1, title: "운영팀 검토 중", detail: "24시간 안에", phase: .current),
    // 결과는 알림 · 내 문의 내역으로 간다(DEC-024 · DEC-025)
    AppealStep(id: 2, title: "결과 안내", detail: "알림 · 내 문의 내역", phase: .upcoming),
  ]

  public init(id: Int, title: String, detail: String, phase: Phase) {
    self.id = id
    self.title = title
    self.detail = detail
    self.phase = phase
  }
}
