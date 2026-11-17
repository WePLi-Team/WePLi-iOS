import Foundation

// DEC-033 · 여러 기능이 함께 쓰는 값 타입 — 기능 폴더에서 옮겨 왔다

public struct Post: Equatable, Identifiable, Sendable {
  public enum Attachment: Equatable, Sendable {
    case none
    /// 곡 칩: 「곡 - 아티스트」 한 줄
    case song(Track)
    case playlist([Track])
  }

  public let id: String
  public let author: String
  public let title: String
  public let body: String
  public let attachment: Attachment
  /// 서버 값(내 좋아요 포함)
  public var likeCount: Int
  public let commentCount: Int
  public var isLiked: Bool
  public var isSaved: Bool

  public init(
    id: String,
    author: String,
    title: String,
    body: String,
    attachment: Attachment,
    likeCount: Int,
    commentCount: Int,
    isLiked: Bool,
    isSaved: Bool
  ) {
    self.id = id
    self.author = author
    self.title = title
    self.body = body
    self.attachment = attachment
    self.likeCount = likeCount
    self.commentCount = commentCount
    self.isLiked = isLiked
    self.isSaved = isSaved
  }
}
