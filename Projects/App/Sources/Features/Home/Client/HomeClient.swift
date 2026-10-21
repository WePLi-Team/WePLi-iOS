import ComposableArchitecture
import Foundation

// REQ-020 · DEC-004 — 홈 내용은 서버가 정한다. 백엔드가 정해지기 전까지 원본(UI-12a) 예시를 돌려주는 목업이다.

struct HomeClient {
  var fetch: @Sendable () async throws -> HomeFeed
  /// 1위 예측 — 고른 뒤 서버가 비율을 돌려준다
  var predict: @Sendable (_ relayID: String, _ optionID: String) async throws -> [HomePrediction.Option]
  /// 지금 위플리에서 듣는 중 — 5초마다 다시 받는다
  var fetchLiveListening: @Sendable () async throws -> HomeLiveListening
}

extension HomeClient: DependencyKey {
  static let liveValue = HomeClient(
    fetch: {
      @Dependency(\.date.now)
      var now
      return .mock(now: now)
    },
    predict: { _, _ in HomePrediction.mockOptions },
    fetchLiveListening: {
      @Dependency(\.date.now)
      var now
      return .mock(now: now)
    }
  )

  static let previewValue = liveValue

  static let testValue = HomeClient(
    fetch: unimplemented("HomeClient.fetch", placeholder: .mock(now: Date(timeIntervalSince1970: 0))),
    predict: unimplemented("HomeClient.predict", placeholder: []),
    fetchLiveListening: unimplemented(
      "HomeClient.fetchLiveListening",
      placeholder: HomeLiveListening(total: 0, songs: [])
    )
  )
}

extension DependencyValues {
  var homeClient: HomeClient {
    get { self[HomeClient.self] }
    set { self[HomeClient.self] = newValue }
  }
}

extension HomeFeed {
  /// 원본 예시 — 히어로 마감은 지금부터 187,953초 · 33,410초 뒤
  static func mock(now: Date) -> HomeFeed {
    HomeFeed(
      heroes: self.mockHeroes(now: now),
      chartUpdatedText: "6월 23일 오전 7시 업데이트",
      chart: self.mockChart,
      banners: self.mockBanners,
      unreadNotifications: 4,
      myRecommendations: self.mockMyRecommendations,
      votingRelays: self.mockVotingRelays(now: now),
      prediction: self.mockPrediction,
      friends: self.mockFriends,
      liveListening: .mock(now: now),
      todayPicks: self.mockTodayPicks,
      timeOfDayColumns: self.mockTimeOfDay,
      favoriteArtist: HomeFavoriteArtist(name: "로이킴", rank: 1),
      favorites: HomeFavorites(totalCount: 32, songs: self.mockFavorites),
      popularPosts: self.mockPosts,
      popularArtists: ["비투비", "BIGBANG (빅뱅)", "윤하(Younha/ユンナ)", "엔플라잉(N.Flying)"],
      recommendedPlaylists: [
        HomePlaylistCard(id: "p1", title: "끈적달달한 체리위스키를 머금은 힙합 R&B"),
        HomePlaylistCard(id: "p2", title: "노을처럼 번지는 아날로그 무드"),
        HomePlaylistCard(id: "p3", title: "추위를 녹이는 음색의 보이스"),
      ],
      themePlaylists: [
        HomePlaylistCard(id: "t1", title: "초여름 청량한 케이팝 댄스"),
        HomePlaylistCard(id: "t2", title: "청량함 가득 여름 국힙"),
        HomePlaylistCard(id: "t3", title: "뼛속까지 청량해지는 K-pop"),
      ],
      videos: self.mockVideos
    )
  }

  private static let mockTodayPicks: [HomeTodayPick] = [
    HomeTodayPick(
      id: "nerd",
      artistTag: "#너드커넥션(Nerd Connection)",
      title: "그대만 있다면 (여름날 우리 X 너드커넥션 (Nerd Connection))"
    ),
    HomeTodayPick(id: "bampyeonji", artistTag: "#아이유(IU)", title: "밤편지"),
    HomeTodayPick(id: "adult", artistTag: "#Sondia", title: "어른"),
  ]

