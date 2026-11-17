import Foundation
import WePLiSharedModels

// REQ-060 · UI-1d

public struct Story: Equatable, Identifiable, Sendable {
  public var id: String {
    self.user
  }

  public let user: String
  /// 새 스토리(라벤더 링) · 본 스토리(회색 링)
  public let isFresh: Bool

  public init(user: String, isFresh: Bool) {
    self.user = user
    self.isFresh = isFresh
  }
}

public struct CommunityFeed: Equatable, Sendable {
  public var stories: [Story]
  public var posts: [Post]
  /// 신고로 임시로 가려진 내 글 — 있으면 맨 위 안내 카드(UI-7e)
  public var hiddenMine: HiddenPost?

  public init(stories: [Story], posts: [Post], hiddenMine: HiddenPost? = nil) {
    self.stories = stories
    self.posts = posts
    self.hiddenMine = hiddenMine
  }
}
