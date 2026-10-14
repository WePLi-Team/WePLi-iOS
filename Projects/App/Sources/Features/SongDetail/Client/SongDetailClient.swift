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
  /// 원본 예시(밤편지). 원본 노트 03: 크레딧 · 발매 정보는 확인 필요한 예시 값
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
      related: [
        RelatedSong(title: "Blueming", artist: "아이유 (IU)"),
        RelatedSong(title: "관객이 될게 (I stan U)", artist: "아이유 (IU)"),
        RelatedSong(title: "팔레트 (Feat. G-DRAGON)", artist: "아이유 (IU)"),
        RelatedSong(title: "에잇(Prod. & Feat. SUGA of BTS)", artist: "아이유 (IU)"),
      ],
      otherAlbums: [
        OtherAlbum(title: "The Winning", subtitle: "2024 · 미니"),
        OtherAlbum(title: "Palette", subtitle: "2017 · 정규"),
        OtherAlbum(title: "에잇", subtitle: "2020 · 싱글"),
      ]
    )
  }
}
