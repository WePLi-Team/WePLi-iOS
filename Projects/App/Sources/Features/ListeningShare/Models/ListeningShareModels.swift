import Foundation

// REQ-079 · UI-13a — 지금 듣는 음악: 연결과 공개 범위. 연결 · 범위는 서버에 저장한다(DEC-004)

/// 듣는 곡을 가져올 서비스 — iOS는 다른 앱의 재생 정보를 읽게 해주지 않아 서비스별 공식 연동을 쓴다(13 원문)
enum ListeningService: CaseIterable, Equatable, Hashable, Sendable {
  case appleMusic
  case spotify
  case lastFM

  var name: String {
    switch self {
    case .appleMusic: "Apple Music"
    case .spotify: "Spotify"
    case .lastFM: "Last.fm"
    }
  }

  var detail: String {
    switch self {
    case .appleMusic: "최근 재생 기록으로 · 몇 분 늦을 수 있어요"
    case .spotify: "지금 재생 중인 곡을 바로 가져와요"
    case .lastFM: "스크로블 기록으로 연결해요"
    }
  }
}

/// 누구에게 보여줄까요 — 기본은 친구, 전체 공개는 직접 골라야 켜진다
enum ListeningVisibility: CaseIterable, Equatable, Sendable {
  case onlyMe
  case friends
  case groups
  case everyone

  var title: String {
    switch self {
    case .onlyMe: "나만 보기"
    case .friends: "친구"
    case .groups: "특정 그룹"
    case .everyone: "전체 공개"
    }
  }

  var detail: String {
    switch self {
    case .onlyMe: "기록만 쌓이고 아무에게도 보이지 않아요"
    case .friends: "서로 팔로우한 친구에게만 보여요"
    case .groups: "고른 그룹의 멤버에게만 보여요"
    case .everyone: "이름 없이 ‘지금 위플리’ 집계에만 더해져요"
    }
  }
}

enum ListeningShareStep: Equatable, Sendable {
  case connect
  case visibility
  case done
}

struct ListeningShareSettings: Equatable, Sendable {
  var visibility: ListeningVisibility = .friends
  var groups: [String] = []
  /// 멈추면 30분 동안 「최근 들은 곡」으로
  var showsRecent = true
  /// 밤 12시–오전 7시에 들은 곡은 공유하지 않는다
  var hidesAtNight = false
}

enum ListeningShareText {
  /// 연결했어요 — 공개 범위별 설명
  static func done(_ settings: ListeningShareSettings, nickname: String) -> String {
    switch settings.visibility {
    case .onlyMe: "지금은 나만 볼 수 있어요. 기록은 계속 쌓여요."
    case .friends: "이제 친구들이 \(nickname)님이 듣는 음악을 볼 수 있어요."
    case .groups: "\(settings.groups.isEmpty ? "고른 그룹" : settings.groups.joined(separator: ", ")) 멤버들이 볼 수 있어요."
    case .everyone: "이름 없이 ‘지금 위플리’ 집계에 더해져요. 친구에게도 보여요."
    }
  }
}
