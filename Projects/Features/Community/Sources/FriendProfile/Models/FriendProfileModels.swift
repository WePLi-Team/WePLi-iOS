import ComposableArchitecture
import Foundation

// REQ-079 · UI-13g · UI-17d · DEC-010 · DEC-020 · DEC-023 · DEC-029 — 친구 프로필(B안).
// 팔로우 · 차단 · 일치율 · 내가 한 신고는 서버 값(DEC-004)

public struct FriendProfile: Equatable, Sendable {
  /// 사용자 id — 커뮤니티 · 검색 · 홈에서 넘어오는 값
  public let id: String
  /// 「지수」
  public let name: String
  /// 「jisu.wav」
  public let handle: String
  public var followerCount: Int
  public let followingCount: Int
  public var isFollowing: Bool
  /// 상대가 나를 팔로우한다 — 취향 일치는 서로 팔로우일 때만 보인다(DEC-023)
  public let followsMe: Bool
  /// 지금 듣는 곡 — 듣지 않으면 nil(링 · 한 줄을 숨긴다)
  public let nowPlaying: FriendNowPlaying?
  public let bio: String
  /// 성향 배지 「메모리얼 멜로디」
  public let persona: String?
  /// 「나와 취향 82% 일치」 — 서버가 계산한다
  public let tasteMatch: Int?
  /// 초대할 릴레이 — 「비 오는 밤 이어달리기 · 5번째 주자」
  public let inviteRelay: FriendInviteRelay?
  public var posts: IdentifiedArrayOf<FriendPost>
  public let playlists: [FriendPlaylist]
  public let relays: [FriendRelay]
  public let recent: [FriendRecentTrack]
  /// 둘 다 자주 듣는 가수(최근 한 달)
  public let sharedArtists: [String]
  /// 내가 이 사람을 신고한 기록 — 같은 사람은 한 번만 신고한다(DEC-029)
  public var myReport: FriendReport?

  public var isMutual: Bool {
    self.isFollowing && self.followsMe
  }

  /// 서로 팔로우일 때만 일치율을 보인다
  public var visibleTasteMatch: Int? {
    self.isMutual ? self.tasteMatch : nil
  }

  public init(
    id: String,
    name: String,
    handle: String,
    followerCount: Int,
    followingCount: Int,
    isFollowing: Bool,
    followsMe: Bool,
    nowPlaying: FriendNowPlaying?,
    bio: String,
    persona: String?,
    tasteMatch: Int?,
    inviteRelay: FriendInviteRelay?,
    posts: IdentifiedArrayOf<FriendPost>,
    playlists: [FriendPlaylist],
    relays: [FriendRelay],
    recent: [FriendRecentTrack],
    sharedArtists: [String],
    myReport: FriendReport? = nil
  ) {
    self.id = id
    self.name = name
    self.handle = handle
    self.followerCount = followerCount
    self.followingCount = followingCount
    self.isFollowing = isFollowing
    self.followsMe = followsMe
    self.nowPlaying = nowPlaying
    self.bio = bio
    self.persona = persona
    self.tasteMatch = tasteMatch
    self.inviteRelay = inviteRelay
    self.posts = posts
    self.playlists = playlists
    self.relays = relays
    self.recent = recent
    self.sharedArtists = sharedArtists
    self.myReport = myReport
  }
}

public struct FriendNowPlaying: Equatable, Sendable {
  public let title: String
  public let artist: String
  /// 「방금」
  public let timeText: String

  public init(title: String, artist: String, timeText: String) {
    self.title = title
    self.artist = artist
    self.timeText = timeText
  }
}

public struct FriendInviteRelay: Equatable, Sendable {
  public let id: String
  public let title: String
  /// 내가 들어갈 순서
  public let order: Int

  public init(id: String, title: String, order: Int) {
    self.id = id
    self.title = title
    self.order = order
  }
}

public struct FriendPost: Equatable, Identifiable, Sendable {
  public let id: String
  public let text: String
  public let song: FriendNowPlaying?
  public var likeCount: Int
  public var isLiked: Bool
  public let commentCount: Int
  /// 「2일 전」
  public let timeText: String

  public init(
    id: String,
    text: String,
    song: FriendNowPlaying?,
    likeCount: Int,
    isLiked: Bool,
    commentCount: Int,
    timeText: String
  ) {
    self.id = id
    self.text = text
    self.song = song
    self.likeCount = likeCount
    self.isLiked = isLiked
    self.commentCount = commentCount
    self.timeText = timeText
  }
}

public struct FriendPlaylist: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  public let songCount: Int
  public let likeCount: Int

  public init(id: String, title: String, songCount: Int, likeCount: Int) {
    self.id = id
    self.title = title
    self.songCount = songCount
    self.likeCount = likeCount
  }
}

