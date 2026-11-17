import Foundation

// DEC-033 · 여러 기능이 함께 쓰는 값 타입 — 기능 폴더에서 옮겨 왔다

/// 게시글에 붙이는 곡. 같은 곡은 카탈로그 id로 가려낸다(표기가 달라도 같은 곡).
public struct ComposeTrack: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  public let artist: String

  public init(id: String, title: String, artist: String) {
    self.id = id
    self.title = title
    self.artist = artist
  }
}

public struct Track: Equatable, Sendable {
  public let title: String
  public let artist: String

  public init(title: String, artist: String) {
    self.title = title
    self.artist = artist
  }
}

public struct PlayerTrack: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  public let artist: String

  public init(id: String, title: String, artist: String) {
    self.id = id
    self.title = title
    self.artist = artist
  }
}
