import Foundation

// REQ-023 · UI-2d

public struct SongDetail: Equatable, Identifiable, Sendable {
  public struct Album: Equatable, Sendable {
    public let title: String
    public let artist: String
    /// 「2017.03.24」
    public let releaseDate: String
    /// 「싱글」 · 「정규」 · 「미니」
    public let type: String
    public let year: Int

    public init(title: String, artist: String, releaseDate: String, type: String, year: Int) {
      self.title = title
      self.artist = artist
      self.releaseDate = releaseDate
      self.type = type
      self.year = year
    }
  }

  public struct RelatedSong: Equatable, Identifiable, Sendable {
    public var id: String {
      self.title
    }

    public let title: String
    public let artist: String

    public init(title: String, artist: String) {
      self.title = title
      self.artist = artist
    }
  }

  public struct OtherAlbum: Equatable, Identifiable, Sendable {
    public var id: String {
      self.title
    }

    public let title: String
    /// 「2024 · 미니」
    public let subtitle: String

    public init(title: String, subtitle: String) {
      self.title = title
      self.subtitle = subtitle
    }
  }

  public let id: String
  public let title: String
  public let artist: String
  public let lyricist: String
  public let composer: String
  public let genres: [String]
  public let album: Album
  public var likeCount: Int
  public let commentCount: Int
  public var isLiked: Bool
  public let related: [RelatedSong]
  public let otherAlbums: [OtherAlbum]

  /// 「밤편지 · 싱글 · 2017」
  public var meta: String {
    "\(self.album.title) · \(self.album.type) · \(self.album.year)"
  }

  public init(
    id: String,
    title: String,
    artist: String,
    lyricist: String,
    composer: String,
    genres: [String],
    album: Album,
    likeCount: Int,
    commentCount: Int,
    isLiked: Bool,
    related: [RelatedSong],
    otherAlbums: [OtherAlbum]
  ) {
    self.id = id
    self.title = title
    self.artist = artist
    self.lyricist = lyricist
    self.composer = composer
    self.genres = genres
    self.album = album
    self.likeCount = likeCount
    self.commentCount = commentCount
    self.isLiked = isLiked
    self.related = related
    self.otherAlbums = otherAlbums
  }
}

/// 30초 미리듣기 (UI-2d · UI-4b)
public enum SongPreview {
  public static let length = 30

  /// 「0:07」
  public static func elapsedText(_ position: Int) -> String {
    String(format: "0:%02d", min(max(position, 0), self.length))
  }

  /// 「-0:23」
  public static func remainingText(_ position: Int) -> String {
    String(format: "-0:%02d", self.length - min(max(position, 0), self.length))
  }

  public static func progress(_ position: Int) -> Double {
    Double(min(max(position, 0), self.length)) / Double(self.length)
  }
}
