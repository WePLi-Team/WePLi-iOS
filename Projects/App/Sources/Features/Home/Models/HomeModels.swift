import Foundation

// REQ-020 · UI-12a(DEC-008) — 통합 홈

/// 히어로 · 넘기는 대표 릴레이
struct HomeHero: Equatable, Identifiable, Sendable {
  enum Status: Equatable, Sendable {
    case live(endsAt: Date)
    case completed
  }

  /// 릴레이 id — 누르면 릴레이 상세
  let id: String
  /// 「손님들이 물어보는\n카페 BGM」 — 줄바꿈 그대로
  let title: String
  /// 「3,012명 참여」 · 「바통 릴레이 · 8명 중 4번째」
  let people: String
  /// 「지금 1위」 · 「방금 이어진 곡」 · 「최종 1위」
  let rankLabel: String
  let song: String
  /// 「Dua Lipa · Album」
  let songMeta: String
  let status: Status

  var isCompleted: Bool {
    self.status == .completed
  }
}

struct HomeChartSong: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  let artist: String

  var track: ComposeTrack {
    ComposeTrack(id: self.id, title: self.title, artist: self.artist)
  }
}

struct HomeBanner: Equatable, Identifiable, Sendable {
  let id: String
  /// 「오직 위플리에서만」
  let eyebrow: String
  /// 「실시간 통합 순위를 한 눈에!」
  let title: String
}

/// 홈 한 번에 받는 내용(서버 기준, DEC-004)
struct HomeFeed: Equatable, Sendable {
  var heroes: [HomeHero]
  /// 「6월 23일 오전 7시 업데이트」
  var chartUpdatedText: String
  /// 위플리 TOP 100 — 홈에는 5곡
  var chart: [HomeChartSong]
  var banners: [HomeBanner]
  /// 알림 배지 — 읽지 않은 알림 수
  var unreadNotifications: Int
  var myRecommendations: [HomeMyRecommendation] = []
  var votingRelays: [HomeVotingRelay] = []
  var prediction: HomePrediction?
  var friends: [HomeFriendListening] = []
  var liveListening = HomeLiveListening(total: 0, songs: [])
  var todayPicks: [HomeTodayPick] = []
  /// 시간대 추천 — 3줄씩 묶은 칸
  var timeOfDayColumns: [[HomeChartSong]] = []
  var favoriteArtist: HomeFavoriteArtist?
  var favorites = HomeFavorites(totalCount: 0, songs: [])
  var popularPosts: [HomePopularPost] = []
  var popularArtists: [String] = []
  var recommendedPlaylists: [HomePlaylistCard] = []
  var themePlaylists: [HomePlaylistCard] = []
  var videos: [HomeVideo] = []
  /// 참여 기록이 없는 새 사용자 — 내 추천곡 · 친구 · 최애 가수 · Fa♥orite 자리에 첫 참여 안내
  var isNewUser = false
}

enum HomeCountdown {
  /// 히어로 「2일 04:12:33」 · 「09:16:50」 — 일은 0을 채우지 않는다(원본)
  static func clock(from now: Date, to endsAt: Date) -> String {
    let seconds = max(0, Int(endsAt.timeIntervalSince(now)))
    let days = seconds / 86400
    let time = String(format: "%02d:%02d:%02d", seconds % 86400 / 3600, seconds % 3600 / 60, seconds % 60)
    return days > 0 ? "\(days)일 \(time)" : time
  }
}
