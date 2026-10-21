import ComposableArchitecture
import Foundation

// REQ-079 · UI-13g · UI-17d · DEC-010 · DEC-020 · DEC-023 · DEC-029 — 친구 프로필(B안).
// 팔로우 · 차단 · 일치율 · 내가 한 신고는 서버 값(DEC-004)

struct FriendProfile: Equatable, Sendable {
  /// 사용자 id — 커뮤니티 · 검색 · 홈에서 넘어오는 값
  let id: String
  /// 「지수」
  let name: String
  /// 「jisu.wav」
  let handle: String
  var followerCount: Int
  let followingCount: Int
  var isFollowing: Bool
  /// 상대가 나를 팔로우한다 — 취향 일치는 서로 팔로우일 때만 보인다(DEC-023)
  let followsMe: Bool
  /// 지금 듣는 곡 — 듣지 않으면 nil(링 · 한 줄을 숨긴다)
  let nowPlaying: FriendNowPlaying?
  let bio: String
  /// 성향 배지 「메모리얼 멜로디」
  let persona: String?
  /// 「나와 취향 82% 일치」 — 서버가 계산한다
  let tasteMatch: Int?
  /// 초대할 릴레이 — 「비 오는 밤 이어달리기 · 5번째 주자」
  let inviteRelay: FriendInviteRelay?
  var posts: IdentifiedArrayOf<FriendPost>
  let playlists: [FriendPlaylist]
  let relays: [FriendRelay]
  let recent: [FriendRecentTrack]
  /// 둘 다 자주 듣는 가수(최근 한 달)
  let sharedArtists: [String]
  /// 내가 이 사람을 신고한 기록 — 같은 사람은 한 번만 신고한다(DEC-029)
  var myReport: FriendReport?

  var isMutual: Bool {
    self.isFollowing && self.followsMe
  }

  /// 서로 팔로우일 때만 일치율을 보인다
  var visibleTasteMatch: Int? {
    self.isMutual ? self.tasteMatch : nil
  }
}

struct FriendNowPlaying: Equatable, Sendable {
  let title: String
  let artist: String
  /// 「방금」
  let timeText: String
}

struct FriendInviteRelay: Equatable, Sendable {
  let id: String
  let title: String
  /// 내가 들어갈 순서
  let order: Int
}

struct FriendPost: Equatable, Identifiable, Sendable {
  let id: String
  let text: String
  let song: FriendNowPlaying?
  var likeCount: Int
  var isLiked: Bool
  let commentCount: Int
  /// 「2일 전」
  let timeText: String
}

struct FriendPlaylist: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  let songCount: Int
  let likeCount: Int
}

struct FriendRelay: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  /// 「비의 랩소디 · 임재현」
  let recommended: String
  /// 「진행 중 · 8명 중 4번째」 · 「최종 2위」
  let result: String
  let isLive: Bool
}

struct FriendRecentTrack: Equatable, Identifiable, Sendable {
  var id: String {
    "\(self.title)|\(self.artist)"
  }

  let title: String
  let artist: String
  /// 「25분 전」
  let timeText: String
}

enum FriendProfileTab: CaseIterable, Equatable, Sendable {
  case posts
  case playlists
  case relays
  case listened

  var title: String {
    switch self {
    case .posts: "게시글"
    case .playlists: "플레이리스트"
    case .relays: "릴레이"
    case .listened: "들은 음악"
    }
  }
}

/// 신고 사유 — 7차와 같은 5개(DEC-020)
enum ReportReason: CaseIterable, Equatable, Sendable {
  case abuse
  case sexual
  case spam
  case impersonation
  case other

  var title: String {
    switch self {
    case .abuse: "욕설 · 비하"
    case .sexual: "음란물"
    case .spam: "스팸 · 홍보"
    case .impersonation: "사칭"
    case .other: "기타"
    }
  }
}

/// 내가 한 신고 — 「이미 신고했어요」에 신고한 날 · 사유 · 진행 상태로 보인다
struct FriendReport: Equatable, Sendable {
  let date: Date
  let reason: ReportReason
  let status: ReportStatus
}

/// 신고 진행 상태 — 결과는 알림과 내 문의 내역으로 온다
enum ReportStatus: Equatable, Sendable {
  case reviewing
  case resolved

  var title: String {
    switch self {
    case .reviewing: "운영팀 검토 중"
    // 원본에 없는 문구 — 17a 「결과 안내」와 맞춤
    case .resolved: "결과 안내"
    }
  }
}

/// 프로필 위에 뜨는 창 — 한 번에 하나
enum FriendProfileOverlay: Hashable, Identifiable, Sendable {
  case menu
  case blockConfirm
  case report
  /// 「신고를 접수했어요」
  case reportDone
  /// 「이미 신고했어요」
  case reportExisting

  var id: Self {
    self
  }
}

enum FriendProfileText {
  static func blockTitle(_ name: String) -> String {
    "\(name) 님을 차단할까요?"
  }

  /// 차단하면 바뀌는 것 3줄(원본 그대로)
  static let blockLines = [
    "서로 팔로우가 끊기고, 프로필과 지금 듣는 중이 서로 보이지 않아요.",
    "같은 릴레이에 추천한 곡은 순위에 그대로 남고, 추천한 사람 이름만 가려져요.",
    "상대에게는 알리지 않아요. 설정 › 차단한 사용자에서 풀 수 있어요.",
  ]

  static func blockedDetail(_ name: String) -> String {
    "\(name) 님의 프로필과 지금 듣는 중이 보이지 않아요"
  }

  static func reportSubtitle(_ name: String) -> String {
    "\(name) 님을 신고하는 이유를 골라주세요"
  }

  static let reportNotice = "신고한 사실은 상대에게 알리지 않아요. 같은 사람은 한 번만 신고할 수 있어요."
  static let reportDetailPlaceholder = "어떤 점이 문제인지 적어주세요 (필수)"
  /// 「기타」 사유는 200자까지
  static let reportDetailLimit = 200
  static let reportDoneTitle = "신고를 접수했어요"
  static let reportDoneDetail = "운영팀이 확인한 뒤 결과를 알림과\n내 문의 내역으로 알려드려요"
  static let reportExistingTitle = "이미 신고했어요"
  static let reportExistingDetail = "같은 사람은 한 번만 신고할 수 있어요. 결과가 나오면 알려드릴게요."

  static func reportBlock(_ name: String) -> String {
    "\(name) 님 차단하기"
  }

  /// 「10월 19일」 — Asia/Seoul(DEC-004)
  static func reportDate(_ date: Date) -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    let parts = calendar.dateComponents([.month, .day], from: date)
    return "\(parts.month ?? 0)월 \(parts.day ?? 0)일"
  }

  static let linkCopied = "프로필 링크를 복사했어요"
  static let blocked = "차단했어요"
  static let unblocked = "차단을 풀었어요 · 팔로우는 다시 해야 해요"
  /// 원본에 없는 문구 — 디자인 확인 필요
  static let failed = "처리하지 못했어요. 다시 시도해 주세요"

  /// 「@jisu.wav」
  static func handle(_ handle: String) -> String {
    "@\(handle)"
  }

  /// 프로필 링크 — 원본 임시 주소 wepli.app/@아이디. 실제 주소는 미결정
  static func link(_ profile: FriendProfile) -> URL? {
    URL(string: "https://wepli.app/@\(profile.handle)")
  }
}
