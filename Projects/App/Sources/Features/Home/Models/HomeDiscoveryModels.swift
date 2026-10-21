import Foundation

// REQ-020 · UI-12a(DEC-008) — 홈 「발견 · 내 취향」 섹션

/// 오늘의 플리 — 매일 아침 위플리가 고른 곡
struct HomeTodayPick: Equatable, Identifiable, Sendable {
  /// 곡 id
  let id: String
  /// 「#아이유(IU)」
  let artistTag: String
  let title: String
}

struct HomeFavoriteArtist: Equatable, Sendable {
  let name: String
  /// 「#1번째 최애 가수」
  let rank: Int
}

/// Fa♥orite · 내가 좋아요한 곡
struct HomeFavorites: Equatable, Sendable {
  let totalCount: Int
  let songs: [HomeChartSong]
}

struct HomePopularPost: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  let body: String
  let author: String
  let likeCount: Int
  let commentCount: Int

  /// 「dlwlrma · 좋아요 10,123 · 댓글 923」
  var meta: String {
    "\(self.author) · 좋아요 \(HomeText.count(self.likeCount)) · 댓글 \(HomeText.count(self.commentCount))"
  }
}

struct HomePlaylistCard: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
}

struct HomeVideo: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  /// 「roykim ∙ #팝송 #캐롤 #플레이리스트」
  let channel: String
}

/// 시간대 추천 — 제목은 지금 시각(Asia/Seoul, DEC-004)에 따라 바뀐다
enum HomeTimeOfDay: Equatable {
  case dawn
  case morning
  case afternoon
  case evening
  case night

  init(hour: Int) {
    switch hour {
    case ..<5: self = .dawn
    case ..<10: self = .morning
    case ..<17: self = .afternoon
    case ..<21: self = .evening
    default: self = .night
    }
  }

  var title: String {
    switch self {
    case .dawn: "잠 안 오는 새벽에"
    case .morning: "출근길에 듣기 좋은"
    case .afternoon: "나른한 오후에"
    case .evening: "퇴근길에 듣기 좋은"
    case .night: "하루를 마무리하며"
    }
  }

  var period: String {
    switch self {
    case .dawn: "새벽"
    case .morning: "오전"
    case .afternoon: "오후"
    case .evening: "저녁"
    case .night: "밤"
    }
  }

  /// 「오후 3시 · 이 시간에 위플리에서 많이 들은 곡」 — 0시는 「새벽 12시」
  static func subtitle(hour: Int) -> String {
    let hour12 = hour % 12 == 0 ? 12 : hour % 12
    return "\(Self(hour: hour).period) \(hour12)시 · 이 시간에 위플리에서 많이 들은 곡"
  }

  static func hour(of date: Date) -> Int {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    return calendar.component(.hour, from: date)
  }
}
