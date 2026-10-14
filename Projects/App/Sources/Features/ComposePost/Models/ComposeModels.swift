import Foundation

// REQ-061 · REQ-062 · UI-2b · UI-2a

/// 게시글에 붙이는 곡. 같은 곡은 카탈로그 id로 가려낸다(표기가 달라도 같은 곡).
struct ComposeTrack: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  let artist: String
}

struct PostDraft: Equatable, Sendable {
  var title: String
  var body: String
  var tracks: [ComposeTrack]
}

enum ComposeInput {
  static let bodyLimit = 500

  /// 보이는 글자 기준으로 자른다
  static func clampBody(_ text: String) -> String {
    text.count > self.bodyLimit ? String(text.prefix(self.bodyLimit)) : text
  }

  static func hasText(_ text: String) -> Bool {
    !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}

/// 최근 검색어 — 최신순 · 중복 제거 · 8개 (UI-2a)
enum RecentSearches {
  static let limit = 8

  static func adding(_ term: String, to list: [String]) -> [String] {
    Array(([term] + list.filter { $0 != term }).prefix(self.limit))
  }
}
