import ComposableArchitecture
import Foundation

// REQ-023 · DEC-004 — 백엔드가 정해지기 전까지 원본(UI-2d) 예시를 돌려주는 목업이다.

struct SongDetailClient {
  var fetch: @Sendable (_ id: String) async throws -> SongDetail
  var setLiked: @Sendable (_ id: String, _ isLiked: Bool) async throws -> Void
}

extension SongDetailClient: DependencyKey {
  static let liveValue = SongDetailClient(
    fetch: { id in .mock(id: id) },
    setLiked: { _, _ in }
  )

  static let previewValue = liveValue

  static let testValue = SongDetailClient(
    fetch: unimplemented("SongDetailClient.fetch", placeholder: .mock(id: "")),
    setLiked: unimplemented("SongDetailClient.setLiked")
  )
}

extension DependencyValues {
  var songDetailClient: SongDetailClient {
    get { self[SongDetailClient.self] }
    set { self[SongDetailClient.self] = newValue }
  }
}

extension SongDetail {
  /// 원본 예시(밤편지, 2d v2). 원본 노트 03: 크레딧 · 발매 정보는 확인 필요한 예시 값
  static func mock(id: String) -> SongDetail {
    SongDetail(
      id: id,
      title: "밤편지",
      artist: "아이유 (IU)",
      lyricist: "아이유",
      composer: "제휘, 김희원",
      genres: ["발라드", "K-POP"],
      album: Album(title: "밤편지", artist: "아이유 (IU)", releaseDate: "2017.03.24", type: "싱글", year: 2017),
      likeCount: 10123,
      commentCount: 923,
      isLiked: false,
      relays: [
        Relay(id: "first-love", title: "첫 사랑이 생각나는 노래 모음", tags: "#첫사랑 #설렘", isLive: true, rank: 3, change: .up(1)),
        Relay(id: "rainy-night", title: "비 오는 밤 이어달리기", tags: "#비 #밤", isLive: true, rank: 2, change: .same),
        Relay(id: "before-sleep", title: "잠들기 전 듣는 노래", tags: "#새벽 #잔잔", isLive: false, rank: 1, change: .final),
      ],
      friendListeners: ["지수", "민지", "해린", "다니엘", "하니"],
      comments: [
        Comment(
          id: "c1",
          author: "minnie._.",
          time: "2시간 전",
          body: "비 오는 날 창문 열고 들으면 진짜 최고예요. 첫 소절부터 울컥해요",
          likeCount: 128
        ),
        Comment(id: "c2", author: "chuuuuu__", time: "2시간 전", body: "바통 릴레이 #밤 키워드에 이 곡 넣었어요ㅎㅎ", likeCount: 64),
      ],
      related: [
        RelatedSong(title: "Blueming", artist: "아이유 (IU)"),
        RelatedSong(title: "관객이 될게 (I stan U)", artist: "아이유 (IU)"),
        RelatedSong(title: "팔레트 (Feat. G-DRAGON)", artist: "아이유 (IU)"),
      ],
      otherAlbums: [
        OtherAlbum(title: "The Winning", subtitle: "2024 · 미니"),
        OtherAlbum(title: "Palette", subtitle: "2017 · 정규"),
        OtherAlbum(title: "에잇", subtitle: "2020 · 싱글"),
      ]
    )
  }
}