  private static let mockTimeOfDay: [[HomeChartSong]] = [
    [
      HomeChartSong(id: "rhapsody", title: "비의 랩소디", artist: "임재현"),
      HomeChartSong(id: "bampyeonji", title: "밤편지", artist: "아이유 (IU)"),
      HomeChartSong(id: "sonagi", title: "소나기", artist: "이클립스 (ECLIPSE)"),
    ],
    [
      HomeChartSong(id: "bam", title: "밤양갱", artist: "비비 (BIBI)"),
      HomeChartSong(id: "nerd", title: "그대만 있다면", artist: "너드커넥션 (Nerd Connection)"),
      HomeChartSong(id: "first", title: "첫 만남은 계획대로 되지 않아", artist: "TWS (투어스)"),
    ],
    [
      HomeChartSong(id: "small-girl", title: "Small girl (feat. 도경수)", artist: "이영지"),
      HomeChartSong(id: "love119", title: "Love 119", artist: "RIIZE"),
      HomeChartSong(id: "hype", title: "Hype Boy", artist: "NewJeans"),
    ],
  ]

  private static let mockFavorites: [HomeChartSong] = [
    HomeChartSong(id: "easy", title: "EASY", artist: "LE SSERAFIM (르세라핌)"),
    HomeChartSong(id: "bampyeonji", title: "밤편지", artist: "아이유 (IU)"),
    HomeChartSong(id: "sonagi", title: "소나기", artist: "이클립스 (ECLIPSE)"),
  ]

  private static let mockPosts: [HomePopularPost] = [
    HomePopularPost(
      id: "post-1",
      title: "밤새면서 들을 수 있는 플리",
      body: "여러분은 코딩할 때 어떤 곡을 듣나요?! 댓글로 알려주세요!",
      author: "dlwlrma",
      likeCount: 10123,
      commentCount: 923
    ),
    HomePopularPost(
      id: "post-2",
      title: "너무 심심해요ㅠㅠ",
      body: "혼자서 심심할 때 듣기 좋은 노래 추천 부탁드려요 :)",
      author: "minnie._.",
      likeCount: 8923,
      commentCount: 671
    ),
    HomePopularPost(
      id: "post-3",
      title: "요즘 최애노래",
      body: "케이윌이랑 매드클라운 조합 너무 좋아요ㅠㅠ",
      author: "chuuuuu__",
      likeCount: 5210,
      commentCount: 312
    ),
  ]

  private static let mockVideos: [HomeVideo] = [
    HomeVideo(id: "yc", title: "슬슬 연말 분위기를 내볼까요?", channel: "roykim ∙ #팝송 #캐롤 #플레이리스트"),
    HomeVideo(id: "y1", title: "Falling - 로이킴 [더 시즌즈-최정훈의 밤의공원]", channel: "KBS Kpop"),
    HomeVideo(id: "y2", title: "ZICO (지코) ‘SPOT! (feat. JENNIE)’ Official MV", channel: "HYBE LABELS"),
  ]

  private static func mockHeroes(now: Date) -> [HomeHero] {
    [
      HomeHero(
        id: "cafe-bgm",
        title: "손님들이 물어보는\n카페 BGM",
        people: "3,012명 참여",
        rankLabel: "지금 1위",
        song: "Radical Optimism",
        songMeta: "Dua Lipa · Album",
        status: .live(endsAt: now.addingTimeInterval(187953))
      ),
      HomeHero(
        id: "rainy-night",
        title: "비 오는 밤\n이어달리기",
        people: "바통 릴레이 · 8명 중 4번째",
        rankLabel: "방금 이어진 곡",
        song: "비의 랩소디",
        songMeta: "임재현",
        status: .live(endsAt: now.addingTimeInterval(33410)),
        isBaton: true
      ),
      HomeHero(
        id: "wake-up",
        title: "졸릴 때 잠 깨는\n청량맛 노동요",
        people: "248명이 추천한 12곡",
        rankLabel: "최종 1위",
        song: "Supernova",
        songMeta: "aespa",
        status: .completed
      ),
    ]
  }

  private static let mockChart: [HomeChartSong] = [
    HomeChartSong(id: "supernova", title: "Supernova", artist: "aespa"),
    HomeChartSong(id: "how-sweet", title: "How Sweet", artist: "NewJeans"),
    HomeChartSong(id: "heya", title: "해야 (HEYA)", artist: "IVE (아이브)"),
    HomeChartSong(id: "bam", title: "밤양갱", artist: "비비 (BIBI)"),
    HomeChartSong(id: "first", title: "첫 만남은 계획대로 되지 않아", artist: "TWS (투어스)"),
  ]

