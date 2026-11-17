import Foundation
import WePLiSharedModels

// REQ-060 · UI-1d

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
  /// 신고로 임시로 가려진 내 글 — 있으면 맨 위 안내 카드(UI-7e)
  var hiddenMine: HiddenPost?
}
