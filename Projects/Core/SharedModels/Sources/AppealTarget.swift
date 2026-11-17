import Foundation

// DEC-033 · 여러 기능이 함께 쓰는 값 타입 — 기능 폴더에서 옮겨 왔다

/// 이의 신청 대상 — 7e 가려진 글 · 7d 이용 제한
public struct AppealTarget: Equatable, Sendable {
  public enum Kind: Equatable, Sendable {
    case post
    case restriction
  }

  public let id: String
  public let kind: Kind
  /// 「비 오는 날 듣는 플리」 · 「커뮤니티 7일 이용 제한」
  public let title: String
  /// 「욕설 · 비하 표현 신고 누적」
  public let reason: String

  /// 「대상 게시글」 — 이용 제한 대상은 원본에 없어 같은 꼴로 둔다
  public var label: String {
    switch self.kind {
    case .post: "대상 게시글"
    case .restriction: "대상 이용 제한"
    }
  }

  /// 「가려진 사유 · …」 · 「제한 사유 · …」
  public var reasonLine: String {
    switch self.kind {
    case .post: "가려진 사유 · \(self.reason)"
    case .restriction: "제한 사유 · \(self.reason)"
    }
  }

  public init(id: String, kind: Kind, title: String, reason: String) {
    self.id = id
    self.kind = kind
    self.title = title
    self.reason = reason
  }
}
