import ComposableArchitecture
import Foundation

// REQ-079 · UI-13g · DEC-010 · DEC-020 · DEC-023 — 친구 프로필(B안). 팔로우 · 차단 · 일치율은 서버 값(DEC-004)

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

/// 프로필 위에 뜨는 창 — 한 번에 하나
enum FriendProfileOverlay: Hashable, Identifiable, Sendable {
  case menu
  case blockConfirm
  case report

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

  static let reportNotice = "서로 다른 5명이 신고하면 운영팀이 확인하기 전까지 임시로 가려져요. 신고한 사실은 상대에게 알리지 않아요."
  static let linkCopied = "프로필 링크를 복사했어요"
  static let blocked = "차단했어요"
  static let unblocked = "차단을 풀었어요 · 팔로우는 다시 해야 해요"
  static let reported = "신고를 접수했어요 · 결과는 알림으로 알려드려요"
  /// 원본에 없는 문구 — 디자인 확인 필요
  static let failed = "처리하지 못했어요. 다시 시도해 주세요"

  /// 「@jisu.wav」
  static func handle(_ handle: String) -> String {
    "@\(handle)"
  }

  /// 프로필 링크 — 미결정: 공유 링크 도메인(REQ-066과 같이 정함)
  static func link(_ profile: FriendProfile) -> URL? {
    URL(string: "https://wepli.example/u/\(profile.handle)")
  }
}
