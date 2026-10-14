import ComposableArchitecture
import Foundation

// REQ-077 — 백엔드가 정해지기 전까지 원본(UI-5c) 예시를 돌려주는 목업이다.

struct LibraryClient {
  var fetch: @Sendable () async throws -> Library
}

extension LibraryClient: DependencyKey {
  static let liveValue = LibraryClient(
    fetch: {
      @Dependency(\.date.now)
      var now
      return .mock(now: now)
    }
  )

  static let previewValue = LibraryClient(fetch: { .mock(now: Date()) })

  static let testValue = LibraryClient(fetch: unimplemented("LibraryClient.fetch", placeholder: .empty))
}

extension DependencyValues {
  var libraryClient: LibraryClient {
    get { self[LibraryClient.self] }
    set { self[LibraryClient.self] = newValue }
  }
}

extension Library {
  /// 원본 예시 — 진행 중 릴레이 마감은 지금부터 1시간 12분 34초 뒤(5e Live Activity와 같은 값)
  static func mock(now: Date) -> Library {
    Library(
      playlists: [
        LibraryPlaylist(id: "album", title: "내 앨범 (2024.05.03)", subtitle: "82곡"),
        LibraryPlaylist(id: "rainy", title: "비 오는 날 듣는 플리", subtitle: "3곡 · 게시글로 공유됨"),
      ],
      liveRelays: [
        LibraryLiveRelay(
          id: "cafe-bgm",
          title: "손님들이 물어보는 카페 BGM",
          endsAt: now.addingTimeInterval(3600 + 12 * 60 + 34),
          myRecommendations: "2곡 · 최고 4위",
          voteProgress: "4 / 10 진행"
        ),
      ],
      completedRelays: [
        LibraryCompletedRelay(id: "first-love", title: "첫 사랑이 생각나는 노래 모음", subtitle: "내 추천곡 ‘EASY’ 최종 3위"),
        LibraryCompletedRelay(id: "wake-up", title: "졸릴 때 잠 깨는 청량맛 노동요", subtitle: "내 추천곡 ‘Supernova’ 최종 1위"),
      ],
      likedSongs: [
        Track(title: "밤편지", artist: "아이유 (IU)"),
        Track(title: "Blueming", artist: "아이유 (IU)"),
        Track(title: "Perhaps Love (사랑인가요)", artist: "에릭남(Eric Nam)"),
      ],
      savedPosts: [
        LibrarySavedPost(id: "p4", title: "이것도 들어봐ㅏㅏㅏ", subtitle: "chuuuuu__ · 노래 1곡", author: "chuuuuu__"),
        LibrarySavedPost(id: "p1", title: "밤새면서 들을 수 있는 플리", subtitle: "dlwlrma · 플레이리스트 3곡", author: "dlwlrma"),
      ]
    )
  }
}
