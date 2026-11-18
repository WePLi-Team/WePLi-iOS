import Foundation
import WePLiSharedModels

// REQ-063 · REQ-064 · UI-2c · UI-9c · UI-9d

public struct PostComment: Equatable, Identifiable, Sendable {
  public let id: String
  public let author: String
  /// 「2시간」 · 「방금」
  public let timeText: String
  public let text: String
  /// 노래로 답한 댓글(UI-9d)
  public var song: Track?
  public var likeCount: Int
  public var isLiked = false
  public var isMine = false
  public var replies: [PostComment] = []

  /// 좋아요 수가 0이면 숫자를 숨긴다(UI-2c)
  public var likeText: String? {
    self.likeCount > 0 ? CountFormatter.string(self.likeCount) : nil
  }

  public init(
    id: String,
    author: String,
    timeText: String,
    text: String,
    song: Track? = nil,
    likeCount: Int,
    isLiked: Bool = false,
    isMine: Bool = false,
    replies: [PostComment] = []
  ) {
    self.id = id
    self.author = author
    self.timeText = timeText
    self.text = text
    self.song = song
    self.likeCount = likeCount
    self.isLiked = isLiked
    self.isMine = isMine
    self.replies = replies
  }
}

public struct PostThread: Equatable, Sendable {
  public var post: Post
  public var comments: [PostComment]

  public init(post: Post, comments: [PostComment]) {
    self.post = post
    self.comments = comments
  }
}

public enum CommentInput {
  /// 곡만 붙이고 글을 비우면 들어가는 문구(UI-9d)
  public static let songOnlyText = "이 노래 추천해요"

  /// 보낼 본문 — 글도 곡도 없으면 nil
  public static func text(draft: String, hasSong: Bool) -> String? {
    let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmed.isEmpty {
      return trimmed
    }
    return hasSong ? self.songOnlyText : nil
  }
}
