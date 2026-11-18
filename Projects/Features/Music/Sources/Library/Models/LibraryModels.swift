import Foundation
import WePLiSharedModels

// REQ-077 · UI-5c

public enum LibrarySegment: Int, CaseIterable, Equatable, Sendable {
  case playlists
  case relays
  case likes

  public var title: String {
    switch self {
    case .playlists: "내 플레이리스트"
    case .relays: "참여한 릴레이"
    case .likes: "좋아요·저장"
    }
  }
}

public struct LibraryPlaylist: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  /// 「82곡」 · 「3곡 · 게시글로 공유됨」
  public let subtitle: String

  public init(id: String, title: String, subtitle: String) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
  }
}

public struct LibraryLiveRelay: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  public let endsAt: Date
  /// 「2곡 · 최고 4위」
  public let myRecommendations: String
  /// 「4 / 10 진행」
  public let voteProgress: String

  public init(id: String, title: String, endsAt: Date, myRecommendations: String, voteProgress: String) {
    self.id = id
    self.title = title
    self.endsAt = endsAt
    self.myRecommendations = myRecommendations
    self.voteProgress = voteProgress
  }
}

public struct LibraryCompletedRelay: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  /// 「내 추천곡 ‘EASY’ 최종 3위」
  public let subtitle: String

  public init(id: String, title: String, subtitle: String) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
  }
}

public struct LibrarySavedPost: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  /// 「chuuuuu__ · 노래 1곡」
  public let subtitle: String
  public let author: String

  public init(id: String, title: String, subtitle: String, author: String) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.author = author
  }
}

public struct Library: Equatable, Sendable {
  public var playlists: [LibraryPlaylist]
  public var liveRelays: [LibraryLiveRelay]
  public var completedRelays: [LibraryCompletedRelay]
  public var likedSongs: [Track]
  public var savedPosts: [LibrarySavedPost]

  public static let empty = Library(playlists: [], liveRelays: [], completedRelays: [], likedSongs: [], savedPosts: [])

  public init(
    playlists: [LibraryPlaylist],
    liveRelays: [LibraryLiveRelay],
    completedRelays: [LibraryCompletedRelay],
    likedSongs: [Track],
    savedPosts: [LibrarySavedPost]
  ) {
    self.playlists = playlists
    self.liveRelays = liveRelays
    self.completedRelays = completedRelays
    self.likedSongs = likedSongs
    self.savedPosts = savedPosts
  }
}