public struct FriendRelay: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  /// 「비의 랩소디 · 임재현」
  public let recommended: String
  /// 「진행 중 · 8명 중 4번째」 · 「최종 2위」
  public let result: String
  public let isLive: Bool

  public init(id: String, title: String, recommended: String, result: String, isLive: Bool) {
    self.id = id
    self.title = title
    self.recommended = recommended
    self.result = result
    self.isLive = isLive
  }
}

public struct FriendRecentTrack: Equatable, Identifiable, Sendable {
  public var id: String {
    "\(self.title)|\(self.artist)"
  }

  public let title: String
  public let artist: String
  /// 「25분 전」
  public let timeText: String

  public init(title: String, artist: String, timeText: String) {
    self.title = title
    self.artist = artist
    self.timeText = timeText
  }
}

public enum FriendProfileTab: CaseIterable, Equatable, Sendable {
  case posts
  case playlists
  case relays
  case listened

  public var title: String {
    switch self {
    case .posts: "게시글"
    case .playlists: "플레이리스트"
    case .relays: "릴레이"
    case .listened: "들은 음악"
    }
  }
}

/// 신고 사유 — 7차와 같은 5개(DEC-020)
public enum ReportReason: CaseIterable, Equatable, Sendable {
  case abuse
  case sexual
  case spam
  case impersonation
  case other

  public var title: String {
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
public struct FriendReport: Equatable, Sendable {
  public let date: Date
  public let reason: ReportReason
  public let status: ReportStatus

  public init(date: Date, reason: ReportReason, status: ReportStatus) {
    self.date = date
    self.reason = reason
    self.status = status
  }
}

/// 신고 진행 상태 — 결과는 알림과 내 문의 내역으로 온다
public enum ReportStatus: Equatable, Sendable {
  case reviewing
  case resolved

  public var title: String {
    switch self {
    case .reviewing: "운영팀 검토 중"
    // 원본에 없는 문구 — 17a 「결과 안내」와 맞춤
    case .resolved: "결과 안내"
    }
  }
}

/// 프로필 위에 뜨는 창 — 한 번에 하나
public enum FriendProfileOverlay: Hashable, Identifiable, Sendable {
  case menu
  case blockConfirm
  case report
  /// 「신고를 접수했어요」
  case reportDone
  /// 「이미 신고했어요」
  case reportExisting

  public var id: Self {
    self
  }
}

public enum FriendProfileText {
  public static func blockTitle(_ name: String) -> String {
    "\(name) 님을 차단할까요?"
  }

  /// 차단하면 바뀌는 것 3줄(원본 그대로)
  public static let blockLines = [
    "서로 팔로우가 끊기고, 프로필과 지금 듣는 중이 서로 보이지 않아요.",
    "같은 릴레이에 추천한 곡은 순위에 그대로 남고, 추천한 사람 이름만 가려져요.",
    "상대에게는 알리지 않아요. 설정 › 차단한 사용자에서 풀 수 있어요.",
  ]

  public static func blockedDetail(_ name: String) -> String {
    "\(name) 님의 프로필과 지금 듣는 중이 보이지 않아요"
  }

  public static func reportSubtitle(_ name: String) -> String {
    "\(name) 님을 신고하는 이유를 골라주세요"
  }

  public static let reportNotice = "신고한 사실은 상대에게 알리지 않아요. 같은 사람은 한 번만 신고할 수 있어요."
  public static let reportDetailPlaceholder = "어떤 점이 문제인지 적어주세요 (필수)"
  /// 「기타」 사유는 200자까지
  public static let reportDetailLimit = 200
  public static let reportDoneTitle = "신고를 접수했어요"
  public static let reportDoneDetail = "운영팀이 확인한 뒤 결과를 알림과\n내 문의 내역으로 알려드려요"
  public static let reportExistingTitle = "이미 신고했어요"
  public static let reportExistingDetail = "같은 사람은 한 번만 신고할 수 있어요. 결과가 나오면 알려드릴게요."

  public static func reportBlock(_ name: String) -> String {
    "\(name) 님 차단하기"
  }

  /// 「10월 19일」 — Asia/Seoul(DEC-004)
  public static func reportDate(_ date: Date) -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    let parts = calendar.dateComponents([.month, .day], from: date)
    return "\(parts.month ?? 0)월 \(parts.day ?? 0)일"
  }

  public static let linkCopied = "프로필 링크를 복사했어요"
  public static let blocked = "차단했어요"
  public static let unblocked = "차단을 풀었어요 · 팔로우는 다시 해야 해요"
  /// 원본에 없는 문구 — 디자인 확인 필요
  public static let failed = "처리하지 못했어요. 다시 시도해 주세요"

  /// 「@jisu.wav」
  public static func handle(_ handle: String) -> String {
    "@\(handle)"
  }

  /// 프로필 링크 — 원본 임시 주소 wepli.app/@아이디. 실제 주소는 미결정
  public static func link(_ profile: FriendProfile) -> URL? {
    URL(string: "https://wepli.app/@\(profile.handle)")
  }
}
