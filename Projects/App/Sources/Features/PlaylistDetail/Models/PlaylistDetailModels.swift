import Foundation

// REQ-025 · UI-3d

struct PlaylistDetail: Equatable, Identifiable, Sendable {
  struct Track: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let artist: String
  }

  struct Artist: Equatable, Identifiable, Sendable {
    var id: String {
      self.name
    }

    let name: String
  }

  let id: String
  let title: String
  let curator: String
  /// 「2024.09.08」
  let createdOn: String
  /// 서버가 알려 주는 전체 곡 수(목록은 앞부분만 올 수 있다)
  let totalTrackCount: Int
  /// 「1시간 34분」
  let durationText: String
  let introduction: String
  let artists: [Artist]
  let tracks: [Track]
  var isSaved: Bool

  /// 「2024.09.08 • 12곡 • 1시간 34분」
  var info: String {
    "\(self.createdOn) • \(self.totalTrackCount)곡 • \(self.durationText)"
  }
}