  private static let mockBanners: [HomeBanner] = [
    HomeBanner(id: "chart", eyebrow: "오직 위플리에서만", title: "실시간 통합 순위를 한 눈에!"),
    HomeBanner(id: "instagram", eyebrow: "위플리 인스타그램 OPEN!", title: "감성 가득한 일상 보러가기"),
  ]

  private static let mockMyRecommendations: [HomeMyRecommendation] = [
    HomeMyRecommendation(
      id: "easy",
      title: "EASY",
      relayID: "first-love",
      relayTitle: "첫 사랑이 생각나는 노래 모음",
      gapText: "2위까지 42점",
      rank: 3,
      change: .up(1)
    ),
    HomeMyRecommendation(
      id: "sonagi",
      title: "소나기",
      relayID: "rainy-night",
      relayTitle: "비 오는 밤 이어달리기",
      gapText: "1위 유지 중",
      rank: 1,
      change: .same
    ),
  ]

  private static func mockVotingRelays(now: Date) -> [HomeVotingRelay] {
    [
      HomeVotingRelay(
        id: "first-love",
        title: "첫 사랑이 생각나는 노래 모음",
        tags: "#첫사랑 #설렘 #2000년대",
        endsAt: now.addingTimeInterval(18720),
        participantCount: 1284
      ),
      HomeVotingRelay(
        id: "dawn-drive",
        title: "새벽 드라이브 필수곡",
        tags: "#드라이브 #시티팝 #새벽",
        endsAt: now.addingTimeInterval(94200),
        participantCount: 842
      ),
      HomeVotingRelay(
        id: "summer-hiphop",
        title: "청량함 가득 여름 국힙",
        tags: "#국힙 #여름 #청량",
        endsAt: now.addingTimeInterval(180300),
        participantCount: 517
      ),
    ]
  }

  private static let mockPrediction = HomePrediction(
    relayID: "first-love",
    question: "첫 사랑이 생각나는 노래 모음, 최종 1위는?",
    record: "8번 중 5번 적중",
    remaining: "1일 12시간",
    options: HomePrediction.mockOptions.map { HomePrediction.Option(id: $0.id, title: $0.title, percent: 0) },
    pickedID: nil
  )

  private static let mockFriends: [HomeFriendListening] = [
    HomeFriendListening(id: "minsu", name: "민수", line: "Live Forever", isLive: true),
    HomeFriendListening(id: "jisu", name: "지수", line: "seasons", isLive: true),
    HomeFriendListening(id: "dlwlrma", name: "dlwlrma", line: "밤편지", isLive: true),
    HomeFriendListening(id: "minnie", name: "minnie._.", line: "12분 전", isLive: false),
  ]
}

extension HomePrediction {
  static let mockOptions: [Option] = [
    Option(id: "supernova", title: "Supernova", percent: 48),
    Option(id: "how-sweet", title: "How Sweet", percent: 31),
    Option(id: "easy", title: "EASY", percent: 21),
  ]
}

extension HomeLiveListening {
  /// 원본: 5초마다 바뀌는 수 — 1,284 ± 9, 곡마다 기준 ± 4
  static func mock(now: Date) -> HomeLiveListening {
    let step = (now.timeIntervalSince1970 / 5).rounded(.down)
    let wave = { (offset: Double) in sin(step / 3 + offset) }
    let base = [127.0, 98, 84]
    let songs = [
      Song(id: "how-sweet", title: "How Sweet", artist: "NewJeans", listeners: 0),
      Song(id: "supernova", title: "Supernova", artist: "aespa", listeners: 0),
      Song(id: "easy", title: "EASY", artist: "LE SSERAFIM (르세라핌)", listeners: 0),
    ].enumerated().map { index, song in
      var song = song
      song.listeners = Int((base[index] + 4 * wave(Double(index) * 2)).rounded())
      return song
    }
    return HomeLiveListening(total: 1284 + Int((9 * wave(0)).rounded()), songs: songs)
  }
}
