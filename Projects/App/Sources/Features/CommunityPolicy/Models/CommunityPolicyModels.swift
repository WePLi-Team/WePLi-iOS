import Foundation

// UI-17b · DEC-027 — 커뮤니티 운영정책. 제한 단계는 위반이 확인될 때마다 하나씩 올라간다.
// 지금 내 단계 · 이의 신청 대상은 서버 값(DEC-004)

/// 이용 제한 단계 한 줄 — 「3회 · 7일 제한 · 게시글 · 댓글 · 곡 추천」
struct PolicyStep: Equatable, Identifiable, Sendable {
  /// 몇 번째 위반인지(1–5)
  let id: Int
  let title: String
  let detail: String

  var countLabel: String {
    "\(self.id)회"
  }
}

/// 내 운영정책 상태 — 위반이 없으면 step이 nil, 이용 제한 중일 때만 이의 신청 대상이 있다
struct CommunityStanding: Equatable, Sendable {
  var step: Int?
  var appealTarget: AppealTarget?

  static let clean = CommunityStanding()
}

enum CommunityPolicyText {
  /// 원본 예시 — 시행일은 법무 검토 뒤 정한다
  static let effectiveDate = "시행일 2026년 11월 1일"

  static let bannedActions = [
    "욕설 · 비하 · 혐오 표현",
    "음란물, 불법 촬영물",
    "광고 · 스팸 · 같은 글 반복",
    "다른 사람을 사칭하거나 개인정보를 올리는 것",
    "저작권이 있는 음원 파일을 올리는 것",
  ]

  /// 1회 경고 → 3일 → 7일 → 30일 → 영구(DEC-027)
  static let steps = [
    PolicyStep(id: 1, title: "경고", detail: "알림으로 알려드려요"),
    PolicyStep(id: 2, title: "3일 제한", detail: "게시글 · 댓글 · 곡 추천"),
    PolicyStep(id: 3, title: "7일 제한", detail: "게시글 · 댓글 · 곡 추천"),
    PolicyStep(id: 4, title: "30일 제한", detail: "게시글 · 댓글 · 곡 추천 · 릴레이 열기"),
    PolicyStep(id: 5, title: "영구 제한", detail: "커뮤니티 기능 전체 · 음악 듣기와 보관함은 그대로"),
  ]

  static let notes = [
    "위반 기록은 1년이 지나면 하나씩 지워져요.",
    "불법 촬영물 · 아동 대상 성적 콘텐츠 · 개인정보 노출은 횟수와 상관없이 바로 영구 제한돼요.",
    "서로 다른 5명이 신고한 글은 운영팀이 확인하기 전까지 임시로 가려져요.",
    "결과에 동의하지 않으면 한 번 이의 신청할 수 있고, 24시간 안에 결과를 알려드려요.",
  ]
}
