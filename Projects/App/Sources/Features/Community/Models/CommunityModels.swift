import Foundation

// REQ-060 · UI-1d

struct Track: Equatable, Sendable {
  let title: String
  let artist: String
}

struct Post: Equatable, Identifiable, Sendable {
  enum Attachment: Equatable, Sendable {
    case none
    /// 곡 칩: 「곡 - 아티스트」 한 줄
    case song(Track)
    case playlist([Track])
  }

  let id: String
  let author: String
  let title: String
  let body: String
  let attachment: Attachment
  /// 서버 값(내 좋아요 포함)
  var likeCount: Int
  let commentCount: Int
  var isLiked: Bool
  var isSaved: Bool
}

struct Story: Equatable, Identifiable, Sendable {
  var id: String {
    self.user
  }

  let user: String
  /// 새 스토리(라벤더 링) · 본 스토리(회색 링)
  let isFresh: Bool
}

struct CommunityFeed: Equatable, Sendable {
  var stories: [Story]
  var posts: [Post]
}

/// 「10,123」 — 천 단위 쉼표 (원본 toLocaleString('en-US'))
enum CountFormatter {
  static func string(_ count: Int) -> String {
    count.formatted(.number.locale(Locale(identifier: "en_US")))
  }
}
