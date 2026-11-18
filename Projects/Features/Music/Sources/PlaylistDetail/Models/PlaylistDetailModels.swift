import Foundation
import WePLiSharedModels

// REQ-025 · UI-3d

public struct PlaylistDetail: Equatable, Identifiable, Sendable {
  public struct Track: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let artist: String

    public init(id: String, title: String, artist: String) {
      self.id = id
      self.title = title
      self.artist = artist
    }
  }

  public struct Artist: Equatable, Identifiable, Sendable {
    public var id: String {
      self.name
    }

    public let name: String

    public init(name: String) {
      self.name = name
    }
  }

  public let id: String
  public let title: String
  public let curator: String
  /// 「2024.09.08」
  public let createdOn: String
  /// 서버가 알려 주는 전체 곡 수(목록은 앞부분만 올 수 있다)
  public let totalTrackCount: Int
  /// 「1시간 34분」
  public let durationText: String
  public let introduction: String
  public let artists: [Artist]
  public let tracks: [Track]
  public var isSaved: Bool

  /// 「2024.09.08 • 12곡 • 1시간 34분」
  public var info: String {
    "\(self.createdOn) • \(self.totalTrackCount)곡 • \(self.durationText)"
  }

  public init(
    id: String,
    title: String,
    curator: String,
    createdOn: String,
    totalTrackCount: Int,
    durationText: String,
    introduction: String,
    artists: [Artist],
    tracks: [Track],
    isSaved: Bool
  ) {
    self.id = id
    self.title = title
    self.curator = curator
    self.createdOn = createdOn
    self.totalTrackCount = totalTrackCount
    self.durationText = durationText
    self.introduction = introduction
    self.artists = artists
    self.tracks = tracks
    self.isSaved = isSaved
  }
}
