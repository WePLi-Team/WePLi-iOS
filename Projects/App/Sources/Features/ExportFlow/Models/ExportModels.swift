import Foundation

// REQ-050 · UI-14c–14k · UI-14o — 내 음악 앱으로 내보내기

enum ExportService: CaseIterable, Equatable, Sendable {
  case appleMusic
  case spotify
  case youtubeMusic
  /// 멜론 · 지니 · FLO 등 — 공개 연동이 없어 곡 목록을 복사한다(14o)
  case otherApps

  var name: String {
    switch self {
    case .appleMusic: "Apple Music"
    case .spotify: "Spotify"
    case .youtubeMusic: "YouTube Music"
    case .otherApps: "멜론 · 지니 · FLO 등"
    }
  }
}

/// 담을 곡(14d)
enum ExportSelection: CaseIterable, Equatable, Sendable {
  case all
  case top10
  case voted

  func title(total: Int, votedCount: Int) -> String {
    switch self {
    case .all: "전체 \(total)곡"
    case .top10: "TOP 10"
    case .voted: "내가 투표한 \(votedCount)곡"
    }
  }
}

struct ExportSong: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  let artist: String
  let recommender: String
  /// 내가 투표한 곡
  var isVoted = false
}

/// 곡 맞추기 결과(14h) — ISRC로 같은 음원을 찾고, 없으면 제목 · 가수로 다시 찾는다
enum ExportMatch: Equatable, Sendable {
  case found
  /// 다른 앨범에 실린 같은 곡 — 기본으로 담는다
  case otherVersion
  /// 같은 음원이 없음 — 비슷한 버전 중에서 고른다(14j)
  case needsCheck(alternatives: [ExportAlternative])
}

struct ExportAlternative: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  /// 「너드커넥션 · 라이브 앨범 · 4:31」
  let detail: String
}

/// 확인이 필요한 곡을 어떻게 할지(14j)
enum ExportResolution: Equatable, Sendable {
  case replace(ExportAlternative)
  case skip
}

/// 곡 목록 옮기기(14o) 형식
enum ExportListFormat: CaseIterable, Equatable, Sendable {
  case titleFirst
  case artistFirst

  var title: String {
    switch self {
    case .titleFirst: "제목 - 가수"
    case .artistFirst: "가수 - 제목"
    }
  }

  /// 「1. Supernova - aespa」
  func lines(_ songs: [ExportSong]) -> [String] {
    songs.enumerated().map { index, song in
      let pair = self == .titleFirst ? "\(song.title) - \(song.artist)" : "\(song.artist) - \(song.title)"
      return "\(index + 1). \(pair)"
    }
  }
}

enum ExportStep: Equatable, Sendable {
  case service
  case settings
  case appleMusicPermission
  case matching
  case review
  case done
  case copyList
}

/// 담기 설정 · 선택 요약 문구
enum ExportText {
  static let nameLimit = 40

  /// 미결정 — 공유 링크 도메인(BusinessCard · SongShare와 같은 임시 주소)
  static func relayLink(_ relayID: String) -> URL {
    URL(string: "https://wepli.example/relays/\(relayID)") ?? URL(fileURLWithPath: "/")
  }

  /// 「Supernova, How Sweet, Hype Boy 외 9곡」
  static func summary(_ songs: [ExportSong]) -> String {
    let head = songs.prefix(3).map(\.title).joined(separator: ", ")
    return songs.count > 3 ? "\(head) 외 \(songs.count - 3)곡" : head
  }
}
