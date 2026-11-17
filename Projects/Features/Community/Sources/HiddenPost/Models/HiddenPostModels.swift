import Foundation
import WePLiSharedModels
import WePLiSupportFeatures

// UI-17c · UI-7e · DEC-024 — 신고 5건으로 임시로 가려진 내 글. 다른 사람에게는 가려지고 글쓴이에게는 그대로 보인다.
// 가려진 시각 · 사유는 서버 값(DEC-004), 날짜는 Asia/Seoul

public struct HiddenPost: Equatable, Identifiable, Sendable {
  public let id: String
  public let author: String
  public let title: String
  public let body: String
  public let song: Track?
  public let postedAt: Date
  public let hiddenAt: Date
  /// 「욕설 · 비하 표현 신고 누적」
  public let reason: String

  /// 이의 신청(UI-11d) 대상 카드
  public var appealTarget: AppealTarget {
    AppealTarget(id: self.id, kind: .post, title: self.title, reason: self.reason)
  }

  /// 신고 5건 · 임시로 가려짐 → 운영팀 검토 중 → 결과 안내
  public var steps: [AppealStep] {
    [
      AppealStep(id: 0, title: "신고 5건 · 임시로 가려짐", detail: HiddenPostText.time(self.hiddenAt), phase: .done),
      AppealStep(id: 1, title: "운영팀 검토 중", detail: "보통 24시간 이내", phase: .current),
      AppealStep(id: 2, title: "결과 안내", detail: "알림 · 내 문의 내역", phase: .upcoming),
    ]
  }

  public init(
    id: String,
    author: String,
    title: String,
    body: String,
    song: Track?,
    postedAt: Date,
    hiddenAt: Date,
    reason: String
  ) {
    self.id = id
    self.author = author
    self.title = title
    self.body = body
    self.song = song
    self.postedAt = postedAt
    self.hiddenAt = hiddenAt
    self.reason = reason
  }
}

public enum HiddenPostText {
  /// 「10월 19일」
  public static func day(_ date: Date) -> String {
    self.formatter("M월 d일").string(from: date)
  }

  /// 「10월 19일 오후 2:02」
  public static func time(_ date: Date) -> String {
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
