import ComposableArchitecture
import Foundation

// REQ-061 · REQ-062 — 백엔드 · 음원 카탈로그가 정해지기 전까지 원본(UI-2a · 2b) 예시로 동작하는 목업이다.

struct ComposeClient {
  /// 곡 검색 — 제목 · 가수 부분 일치(대소문자 무시)
  var searchTracks: @Sendable (_ query: String) async throws -> [ComposeTrack]
  var recentSearches: @Sendable () -> [String]
  var trendingSearches: @Sendable () -> [String]
  var publish: @Sendable (_ draft: PostDraft) async throws -> Void
}

extension ComposeClient: DependencyKey {
  static let liveValue = ComposeClient(
    searchTracks: { query in
      let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      guard !needle.isEmpty else { return [] }
      return ComposeTrack.catalog.filter { "\($0.title) \($0.artist)".lowercased().contains(needle) }
    },
    recentSearches: { ["로이킴", "아이유", "데이식스"] },
    trendingSearches: {
      ["눈물의 여왕 OST", "데이식스", "블랙핑크", "아이유", "선재 업고 튀어 OST", "아일릿", "베이비몬스터", "크러쉬", "아이브"]
    },
    publish: { _ in }
  )

  static let previewValue = liveValue

  static let testValue = ComposeClient(
    searchTracks: unimplemented("ComposeClient.searchTracks", placeholder: []),
    recentSearches: unimplemented("ComposeClient.recentSearches", placeholder: []),
    trendingSearches: unimplemented("ComposeClient.trendingSearches", placeholder: []),
    publish: unimplemented("ComposeClient.publish")
  )
}

extension DependencyValues {
  var composeClient: ComposeClient {
    get { self[ComposeClient.self] }
    set { self[ComposeClient.self] = newValue }
  }
}

extension ComposeTrack {
  /// 원본(UI-2a) 검색 대상 14곡
  static let catalog: [ComposeTrack] = [
    ComposeTrack(id: "c1", title: "관객이 될게 (I stan U)", artist: "아이유 (IU)"),
    ComposeTrack(id: "c2", title: "밤편지", artist: "아이유 (IU)"),
    ComposeTrack(id: "c3", title: "Blueming", artist: "아이유 (IU)"),
    ComposeTrack(id: "c4", title: "팔레트 (Feat. G-DRAGON)", artist: "아이유 (IU)"),
    ComposeTrack(id: "c5", title: "에잇(Prod. & Feat. SUGA of BTS)", artist: "아이유 (IU)"),
    ComposeTrack(id: "c6", title: "비가 내리는 날에는", artist: "윤하 (Younha)"),
    ComposeTrack(id: "c7", title: "우리의 밤은 당신보다...", artist: "츄(CHUU)"),
    ComposeTrack(id: "c8", title: "Diamond", artist: "로시(Rothy)"),
    ComposeTrack(id: "c9", title: "해야 (HEYA)", artist: "IVE (아이브)"),
    ComposeTrack(id: "c10", title: "Supernova", artist: "aespa"),
    ComposeTrack(id: "c11", title: "How Sweet", artist: "NewJeans"),
    ComposeTrack(id: "c12", title: "Hype Boy", artist: "NewJeans"),
    ComposeTrack(id: "c13", title: "밤양갱", artist: "비비(bibi)"),
    ComposeTrack(id: "c14", title: "EASY", artist: "LE SSERAFIM (르세라핌)"),
  ]
}
