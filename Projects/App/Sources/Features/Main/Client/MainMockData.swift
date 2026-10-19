import Foundation

// MARK: - MainData Mock

extension MainData {
  static let mock = MainData(
    relayLists: RelayList.mockList,
    chartSongs: ChartSong.mockList,
    popularArtists: Artist.mockList,
    recommendedPlaylists: Playlist.recommendedMockList,
    themedPlaylists: Playlist.themedMockList,
    youtubeVideos: YouTubeVideo.mockList,
    banners: Banner.mockList,
    chartUpdateTime: "6월 23일 오전 7시 업데이트"
  )
}

// MARK: - RelayList Mock

extension RelayList {
  static let mockList: [RelayList] = [
    RelayList(
      id: "1",
      title: "손님들이 물어보는\n카페 BGM",
      participantCount: 3012,
      firstSong: Song(
        id: "1",
        title: "Radical Optimism",
        artist: "Dua Lipa",
        albumName: "Album",
        releaseYear: "2024",
        albumArtURL: nil
      ),
      backgroundImageURL: nil,
      remainingSeconds: 130215
    ),
    RelayList(
      id: "2",
      title: "비 오는 날 듣기 좋은\n감성 플레이리스트",
      participantCount: 2456,
      firstSong: nil,
      backgroundImageURL: nil,
      remainingSeconds: 0
    ),
  ]
}

// MARK: - ChartSong Mock

extension ChartSong {
  static let mockList: [ChartSong] = [
    ChartSong(
      id: "1",
      rank: 1,
      song: Song(
        id: "s1",
        title: "Small girl (feat. 도경수 (D.O)",
        artist: "이영지",
        albumName: nil,
        releaseYear: nil,
        albumArtURL: nil
      )
    ),
    ChartSong(
      id: "2",
      rank: 2,
      song: Song(
        id: "s2",
        title: "Supernova",
        artist: "aespa",
        albumName: nil,
        releaseYear: nil,
        albumArtURL: nil
      )
    ),
    ChartSong(
      id: "3",
      rank: 3,
      song: Song(
        id: "s3",
        title: "How Sweet",
        artist: "NewJeans",
        albumName: nil,
        releaseYear: nil,
        albumArtURL: nil
      )
    ),
    ChartSong(
      id: "4",
      rank: 4,
      song: Song(
        id: "s4",
        title: "해야 (HEYA)",
        artist: "IVE (아이브)",
        albumName: nil,
        releaseYear: nil,
        albumArtURL: nil
      )
    ),
    ChartSong(
      id: "5",
      rank: 5,
      song: Song(
        id: "s5",
        title: "소나기",
        artist: "이클립스 (ECLIPSE)",
        albumName: nil,
        releaseYear: nil,
        albumArtURL: nil
      )
    ),
  ]
}

// MARK: - Artist Mock

extension Artist {
  static let mockList: [Artist] = [
    Artist(id: "a1", name: "BIGBANG (빅뱅)", profileImageURL: nil),
    Artist(id: "a2", name: "비투비", profileImageURL: nil),
    Artist(id: "a3", name: "윤하(Younha/ユンナ)", profileImageURL: nil),
    Artist(id: "a4", name: "엔플라잉(N.Flying)", profileImageURL: nil),
  ]
}

// MARK: - Playlist Mock

extension Playlist {
  static let recommendedMockList: [Playlist] = [
    Playlist(id: "p1", title: "끈적달달한 체리위스키를 머금은 힙합 R&B", coverImageURL: nil),
    Playlist(id: "p2", title: "노을처럼 번지는 아날로그 무드", coverImageURL: nil),
    Playlist(id: "p3", title: "추위를 녹이는\n음색의 보이스", coverImageURL: nil),
  ]

  static let themedMockList: [Playlist] = [
    Playlist(id: "t1", title: "초여름 청량한 케이팝 댄스", coverImageURL: nil),
    Playlist(id: "t2", title: "청량함 가득 여름 국힙", coverImageURL: nil),
    Playlist(id: "t3", title: "뼛속까지 청량해지는 K-pop", coverImageURL: nil),
  ]
}

// MARK: - YouTubeVideo Mock

extension YouTubeVideo {
  static let mockList: [YouTubeVideo] = [
    YouTubeVideo(
      id: "y1",
      title: "Falling - 로이킴 [더 시즌즈-최정훈의 밤의공원]",
      channelName: "KBS Kpop",
      thumbnailURL: nil
    ),
    YouTubeVideo(
      id: "y2",
      title: "ZICO (지코) 'SPOT! (feat. JENNIE)' Official MV",
      channelName: "HYBE LABELS",
      thumbnailURL: nil
    ),
  ]
}

// MARK: - Banner Mock

extension Banner {
  static let mockList: [Banner] = [
    Banner(
      id: "b1",
      title: "실시간 통합 순위를 한 눈에!",
      subtitle: "오직 위플리에서만",
      imageURL: nil,
      actionURL: nil
    ),
    Banner(
      id: "b2",
      title: "감성 가득한 일상 보러가기",
      subtitle: "위플리 인스타그램 OPEN!",
      imageURL: nil,
      actionURL: nil
    ),
  ]
}
