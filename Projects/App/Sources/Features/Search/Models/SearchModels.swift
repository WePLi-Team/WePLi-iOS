import Foundation

// REQ-080 · UI-4c — 통합 검색 규칙(원본 turn4 그대로)

enum SearchScope: CaseIterable, Equatable, Sendable {
  case all
  case song
  case list
  case user

  var title: String {
    switch self {
    case .all: "전체"
    case .song: "곡"
    case .list: "플리·릴레이"
    case .user: "사용자"
    }
  }
}

struct SearchSong: Equatable, Identifiable, Sendable {
  var id: String {
    "\(self.title)|\(self.artist)"
  }

  let title: String
  let artist: String
  var tags: [String] = []
}

/// 플레이리스트 · 릴레이 · 게시글을 한 섹션에서 보여 준다(부가정보로 구분)
struct SearchList: Equatable, Identifiable, Sendable {
  var id: String {
    self.title
  }

  let title: String
  /// 「릴레이리스트 · 3,012명 참여」 · 「플레이리스트 · WePLi」 · 「게시글 · 김동」
  let subtitle: String
  var tags: [String] = []
}

struct SearchUser: Equatable, Identifiable, Sendable {
  var id: String {
    self.name
  }

  let name: String
  /// 「센티멘탈 심포니 · 게시글 24」
  let subtitle: String
}

struct SearchCatalog: Equatable, Sendable {
  var songs: [SearchSong]
  var lists: [SearchList]
  var users: [SearchUser]
}

struct SearchResults: Equatable, Sendable {
  var songs: [SearchSong] = []
  var lists: [SearchList] = []
  var users: [SearchUser] = []

  var isEmpty: Bool {
    self.songs.isEmpty && self.lists.isEmpty && self.users.isEmpty
  }
}

enum SearchEngine {
  /// 앞뒤 공백 제거 → 맨 앞 「#」 하나 제거 → 소문자
  static func normalize(_ query: String) -> String {
    var text = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if text.hasPrefix("#") {
      text.removeFirst()
    }
    return text.lowercased()
  }

  /// 부분 일치(제목 · 아티스트 · 부가정보) 또는 태그 정확히 일치.
  /// 개수는 「전체」에서 곡 4 · 플리/릴레이 3 · 사용자 3, 개별 범위는 그 종류만 10. 정렬하지 않는다.
  static func search(_ query: String, scope: SearchScope, in catalog: SearchCatalog) -> SearchResults {
    let needle = self.normalize(query)
    guard !needle.isEmpty else { return SearchResults() }
    let matches = { (text: String, tags: [String]) in
      text.lowercased().contains(needle) || tags.contains { $0.lowercased() == needle }
    }
    let songs = catalog.songs.filter { matches("\($0.title) \($0.artist) ", $0.tags) }
    let lists = catalog.lists.filter { matches("\($0.title)  \($0.subtitle)", $0.tags) }
    let users = catalog.users.filter { matches("\($0.name)  \($0.subtitle)", []) }
    return SearchResults(
      songs: scope == .all ? Array(songs.prefix(4)) : scope == .song ? Array(songs.prefix(10)) : [],
      lists: scope == .all ? Array(lists.prefix(3)) : scope == .list ? Array(lists.prefix(10)) : [],
      users: scope == .all ? Array(users.prefix(3)) : scope == .user ? Array(users.prefix(10)) : []
    )
  }
}
