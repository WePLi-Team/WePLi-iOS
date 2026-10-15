import Foundation

// REQ-050 · UI-14c–14k · UI-14o — 내 음악 앱으로 내보내기

enum ExportService: CaseIterable, Equatable, Sendable {
  case appleMusic
  case spotify
  case youtubeMusic
  /// 멜론 · 지니 · FLO 등 — 공개 연동이 없어 곡 목록을 복사한다(14o)
  case otherApps

  /// 완성 플리의 「이미 담은 서비스」 이름에서
  init?(name: String) {
    guard let service = Self.allCases.first(where: { $0.name == name }) else { return nil }
    self = service
  }

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
  /// 14f — Apple Music 구독이 없을 때
  case subscriptionNeeded
  /// 14n — 끊김 · 연결 만료 · 이미 담은 플리
  case problem(ExportProblem)
}

/// 문제가 생겼을 때(14n)
enum ExportProblem: Equatable, Sendable {
  /// 인터넷 연결이 끊겨 멈춤
  case interrupted
  /// Spotify 연결 만료 — 다시 로그인하면 멈춘 곳부터 잇는다
  case expired
  /// 같은 릴레이를 이미 담았다
  case alreadyExported(ExportRecord)
}

/// 이미 담은 플리 — 서비스 · 플리 id · 담은 날 · 곡 수
struct ExportRecord: Equatable, Sendable {
  let service: ExportService
  let playlistID: String
  /// 「10월 12일」
  let exportedOn: String
  let songCount: Int
}

/// 다시 내보낼 때(14n 이미 담음)
enum ExportReExport: CaseIterable, Equatable, Sendable {
  case update
  case new

  var title: String {
    switch self {
    case .update: "기존 플리 업데이트"
    case .new: "새 플리로 하나 더 만들기"
    }
  }

  var detail: String {
    switch self {
    case .update: "최종 순위로 곡과 순서를 맞춰요"
    case .new: "기존 플리는 그대로 둬요"
    }
  }
}

/// 어디에 담을지
enum ExportTarget: Equatable, Sendable {
  case new(name: String)
  /// 멈춘 곳부터 이어 담기
  case append(playlistID: String)
  /// 최종 순위로 곡과 순서를 맞추기
  case replace(playlistID: String)
}

enum ExportError: Error, Equatable, Sendable {
  /// `added`곡까지 담고 연결이 끊겼다
  case interrupted(playlistID: String, added: Int)
  /// 연결이 만료됐다 — 플리를 만들기 전이면 id가 없다
  case expired(playlistID: String?, added: Int)
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

extension ExportFlowFeature.State {
  /// 완성 플리(UI-14b)에서 연다
  init(_ playlist: CompletedPlaylist) {
    // 미결정 — 담은 날 · 플리 id는 내보내기 기록(서버)이 필요하다. 지금은 완성일 · 릴레이 id로 둔다
    let exported = playlist.exportedTo.flatMap(ExportService.init(name:)).map {
      ExportRecord(
        service: $0,
        playlistID: playlist.id,
        exportedOn: playlist.completedOn,
        songCount: playlist.songCount
      )
    }
    self.init(
      relayID: playlist.id,
      title: playlist.title.replacingOccurrences(of: "\n", with: " "),
      recommenderCount: playlist.recommenderCount,
      // 미결정 — 완성 플리 응답에 내가 투표한 곡 정보가 없다(14d 「내가 투표한 n곡」)
      songs: playlist.ranking.map { ExportSong(
        id: $0.id,
        title: $0.title,
        artist: $0.artist,
        recommender: $0.recommender
      ) },
      exported: exported
    )
  }
}
