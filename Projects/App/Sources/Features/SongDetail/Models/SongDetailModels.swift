import Foundation

// REQ-023 · UI-2d v2

struct SongDetail: Equatable, Identifiable, Sendable {
  struct Album: Equatable, Sendable {
    let title: String
    let artist: String
    /// 「2017.03.24」
    let releaseDate: String
    /// 「싱글」 · 「정규」 · 「미니」
    let type: String
    let year: Int
  }

  struct RelatedSong: Equatable, Identifiable, Sendable {
    var id: String {
      self.title
    }

    let title: String
    let artist: String
  }

  /// 이 곡이 올라간 릴레이 — 지금 순위와 변동(2d v2)
  struct Relay: Equatable, Identifiable, Sendable {
    enum Change: Equatable, Sendable {
      case up(Int)
      case down(Int)
      case same
      /// 완성된 릴레이 — 「최종」
      case final
    }

    let id: String
    let title: String
    /// 「#첫사랑 #설렘」
    let tags: String
    let isLive: Bool
    let rank: Int
    let change: Change
  }

  /// 댓글 미리보기(2d v2)
  struct Comment: Equatable, Identifiable, Sendable {
    let id: String
    let author: String
    /// 「2시간 전」
    let time: String
    let body: String
    let likeCount: Int
  }

  struct OtherAlbum: Equatable, Identifiable, Sendable {
    var id: String {
      self.title
    }

    let title: String
    /// 「2024 · 미니」
    let subtitle: String
  }

  let id: String
  let title: String
  let artist: String
  let lyricist: String
  let composer: String
  let genres: [String]
  let album: Album
  var likeCount: Int
  let commentCount: Int
  var isLiked: Bool
  let relays: [Relay]
  /// 이번 주에 들은 친구 — 앞 사람 이름과 나머지 수
  let friendListeners: [String]
  let comments: [Comment]
  let related: [RelatedSong]
  let otherAlbums: [OtherAlbum]

  /// 「밤편지 · 싱글 · 2017.03.24」
  var meta: String {
    "\(self.album.title) · \(self.album.type) · \(self.album.releaseDate)"
  }

  /// 「#아이유(IU)」 — 가수는 해시태그로 쓴다(2d v2)
  var artistTag: String {
    "#" + self.artist.replacingOccurrences(of: " ", with: "")
  }
}

/// 30초 미리듣기 (UI-2d · UI-4b)
enum SongPreview {
  static let length = 30

  /// 「0:07」
  static func elapsedText(_ position: Int) -> String {
    String(format: "0:%02d", min(max(position, 0), self.length))
  }

  /// 「-0:23」
  static func remainingText(_ position: Int) -> String {
    String(format: "-0:%02d", self.length - min(max(position, 0), self.length))
  }

  static func progress(_ position: Int) -> Double {
    Double(min(max(position, 0), self.length)) / Double(self.length)
  }
}
