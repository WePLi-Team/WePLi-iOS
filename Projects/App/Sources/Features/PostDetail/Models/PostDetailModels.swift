import Foundation

// REQ-063 · REQ-064 · UI-2c · UI-9c · UI-9d

struct PostComment: Equatable, Identifiable, Sendable {
  let id: String
  let author: String
  /// 「2시간」 · 「방금」
  let timeText: String
  let text: String
  /// 노래로 답한 댓글(UI-9d)
  var song: Track?
  var likeCount: Int
  var isLiked = false
  var isMine = false
  var replies: [PostComment] = []

  /// 좋아요 수가 0이면 숫자를 숨긴다(UI-2c)
  var likeText: String? {
    self.likeCount > 0 ? CountFormatter.string(self.likeCount) : nil
  }
}

struct PostThread: Equatable, Sendable {
  var post: Post
  var comments: [PostComment]
}

enum CommentInput {
  /// 곡만 붙이고 글을 비우면 들어가는 문구(UI-9d)
  static let songOnlyText = "이 노래 추천해요"

  /// 보낼 본문 — 글도 곡도 없으면 nil
  static func text(draft: String, hasSong: Bool) -> String? {
    let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmed.isEmpty {
      return trimmed
    }
    return hasSong ? self.songOnlyText : nil
  }
}
