import ComposableArchitecture
import Foundation

// REQ-025 · DEC-004 — 백엔드가 정해지기 전까지 원본(UI-3d) 예시를 돌려주는 목업이다.

struct PlaylistDetailClient {
  var fetch: @Sendable (_ id: String) async throws -> PlaylistDetail
  var setSaved: @Sendable (_ id: String, _ isSaved: Bool) async throws -> Void
}

extension PlaylistDetailClient: DependencyKey {
  static let liveValue = PlaylistDetailClient(
    fetch: { id in .mock(id: id) },
    setSaved: { _, _ in }
  )

  static let previewValue = liveValue

  static let testValue = PlaylistDetailClient(
    fetch: unimplemented("PlaylistDetailClient.fetch", placeholder: .mock(id: "")),
    setSaved: unimplemented("PlaylistDetailClient.setSaved")
  )
}

extension DependencyValues {
  var playlistDetailClient: PlaylistDetailClient {
    get { self[PlaylistDetailClient.self] }
    set { self[PlaylistDetailClient.self] = newValue }
  }
}

extension PlaylistDetail {
  /// 원본 예시 — 정보에는 12곡이지만 원본 목록은 6곡(앞부분만 온 것으로 본다)
  static func mock(id: String) -> PlaylistDetail {
    PlaylistDetail(
      id: id,
      title: "[Playlist] 졸릴 때 잠깨기 좋은 청량맛 노동요🧊🌊💙",
      curator: "WePLi",
      createdOn: "2024.09.08",
      totalTrackCount: 12,
      durationText: "1시간 34분",
      introduction: "나와 비슷한 취향을 가진 사람들이 올 한해 즐겨들었던 곡들을 모아봤어요. "
        + "다른 사람들은 어떤 노래를 듣는지 궁금할 때가 있잖아요. "
        + "특히 졸음이 몰려오는 오후, 머리를 맑게 깨워줄 청량한 곡들 위주로 골랐어요.",
      artists: [
        Artist(name: "BIGBANG (빅뱅)"),
        Artist(name: "윤하(Younha/ユンナ)"),
        Artist(name: "엔플라잉(N.Flying)"),
        Artist(name: "비투비"),
      ],
      tracks: [
        Track(id: "t1", title: "Shopper", artist: "아이유 (IU)"),
        Track(id: "t2", title: "Love is Lonely", artist: "NMIXX"),
        Track(id: "t3", title: "관객이 될게 (I stan U)", artist: "아이유 (IU)"),
        Track(id: "t4", title: "natural", artist: "Young K (DAY6)"),
        Track(id: "t5", title: "나의 X에게", artist: "경서"),
        Track(id: "t6", title: "에잇(Prod. & Feat. SUGA of BTS)", artist: "아이유 (IU)"),
      ],
      isSaved: false
    )
  }
}
