import Foundation

// MARK: - RelayList

struct RelayList: Equatable, Identifiable {
  let id: String
  let title: String
  let participantCount: Int
  let firstSong: Song?
  let backgroundImageURL: String?
  var remainingSeconds: Int

  var isCompleted: Bool {
    remainingSeconds <= 0
  }

  var remainingTimeText: String {
    guard remainingSeconds > 0 else { return "" }
    let days = remainingSeconds / 86400
    let hours = (remainingSeconds % 86400) / 3600
    let minutes = (remainingSeconds % 3600) / 60
    let seconds = remainingSeconds % 60
    return "\(days)일 \(hours)시간 \(minutes)분 \(seconds)초"
  }
}

// MARK: - Song

struct Song: Equatable, Identifiable {
  let id: String
  let title: String
  let artist: String
  let albumName: String?
  let releaseYear: String?
  let albumArtURL: String?
}

// MARK: - ChartSong

struct ChartSong: Equatable, Identifiable {
  let id: String
  let rank: Int
  let song: Song
}

// MARK: - Artist

struct Artist: Equatable, Identifiable {
  let id: String
  let name: String
  let profileImageURL: String?
}

// MARK: - Playlist

struct Playlist: Equatable, Identifiable {
  let id: String
  let title: String
  let coverImageURL: String?
}

// MARK: - YouTubeVideo

struct YouTubeVideo: Equatable, Identifiable {
  let id: String
  let title: String
  let channelName: String
  let thumbnailURL: String?
}

// MARK: - Banner

struct Banner: Equatable, Identifiable {
  let id: String
  let title: String
  let subtitle: String
  let imageURL: String?
  let actionURL: String?
}

// MARK: - MainData

struct MainData: Equatable {
  let relayLists: [RelayList]
  let chartSongs: [ChartSong]
  let popularArtists: [Artist]
  let recommendedPlaylists: [Playlist]
  let themedPlaylists: [Playlist]
  let youtubeVideos: [YouTubeVideo]
  let banners: [Banner]
  let chartUpdateTime: String
}
