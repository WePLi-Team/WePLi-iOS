import ComposableArchitecture
import Foundation

// REQ-080 — 백엔드가 정해지기 전까지 원본(UI-4c) 예시 데이터 안에서 찾는다.

struct SearchClient {
  var search: @Sendable (_ query: String, _ scope: SearchScope) async throws -> SearchResults
  var recentQueries: @Sendable () -> [String]
}

extension SearchClient: DependencyKey {
  static let liveValue = SearchClient(
    search: { query, scope in SearchEngine.search(query, scope: scope, in: .mock) },
    recentQueries: { ["로이킴", "비 오는 날", "아이유"] }
  )

  static let previewValue = liveValue

  static let testValue = SearchClient(
    search: unimplemented("SearchClient.search", placeholder: SearchResults()),
    recentQueries: unimplemented("SearchClient.recentQueries", placeholder: [])
  )
}

extension DependencyValues {
  var searchClient: SearchClient {
    get { self[SearchClient.self] }
    set { self[SearchClient.self] = newValue }
  }
}

/// 둘러보기 태그 6개 (원본 순서)
enum SearchBrowseTag {
  static let all = ["카페 BGM", "비 오는 날", "새벽 드라이브", "여행 플리", "추억의 명곡", "요즘 핫한 곡"]
}

extension SearchCatalog {
  static let mock = SearchCatalog(
    songs: [
      SearchSong(title: "밤편지", artist: "아이유 (IU)"),
      SearchSong(title: "Blueming", artist: "아이유 (IU)"),
      SearchSong(title: "관객이 될게 (I stan U)", artist: "아이유 (IU)"),
      SearchSong(title: "비와 당신", artist: "이무진", tags: ["비 오는 날"]),
      SearchSong(title: "비의 랩소디", artist: "임재현", tags: ["비 오는 날"]),
      SearchSong(title: "비가 내리는 날에는", artist: "윤하 (Younha)", tags: ["비 오는 날", "추억의 명곡"]),
      SearchSong(title: "벚꽃 엔딩", artist: "버스커 버스커(Busker Busker)", tags: ["추억의 명곡"]),
      SearchSong(title: "Supernova", artist: "aespa", tags: ["요즘 핫한 곡"]),
      SearchSong(title: "How Sweet", artist: "NewJeans", tags: ["요즘 핫한 곡", "여행 플리"]),
      SearchSong(title: "너의 바다", artist: "호피폴라", tags: ["새벽 드라이브", "여행 플리"]),
    ],
    lists: [
      SearchList(title: "손님들이 물어보는 카페 BGM", subtitle: "릴레이리스트 · 3,012명 참여", tags: ["카페 BGM"]),
      SearchList(title: "첫 사랑이 생각나는 노래 모음", subtitle: "릴레이리스트 · 132명 참여", tags: ["추억의 명곡", "드라마 OST"]),
      SearchList(
        title: "[Playlist] 졸릴 때 잠깨기 좋은 청량맛 노동요",
        subtitle: "플레이리스트 · WePLi",
        tags: ["여행 플리", "새벽 드라이브"]
      ),
      SearchList(title: "노을처럼 번지는 아날로그 무드", subtitle: "플레이리스트 · WePLi", tags: ["새벽 드라이브", "추억의 명곡"]),
      SearchList(title: "추위를 녹이는 음색의 보이스", subtitle: "플레이리스트 · WePLi", tags: ["비 오는 날"]),
      SearchList(title: "비 오는 날 듣는 플리", subtitle: "게시글 · 김동", tags: ["비 오는 날"]),
      SearchList(title: "끈적달달한 체리위스키를 머금은 힙합 R&B", subtitle: "플레이리스트 · WePLi", tags: ["카페 BGM"]),
      SearchList(title: "청량함 가득 여름 국힙", subtitle: "플레이리스트 · WePLi", tags: ["여행 플리"]),
      SearchList(title: "뼛속까지 청량해지는 K-pop", subtitle: "플레이리스트 · WePLi", tags: ["여행 플리", "요즘 핫한 곡"]),
    ],
    users: [
      SearchUser(name: "chuuuuu__", subtitle: "센티멘탈 심포니 · 게시글 24"),
      SearchUser(name: "roykim", subtitle: "멜로디 메모리즈 · 게시글 8"),
      SearchUser(name: "minnie._.", subtitle: "소셜 튠즈 · 게시글 31"),
      SearchUser(name: "woogi", subtitle: "에너지 플래시 · 게시글 5"),
      SearchUser(name: "dlwlrma", subtitle: "노스텔지어 서너 · 게시글 12"),
    ]
  )
}
