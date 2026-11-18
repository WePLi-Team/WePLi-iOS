import Foundation
import WePLiSharedModels

// REQ-061 · REQ-062 · UI-2b · UI-2a

public struct PostDraft: Equatable, Sendable {
  public var title: String
  public var body: String
  public var tracks: [ComposeTrack]

  public init(title: String, body: String, tracks: [ComposeTrack]) {
    self.title = title
    self.body = body
    self.tracks = tracks
  }
}

public enum ComposeInput {
  public static let bodyLimit = 500

  /// 보이는 글자 기준으로 자른다
  public static func clampBody(_ text: String) -> String {
    text.count > self.bodyLimit ? String(text.prefix(self.bodyLimit)) : text
  }

  public static func hasText(_ text: String) -> Bool {
    !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}

/// 최근 검색어 — 최신순 · 중복 제거 · 8개 (UI-2a)
public enum RecentSearches {
  public static let limit = 8

  public static func adding(_ term: String, to list: [String]) -> [String] {
    Array(([term] + list.filter { $0 != term }).prefix(self.limit))
  }
}
