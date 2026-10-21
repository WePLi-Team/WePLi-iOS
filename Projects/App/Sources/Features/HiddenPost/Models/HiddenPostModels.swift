import Foundation

// UI-17c · UI-7e · DEC-024 — 신고 5건으로 임시로 가려진 내 글. 다른 사람에게는 가려지고 글쓴이에게는 그대로 보인다.
// 가려진 시각 · 사유는 서버 값(DEC-004), 날짜는 Asia/Seoul

struct HiddenPost: Equatable, Identifiable, Sendable {
  let id: String
  let author: String
  let title: String
  let body: String
  let song: Track?
  let postedAt: Date
  let hiddenAt: Date
  /// 「욕설 · 비하 표현 신고 누적」
  let reason: String

  /// 이의 신청(UI-11d) 대상 카드
  var appealTarget: AppealTarget {
    AppealTarget(id: self.id, kind: .post, title: self.title, reason: self.reason)
  }

  /// 신고 5건 · 임시로 가려짐 → 운영팀 검토 중 → 결과 안내
  var steps: [AppealStep] {
    [
      AppealStep(id: 0, title: "신고 5건 · 임시로 가려짐", detail: HiddenPostText.time(self.hiddenAt), phase: .done),
      AppealStep(id: 1, title: "운영팀 검토 중", detail: "보통 24시간 이내", phase: .current),
      AppealStep(id: 2, title: "결과 안내", detail: "알림 · 내 문의 내역", phase: .upcoming),
    ]
  }
}

enum HiddenPostText {
  /// 「10월 19일」
  static func day(_ date: Date) -> String {
    self.formatter("M월 d일").string(from: date)
  }

  /// 「10월 19일 오후 2:02」
  static func time(_ date: Date) -> String {
    self.formatter("M월 d일 a h:mm").string(from: date)
  }

  private static func formatter(_ format: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
    formatter.dateFormat = format
    return formatter
  }
}
