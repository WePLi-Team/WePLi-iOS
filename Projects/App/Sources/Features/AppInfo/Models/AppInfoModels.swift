import Foundation

// REQ-114 · UI-7g — 약관 및 정책. 본문은 원본 예시(법무 검토 전 — 머리말 「정책 문구는 모두 제안」)

struct AppDocument: Equatable, Identifiable, Sendable {
  struct Clause: Equatable, Sendable {
    let title: String
    let body: String
  }

  let id: String
  let title: String
  let clauses: [Clause]

  static let policyID = "policy"

  /// 원본 순서 — 서비스 이용약관 · 개인정보처리방침 · 커뮤니티 운영정책 · 오픈소스 라이선스
  static let all: [AppDocument] = [
    AppDocument(id: "terms", title: "서비스 이용약관", clauses: [
      Clause(
        title: "제1조 (목적)",
        body: "이 약관은 위플리가 제공하는 서비스의 이용 조건과 절차, 회원과 회사의 권리·의무를 정하는 것을 목적으로 합니다."
      ),
      Clause(
        title: "제2조 (회원의 게시물)",
        body: "회원이 작성한 게시글·댓글·추천곡의 권리는 회원에게 있으며, 회사는 서비스 운영에 필요한 범위에서 이를 사용할 수 있습니다."
      ),
      Clause(
        title: "제3조 (이용 제한)",
        body: "운영정책을 위반한 경우 사전 안내 후 커뮤니티 이용을 제한할 수 있으며, 회원은 이의를 신청할 수 있습니다."
      ),
    ]),
    AppDocument(id: "privacy", title: "개인정보처리방침", clauses: [
      Clause(title: "수집하는 정보", body: "소셜 로그인 식별값, 닉네임, 프로필 사진, 성향, 서비스 이용 기록"),
      Clause(
        title: "보관 기간",
        body: "회원 탈퇴 시 지체 없이 파기합니다. 단, 관련 법령에 따라 보관이 필요한 정보는 정해진 기간 동안 보관합니다."
      ),
    ]),
    // 본문은 운영정책 화면(UI-17b · CommunityPolicyText)에 있다
    AppDocument(id: policyID, title: "커뮤니티 운영정책", clauses: []),
    // 미결정 — 원본은 Pretendard 하나만 적었다. 출시 전 실제 의존성(TCA · Moya · Kingfisher · Supabase 등)으로 채운다
    AppDocument(id: "licenses", title: "오픈소스 라이선스", clauses: [
      Clause(title: "Pretendard", body: "SIL Open Font License 1.1"),
    ]),
  ]
}

enum AppInfoText {
  /// 아이콘이나 버전을 이만큼 누르면 개발자 모드가 켜진다(7g 노트 02)
  static let developerTapCount = 7

  /// 3번째 탭부터 남은 횟수를 알린다 — 「개발자 모드까지 4번 남았어요」
  static func developerToast(taps: Int) -> String? {
    if taps >= developerTapCount {
      return "개발자 모드가 켜졌어요"
    }
    return taps >= 3 ? "개발자 모드까지 \(developerTapCount - taps)번 남았어요" : nil
  }

  /// 「1.2.0」이 「1.0.0」보다 새 버전인지 — 점으로 나눈 숫자를 차례로 비교한다
  static func isNewer(_ latest: String, than current: String) -> Bool {
    let lhs = latest.split(separator: ".").map { Int($0) ?? 0 }
    let rhs = current.split(separator: ".").map { Int($0) ?? 0 }
    for index in 0 ..< max(lhs.count, rhs.count) {
      let left = index < lhs.count ? lhs[index] : 0
      let right = index < rhs.count ? rhs[index] : 0
      if left != right {
        return left > right
      }
    }
    return false
  }
}
