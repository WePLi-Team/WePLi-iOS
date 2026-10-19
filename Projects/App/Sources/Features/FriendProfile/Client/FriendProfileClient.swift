import ComposableArchitecture
import Foundation
import UIKit

// REQ-079 · DEC-004 · DEC-020 — 친구 프로필. 백엔드가 정해지기 전까지 원본(UI-13g) 예시를 돌려주는 목업이다.
// 차단 · 신고는 서버가 처리한다(서로 팔로우 해제 · 서로 비공개 · 5명 신고 시 임시 가림). 사용자 정보는 로그에 남기지 않는다.

struct FriendProfileClient {
  var fetch: @Sendable (_ userID: String) async throws -> FriendProfile
  var setFollowing: @Sendable (_ userID: String, _ isOn: Bool) async throws -> Void
  /// 차단하면 서버가 서로 팔로우를 끊는다
  var setBlocked: @Sendable (_ userID: String, _ isOn: Bool) async throws -> Void
  var report: @Sendable (_ userID: String, _ reason: ReportReason) async throws -> Void
  var invite: @Sendable (_ userID: String, _ relayID: String) async throws -> Void
  var likePost: @Sendable (_ postID: String, _ isOn: Bool) async throws -> Void
  /// 지금 듣는 곡을 내 플리에 담기
  var saveSong: @Sendable (_ title: String, _ artist: String) async throws -> Void
  var copyLink: @Sendable (_ url: URL) async -> Void
}

extension FriendProfileClient: DependencyKey {
  static let liveValue = FriendProfileClient(
    fetch: { userID in .mock(id: userID) },
    setFollowing: { _, _ in },
    setBlocked: { _, _ in },
    report: { _, _ in },
    invite: { _, _ in },
    likePost: { _, _ in },
    saveSong: { _, _ in },
    copyLink: { url in await MainActor.run { UIPasteboard.general.url = url } }
  )

  static let previewValue = liveValue

  static let testValue = FriendProfileClient(
    fetch: unimplemented("FriendProfileClient.fetch", placeholder: .mock(id: "jisoo")),
    setFollowing: unimplemented("FriendProfileClient.setFollowing"),
    setBlocked: unimplemented("FriendProfileClient.setBlocked"),
    report: unimplemented("FriendProfileClient.report"),
    invite: unimplemented("FriendProfileClient.invite"),
    likePost: unimplemented("FriendProfileClient.likePost"),
    saveSong: unimplemented("FriendProfileClient.saveSong"),
    copyLink: unimplemented("FriendProfileClient.copyLink")
  )
}

extension DependencyValues {
  var friendProfileClient: FriendProfileClient {
    get { self[FriendProfileClient.self] }
    set { self[FriendProfileClient.self] = newValue }
  }
}

extension FriendProfile {
  /// 원본(UI-13g) 예시 — 누구를 열든 같은 내용이다(목업)
  static func mock(id: String) -> FriendProfile {
    FriendProfile(
      id: id,
      name: "지수",
      handle: "jisu.wav",
      followerCount: 128,
      followingCount: 96,
      isFollowing: true,
      followsMe: true,
      nowPlaying: FriendNowPlaying(title: "밤편지", artist: "아이유", timeText: "방금"),
      bio: "비 오는 날엔 너드커넥션, 맑은 날엔 아이유",
      persona: "메모리얼 멜로디",
      tasteMatch: 82,
      inviteRelay: FriendInviteRelay(id: "rainy-night", title: "비 오는 밤 이어달리기", order: 5),
      posts: IdentifiedArray(uniqueElements: mockPosts),
      playlists: [
        FriendPlaylist(id: "analog-mood", title: "노을처럼 번지는 아날로그 무드", songCount: 18, likeCount: 64),
        FriendPlaylist(id: "early-summer", title: "초여름 청량한 케이팝 댄스", songCount: 24, likeCount: 31),
        FriendPlaylist(id: "warm-voice", title: "추위를 녹이는 음색의 보이스", songCount: 12, likeCount: 22),
        FriendPlaylist(id: "fresh-kpop", title: "뼛속까지 청량해지는 K-pop", songCount: 20, likeCount: 17),
      ],
      relays: mockRelays,
      recent: [
        FriendRecentTrack(title: "그대만 있다면 (여름날 우리 X 너드커넥션)", artist: "너드커넥션", timeText: "25분 전"),
        FriendRecentTrack(title: "어른", artist: "Sondia", timeText: "1시간 전"),
        FriendRecentTrack(title: "How Sweet", artist: "NewJeans", timeText: "어제"),
        FriendRecentTrack(title: "비의 랩소디", artist: "임재현", timeText: "어제"),
      ],
      sharedArtists: ["아이유", "윤하(Younha/ユンナ)", "로이킴", "엔플라잉(N.Flying)"]
    )
  }

  private static let mockPosts = [
    FriendPost(
      id: "jisu-1",
      text: "비 오는 날 퇴근길에 이거 들으면 버스 창문이 뮤직비디오가 돼요. 너드커넥션 라이브 버전 꼭 들어보세요",
      song: FriendNowPlaying(title: "그대만 있다면 (여름날 우리 X 너드커넥션)", artist: "너드커넥션(Nerd Connection)", timeText: ""),
      likeCount: 42,
      isLiked: false,
      commentCount: 7,
      timeText: "2일 전"
    ),
    FriendPost(
      id: "jisu-2",
      text: "‘비 오는 밤 이어달리기’ 바통 받았어요. 다음 키워드 #바다 로 넘깁니다. 다음 분 부담 갖지 마시고요 🌊",
      song: nil,
      likeCount: 18,
      isLiked: false,
      commentCount: 3,
      timeText: "4일 전"
    ),
    FriendPost(
      id: "jisu-3",
      text: "밤편지는 가사 첫 줄부터 반칙이에요",
      song: FriendNowPlaying(title: "밤편지", artist: "아이유(IU)", timeText: ""),
      likeCount: 96,
      isLiked: false,
      commentCount: 12,
      timeText: "1주 전"
    ),
  ]

  private static let mockRelays = [
    FriendRelay(
      id: "rainy-night",
      title: "비 오는 밤 이어달리기",
      recommended: "비의 랩소디 · 임재현",
      result: "진행 중 · 8명 중 4번째",
      isLive: true
    ),
    FriendRelay(id: "first-love", title: "첫 사랑이 생각나는 노래 모음", recommended: "밤편지 · 아이유", result: "최종 2위", isLive: false),
    FriendRelay(
      id: "summer-work",
      title: "졸릴 때 잠 깨는 청량맛 노동요",
      recommended: "How Sweet · NewJeans",
      result: "최종 5위",
      isLive: false
    ),
  ]
}
