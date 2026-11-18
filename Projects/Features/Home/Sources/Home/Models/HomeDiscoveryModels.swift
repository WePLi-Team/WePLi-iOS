import Foundation

// REQ-020 · UI-12a(DEC-008) — 홈 「발견 · 내 취향」 섹션

/// 오늘의 플리 — 매일 아침 위플리가 고른 곡
public struct HomeTodayPick: Equatable, Identifiable, Sendable {
  /// 곡 id
  public let id: String
  /// 「#아이유(IU)」
  public let artistTag: String
  public let title: String

  public init(id: String, artistTag: String, title: String) {
    self.id = id
    self.artistTag = artistTag
    self.title = title
  }
}

public struct HomeFavoriteArtist: Equatable, Sendable {
  public let name: String
  /// 「#1번째 최애 가수」
  public let rank: Int

  public init(name: String, rank: Int) {
    self.name = name
    self.rank = rank
  }
}

/// Fa♥orite · 내가 좋아요한 곡
public struct HomeFavorites: Equatable, Sendable {
  public let totalCount: Int
  public let songs: [HomeChartSong]

  public init(totalCount: Int, songs: [HomeChartSong]) {
    self.totalCount = totalCount
    self.songs = songs
  }
}

public struct HomePopularPost: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  public let body: String
  public let author: String
  public let likeCount: Int
  public let commentCount: Int

  /// 「dlwlrma · 좋아요 10,123 · 댓글 923」
  public var meta: String {
    "\(self.author) · 좋아요 \(HomeText.count(self.likeCount)) · 댓글 \(HomeText.count(self.commentCount))"
  }

  public init(id: String, title: String, body: String, author: String, likeCount: Int, commentCount: Int) {
    self.id = id
    self.title = title
    self.body = body
    self.author = author
    self.likeCount = likeCount
    self.commentCount = commentCount
  }
}

public struct HomePlaylistCard: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String

  public init(id: String, title: String) {
    self.id = id
    self.title = title
  }
}

public struct HomeVideo: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  /// 「roykim ∙ #팝송 #캐롤 #플레이리스트」
  public let channel: String

  public init(id: String, title: String, channel: String) {
    self.id = id
    self.title = title
    self.channel = channel
  }
}

/// 시간대 추천 — 제목은 지금 시각(Asia/Seoul, DEC-004)에 따라 바뀐다
public enum HomeTimeOfDay: Equatable {
  case dawn
  case morning
  case afternoon
  case evening
  case night

  public init(hour: Int) {
    switch hour {
    case ..<5: self = .dawn
    case ..<10: self = .morning
    case ..<17: self = .afternoon
    case ..<21: self = .evening
    default: self = .night
    }
  }

  public var title: String {
    switch self {
    case .dawn: "잠 안 오는 새벽에"
    case .morning: "출근길에 듣기 좋은"
    case .afternoon: "나른한 오후에"
    case .evening: "퇴근길에 듣기 좋은"
    case .night: "하루를 마무리하며"
    }
  }

  public var period: String {
    switch self {
    case .dawn: "새벽"
    case .morning: "오전"
    case .afternoon: "오후"
    case .evening: "저녁"
    case .night: "밤"
    }
  }

  /// 「오후 3시 · 이 시간에 위플리에서 많이 들은 곡」 — 0시는 「새벽 12시」
  public static func subtitle(hour: Int) -> String {
    let hour12 = hour % 12 == 0 ? 12 : hour % 12
    return "\(Self(hour: hour).period) \(hour12)시 · 이 시간에 위플리에서 많이 들은 곡"
  }

  public static func hour(of date: Date) -> Int {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    return calendar.component(.hour, from: date)
  }
}
