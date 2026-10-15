import ComposableArchitecture
import Foundation

// REQ-079 · DEC-004 — 친구 피드. 백엔드가 정해지기 전까지 원본(UI-13b) 예시를 돌려주는 목업이다.

struct FriendFeedClient {
  var fetch: @Sendable () async throws -> FriendFeed
  /// 반응을 켜거나(이모지) 끈다(nil)
  var react: @Sendable (_ rowID: FriendListening.ID, _ reaction: FriendReaction?) async throws -> Void
  /// 같은 곡을 듣는 친구에게 🎧 반응 보내기
  var sendHeadphones: @Sendable (_ friendID: FriendListening.ID) async throws -> Void
  /// 미결정 — 연결된 음악 앱에서 곡 열기(어느 앱인지 · 곡이 없을 때)
  var openInMusicApp: @Sendable (_ title: String, _ artist: String) async -> Void
}

extension FriendFeedClient: DependencyKey {
  static let liveValue = FriendFeedClient(
    fetch: { .mock },
    react: { _, _ in },
    sendHeadphones: { _ in },
    openInMusicApp: { _, _ in }
  )

  static let previewValue = liveValue

  static let testValue = FriendFeedClient(
    fetch: unimplemented("FriendFeedClient.fetch", placeholder: .mock),
    react: unimplemented("FriendFeedClient.react"),
    sendHeadphones: unimplemented("FriendFeedClient.sendHeadphones"),
    openInMusicApp: unimplemented("FriendFeedClient.openInMusicApp")
  )
}

extension DependencyValues {
  var friendFeedClient: FriendFeedClient {
    get { self[FriendFeedClient.self] }
    set { self[FriendFeedClient.self] = newValue }
  }
}

extension FriendFeed {
  /// 원본(UI-13b) 예시
  static let mock = FriendFeed(
    rail: [
      FriendListening(id: "me", name: "나", isMe: true, title: "밤편지", artist: "아이유", isPlaying: true, timeText: "방금"),
      FriendListening(id: "jisoo", name: "지수", title: "밤편지", artist: "아이유", isPlaying: true, timeText: "방금"),
      FriendListening(id: "minsu", name: "민수", title: "Supernova", artist: "aespa", isPlaying: true, timeText: "방금"),
      FriendListening(
        id: "jongmin",
        name: "종민",
        title: "How Sweet",
        artist: "NewJeans",
        isPlaying: true,
        timeText: "3분 전"
      ),
      FriendListening(
        id: "subin",
        name: "수빈",
        title: "해야 (HEYA)",
        artist: "IVE (아이브)",
        isPlaying: false,
        timeText: "1시간 전"
      ),
    ],
    sameSong: FriendListening(id: "jisoo", name: "지수", title: "밤편지", artist: "아이유", isPlaying: true, timeText: "방금"),
    feed: [
      FriendListening(
        id: "minsu",
        name: "민수",
        title: "Supernova",
        artist: "aespa",
        isPlaying: true,
        timeText: "방금",
        reactions: [.fire: 3, .love: 1]
      ),
      FriendListening(
        id: "jongmin",
        name: "종민",
        title: "How Sweet",
        artist: "NewJeans",
        isPlaying: true,
        timeText: "3분 전",
        reactions: [.clap: 2]
      ),
      FriendListening(
        id: "subin",
        name: "수빈",
        title: "해야 (HEYA)",
        artist: "IVE (아이브)",
        isPlaying: false,
        timeText: "1시간 전"
      ),
    ],
    weekly: [
      FriendWeeklySong(title: "Supernova", artist: "aespa", friendCount: 7),
      FriendWeeklySong(title: "밤편지", artist: "아이유", friendCount: 5),
      FriendWeeklySong(title: "How Sweet", artist: "NewJeans", friendCount: 4),
    ]
  )
}
