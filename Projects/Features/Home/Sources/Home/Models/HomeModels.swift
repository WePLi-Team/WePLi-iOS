import Foundation
import WePLiSharedModels

// REQ-020 · UI-12a(DEC-008) — 통합 홈

/// 히어로 · 넘기는 대표 릴레이
public struct HomeHero: Equatable, Identifiable, Sendable {
  public enum Status: Equatable, Sendable {
    case live(endsAt: Date)
    case completed
  }

  /// 릴레이 id — 누르면 릴레이 상세
  public let id: String
  /// 「손님들이 물어보는\n카페 BGM」 — 줄바꿈 그대로
  public let title: String
  /// 「3,012명 참여」 · 「바통 릴레이 · 8명 중 4번째」
  public let people: String
  /// 「지금 1위」 · 「방금 이어진 곡」 · 「최종 1위」
  public let rankLabel: String
  public let song: String
  /// 「Dua Lipa · Album」
  public let songMeta: String
  public let status: Status
  /// 바통 릴레이 — 누르면 바통 화면(UI-8c)
  public var isBaton = false

  public var isCompleted: Bool {
    self.status == .completed
  }

  public init(
    id: String,
    title: String,
    people: String,
    rankLabel: String,
    song: String,
    songMeta: String,
    status: Status,
    isBaton: Bool = false
  ) {
    self.id = id
    self.title = title
    self.people = people
    self.rankLabel = rankLabel
    self.song = song
    self.songMeta = songMeta
    self.status = status
    self.isBaton = isBaton
  }
}

public struct HomeChartSong: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  public let artist: String

  public var track: ComposeTrack {
    ComposeTrack(id: self.id, title: self.title, artist: self.artist)
  }

  public init(id: String, title: String, artist: String) {
    self.id = id
    self.title = title
    self.artist = artist
  }
}

public struct HomeBanner: Equatable, Identifiable, Sendable {
  public let id: String
  /// 「오직 위플리에서만」
  public let eyebrow: String
  /// 「실시간 통합 순위를 한 눈에!」
  public let title: String

  public init(id: String, eyebrow: String, title: String) {
    self.id = id
    self.eyebrow = eyebrow
    self.title = title
  }
}

/// 홈 한 번에 받는 내용(서버 기준, DEC-004)
public struct HomeFeed: Equatable, Sendable {
  public var heroes: [HomeHero]
  /// 「6월 23일 오전 7시 업데이트」
  public var chartUpdatedText: String
  /// 위플리 TOP 100 — 홈에는 5곡
  public var chart: [HomeChartSong]
  public var banners: [HomeBanner]
  /// 알림 배지 — 읽지 않은 알림 수
  public var unreadNotifications: Int
  public var myRecommendations: [HomeMyRecommendation] = []
  public var votingRelays: [HomeVotingRelay] = []
  public var prediction: HomePrediction?
  public var friends: [HomeFriendListening] = []
  public var liveListening = HomeLiveListening(total: 0, songs: [])
  public var todayPicks: [HomeTodayPick] = []
  /// 시간대 추천 — 3줄씩 묶은 칸
  public var timeOfDayColumns: [[HomeChartSong]] = []
  public var favoriteArtist: HomeFavoriteArtist?
  public var favorites = HomeFavorites(totalCount: 0, songs: [])
  public var popularPosts: [HomePopularPost] = []
  public var popularArtists: [String] = []
  public var recommendedPlaylists: [HomePlaylistCard] = []
  public var themePlaylists: [HomePlaylistCard] = []
  public var videos: [HomeVideo] = []
  /// 참여 기록이 없는 새 사용자 — 내 추천곡 · 친구 · 최애 가수 · Fa♥orite 자리에 첫 참여 안내
  public var isNewUser = false

  public init(
    heroes: [HomeHero],
    chartUpdatedText: String,
    chart: [HomeChartSong],
    banners: [HomeBanner],
    unreadNotifications: Int,
    myRecommendations: [HomeMyRecommendation] = [],
    votingRelays: [HomeVotingRelay] = [],
    prediction: HomePrediction? = nil,
    friends: [HomeFriendListening] = [],
    liveListening: HomeLiveListening = HomeLiveListening(total: 0, songs: []),
    todayPicks: [HomeTodayPick] = [],
    timeOfDayColumns: [[HomeChartSong]] = [],
    favoriteArtist: HomeFavoriteArtist? = nil,
    favorites: HomeFavorites = HomeFavorites(totalCount: 0, songs: []),
    popularPosts: [HomePopularPost] = [],
    popularArtists: [String] = [],
    recommendedPlaylists: [HomePlaylistCard] = [],
    themePlaylists: [HomePlaylistCard] = [],
    videos: [HomeVideo] = [],
    isNewUser: Bool = false
  ) {
    self.heroes = heroes
    self.chartUpdatedText = chartUpdatedText
    self.chart = chart
    self.banners = banners
    self.unreadNotifications = unreadNotifications
    self.myRecommendations = myRecommendations
    self.votingRelays = votingRelays
    self.prediction = prediction
    self.friends = friends
    self.liveListening = liveListening
    self.todayPicks = todayPicks
    self.timeOfDayColumns = timeOfDayColumns
    self.favoriteArtist = favoriteArtist
    self.favorites = favorites
    self.popularPosts = popularPosts
    self.popularArtists = popularArtists
    self.recommendedPlaylists = recommendedPlaylists
    self.themePlaylists = themePlaylists
    self.videos = videos
    self.isNewUser = isNewUser
  }
}

public enum HomeCountdown {
  /// 히어로 「2일 04:12:33」 · 「09:16:50」 — 일은 0을 채우지 않는다(원본)
  public static func clock(from now: Date, to endsAt: Date) -> String {
    let seconds = max(0, Int(endsAt.timeIntervalSince(now)))
    let days = seconds / 86400
    let time = String(format: "%02d:%02d:%02d", seconds % 86400 / 3600, seconds % 3600 / 60, seconds % 60)
    return days > 0 ? "\(days)일 \(time)" : time
  }
}
