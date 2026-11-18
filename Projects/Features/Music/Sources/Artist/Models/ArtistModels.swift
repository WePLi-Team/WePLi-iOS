import Foundation

// REQ-024 · UI-5b — 아티스트

public struct ArtistDetail: Equatable, Identifiable, Sendable {
  public struct Song: Equatable, Identifiable, Sendable {
    public var id: String {
      self.title
    }

    public let title: String
    public let album: String
    public let year: Int

    /// 「밤편지 · 2017」
    public var subtitle: String {
      "\(self.album) · \(self.year)"
    }

    public init(title: String, album: String, year: Int) {
      self.title = title
      self.album = album
      self.year = year
    }
  }

  public struct Album: Equatable, Identifiable, Sendable {
    public var id: String {
      self.title
    }

    public let title: String
    /// 「2024 · 미니」
    public let meta: String

    public init(title: String, meta: String) {
      self.title = title
      self.meta = meta
    }
  }

  /// 「위플리에서 함께 듣는 곳」 — 이 아티스트의 곡이 담긴 플레이리스트와 게시글(원본 노트 02)
  public struct Place: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let kind: ArtistPlaceKind

    public init(id: String, title: String, kind: ArtistPlaceKind) {
      self.id = id
      self.title = title
      self.kind = kind
    }
  }

  /// 아티스트 id — 목업은 이름을 그대로 쓴다
  public let id: String
  /// 「아이유 (IU)」
  public let name: String
  /// 「위플리 차트 진입 6곡」 — 계산 기준은 서버가 정한다(원본에 규칙 없음)
  public let chartEntryCount: Int
  public var isLiked: Bool
  /// 인기곡 Top 5
  public let popularSongs: [Song]
  public let albums: [Album]
  public let places: [Place]
  public let relatedArtists: [String]

  /// 「플레이리스트 · 아이유 3곡 포함」 · 「게시글 · dlwlrma」
  public func meta(for place: Place) -> String {
    switch place.kind {
    case let .playlist(count): "플레이리스트 · \(self.id) \(count)곡 포함"
    case let .post(author): "게시글 · \(author)"
    }
  }

  public init(
    id: String,
    name: String,
    chartEntryCount: Int,
    isLiked: Bool,
    popularSongs: [Song],
    albums: [Album],
    places: [Place],
    relatedArtists: [String]
  ) {
    self.id = id
    self.name = name
    self.chartEntryCount = chartEntryCount
    self.isLiked = isLiked
    self.popularSongs = popularSongs
    self.albums = albums
    self.places = places
    self.relatedArtists = relatedArtists
  }
}

public enum ArtistPlaceKind: Equatable, Sendable {
  /// 담긴 곡 수
  case playlist(songCount: Int)
  /// 작성자 닉네임
  case post(author: String)
}

public extension ArtistDetail {
  /// 원본(UI-5b) 예시 데이터
  static func mock(id: String) -> ArtistDetail {
    ArtistDetail(
      id: id,
      name: id == "아이유" ? "아이유 (IU)" : id,
      chartEntryCount: 6,
      isLiked: false,
      popularSongs: [
        Song(title: "밤편지", album: "밤편지", year: 2017),
        Song(title: "관객이 될게 (I stan U)", album: "The Winning", year: 2024),
        Song(title: "Blueming", album: "Love poem", year: 2019),
        Song(title: "에잇(Prod. & Feat. SUGA of BTS)", album: "에잇", year: 2020),
        Song(title: "팔레트 (Feat. G-DRAGON)", album: "Palette", year: 2017),
      ],
      albums: [
        Album(title: "The Winning", meta: "2024 · 미니"),
        Album(title: "Love poem", meta: "2019 · 미니"),
        Album(title: "에잇", meta: "2020 · 싱글"),
        Album(title: "Palette", meta: "2017 · 정규"),
      ],
      places: [
        Place(id: "pl-1", title: "졸릴 때 잠깨기 좋은 청량맛 노동요", kind: .playlist(songCount: 3)),
        Place(id: "post-1", title: "밤새면서 들을 수 있는 플리", kind: .post(author: "dlwlrma")),
      ],
      relatedArtists: ["윤하(Younha)", "비투비", "BIGBANG (빅뱅)", "엔플라잉(N.Flying)"]
    )
  }
}
