import Foundation

// REQ-023 · UI-2d

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
  let related: [RelatedSong]
  let otherAlbums: [OtherAlbum]

  /// 「밤편지 · 싱글 · 2017」
  var meta: String {
    "\(self.album.title) · \(self.album.type) · \(self.album.year)"
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
