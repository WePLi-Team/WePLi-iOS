import Foundation

// REQ-077 · UI-5c

enum LibrarySegment: Int, CaseIterable, Equatable, Sendable {
  case playlists
  case relays
  case likes

  var title: String {
    switch self {
    case .playlists: "내 플레이리스트"
    case .relays: "참여한 릴레이"
    case .likes: "좋아요·저장"
    }
  }
}

struct LibraryPlaylist: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  /// 「82곡」 · 「3곡 · 게시글로 공유됨」
  let subtitle: String
}

struct LibraryLiveRelay: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  let endsAt: Date
  /// 「2곡 · 최고 4위」
  let myRecommendations: String
  /// 「4 / 10 진행」
  let voteProgress: String
}

struct LibraryCompletedRelay: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  /// 「내 추천곡 ‘EASY’ 최종 3위」
  let subtitle: String
}

struct LibrarySavedPost: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  /// 「chuuuuu__ · 노래 1곡」
  let subtitle: String
  let author: String
}

struct Library: Equatable, Sendable {
  var playlists: [LibraryPlaylist]
  var liveRelays: [LibraryLiveRelay]
  var completedRelays: [LibraryCompletedRelay]
  var likedSongs: [Track]
  var savedPosts: [LibrarySavedPost]

  static let empty = Library(playlists: [], liveRelays: [], completedRelays: [], likedSongs: [], savedPosts: [])
}
