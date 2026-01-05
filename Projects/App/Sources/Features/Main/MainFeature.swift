import ComposableArchitecture
import Foundation

@Reducer
struct MainFeature {
  @ObservableState
  struct State: Equatable {
    var relayLists: [RelayList] = []
    var currentRelayListIndex: Int = 0
    var chartSongs: [ChartSong] = []
    var popularArtists: [Artist] = []
    var recommendedPlaylists: [Playlist] = []
    var themedPlaylists: [Playlist] = []
    var youtubeVideos: [YouTubeVideo] = []
    var banners: [Banner] = []
    var isLoading: Bool = false
    var chartUpdateTime: String = ""
  }

  enum Action {
    case onAppear
    case loadData
    case dataLoaded(MainData)
    case relayListPageChanged(Int)
    case searchButtonTapped
    case notificationButtonTapped
    case chartSongTapped(ChartSong)
    case artistTapped(Artist)
    case playlistTapped(Playlist)
    case youtubeVideoTapped(YouTubeVideo)
    case bannerTapped(Banner)
    case seeAllChartTapped
    case seeAllPlaylistTapped
    case seeAllThemedPlaylistTapped
    case seeAllYoutubeTapped
    case timerTick
  }

  @Dependency(\.mainClient)
  var mainClient

  @Dependency(\.continuousClock)
  var clock

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .send(.loadData)

      case .loadData:
        state.isLoading = true
        return .run { send in
          let data = await mainClient.fetchMainData()
          await send(.dataLoaded(data))
        }

      case let .dataLoaded(data):
        state.isLoading = false
        state.relayLists = data.relayLists
        state.chartSongs = data.chartSongs
        state.popularArtists = data.popularArtists
        state.recommendedPlaylists = data.recommendedPlaylists
        state.themedPlaylists = data.themedPlaylists
        state.youtubeVideos = data.youtubeVideos
        state.banners = data.banners
        state.chartUpdateTime = data.chartUpdateTime
        return .run { send in
          for await _ in clock.timer(interval: .seconds(1)) {
            await send(.timerTick)
          }
        }

      case let .relayListPageChanged(index):
        state.currentRelayListIndex = index
        return .none

      case .searchButtonTapped:
        return .none

      case .notificationButtonTapped:
        return .none

      case .chartSongTapped:
        return .none

      case .artistTapped:
        return .none

      case .playlistTapped:
        return .none

      case .youtubeVideoTapped:
        return .none

      case .bannerTapped:
        return .none

      case .seeAllChartTapped:
        return .none

      case .seeAllPlaylistTapped:
        return .none

      case .seeAllThemedPlaylistTapped:
        return .none

      case .seeAllYoutubeTapped:
        return .none

      case .timerTick:
        for index in state.relayLists.indices {
          if state.relayLists[index].remainingSeconds > 0 {
            state.relayLists[index].remainingSeconds -= 1
          }
        }
        return .none
      }
    }
  }
}

// MARK: - Models

struct RelayList: Equatable, Identifiable {
  let id: String
  let title: String
  let participantCount: Int
  let firstSong: Song?
  let backgroundImageURL: String?
  var remainingSeconds: Int

  var isCompleted: Bool {
    remainingSeconds <= 0
  }

  var remainingTimeText: String {
    guard remainingSeconds > 0 else { return "" }
    let days = remainingSeconds / 86400
    let hours = (remainingSeconds % 86400) / 3600
    let minutes = (remainingSeconds % 3600) / 60
    let seconds = remainingSeconds % 60
    return "\(days)일 \(hours)시간 \(minutes)분 \(seconds)초"
  }
}

struct Song: Equatable, Identifiable {
  let id: String
  let title: String
  let artist: String
  let albumName: String?
  let releaseYear: String?
  let albumArtURL: String?
}

struct ChartSong: Equatable, Identifiable {
  let id: String
  let rank: Int
  let song: Song
}

struct Artist: Equatable, Identifiable {
  let id: String
  let name: String
  let profileImageURL: String?
}

struct Playlist: Equatable, Identifiable {
  let id: String
  let title: String
  let coverImageURL: String?
}

struct YouTubeVideo: Equatable, Identifiable {
  let id: String
  let title: String
  let channelName: String
  let thumbnailURL: String?
}

struct Banner: Equatable, Identifiable {
  let id: String
  let title: String
  let subtitle: String
  let imageURL: String?
  let actionURL: String?
}

struct MainData: Equatable {
  let relayLists: [RelayList]
  let chartSongs: [ChartSong]
  let popularArtists: [Artist]
  let recommendedPlaylists: [Playlist]
  let themedPlaylists: [Playlist]
  let youtubeVideos: [YouTubeVideo]
  let banners: [Banner]
  let chartUpdateTime: String
}

// MARK: - MainClient Dependency

struct MainClient {
  var fetchMainData: @Sendable () async -> MainData
}

extension MainClient: DependencyKey {
  static let liveValue = MainClient(
    fetchMainData: {
      // TODO: Implement actual API call
      try? await Task.sleep(nanoseconds: 500000000)
      return .mock
    }
  )

  static let testValue = MainClient(
    fetchMainData: { .mock }
  )

  static let previewValue = MainClient(
    fetchMainData: { .mock }
  )
}

extension DependencyValues {
  var mainClient: MainClient {
    get { self[MainClient.self] }
    set { self[MainClient.self] = newValue }
  }
}

// MARK: - Mock Data

extension MainData {
  static let mock = MainData(
    relayLists: [
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
    ],
    chartSongs: [
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
        song: Song(id: "s2", title: "Supernova", artist: "aespa", albumName: nil, releaseYear: nil, albumArtURL: nil)
      ),
      ChartSong(
        id: "3",
        rank: 3,
        song: Song(id: "s3", title: "How Sweet", artist: "NewJeans", albumName: nil, releaseYear: nil, albumArtURL: nil)
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
        song: Song(id: "s5", title: "소나기", artist: "이클립스 (ECLIPSE)", albumName: nil, releaseYear: nil, albumArtURL: nil)
      ),
    ],
    popularArtists: [
      Artist(id: "a1", name: "BIGBANG (빅뱅)", profileImageURL: nil),
      Artist(id: "a2", name: "비투비", profileImageURL: nil),
      Artist(id: "a3", name: "윤하(Younha/ユンナ)", profileImageURL: nil),
      Artist(id: "a4", name: "엔플라잉(N.Flying)", profileImageURL: nil),
    ],
    recommendedPlaylists: [
      Playlist(id: "p1", title: "끈적달달한 체리위스키를 머금은 힙합 R&B", coverImageURL: nil),
      Playlist(id: "p2", title: "노을처럼 번지는 아날로그 무드", coverImageURL: nil),
      Playlist(id: "p3", title: "추위를 녹이는\n음색의 보이스", coverImageURL: nil),
    ],
    themedPlaylists: [
      Playlist(id: "t1", title: "초여름 청량한 케이팝 댄스", coverImageURL: nil),
      Playlist(id: "t2", title: "청량함 가득 여름 국힙", coverImageURL: nil),
      Playlist(id: "t3", title: "뼛속까지 청량해지는 K-pop", coverImageURL: nil),
    ],
    youtubeVideos: [
      YouTubeVideo(id: "y1", title: "Falling - 로이킴 [더 시즌즈-최정훈의 밤의공원]", channelName: "KBS Kpop", thumbnailURL: nil),
      YouTubeVideo(
        id: "y2",
        title: "ZICO (지코) 'SPOT! (feat. JENNIE)' Official MV",
        channelName: "HYBE LABELS",
        thumbnailURL: nil
      ),
    ],
    banners: [
      Banner(id: "b1", title: "실시간 통합 순위를 한 눈에!", subtitle: "오직 위플리에서만", imageURL: nil, actionURL: nil),
      Banner(id: "b2", title: "감성 가득한 일상 보러가기", subtitle: "위플리 인스타그램 OPEN!", imageURL: nil, actionURL: nil),
    ],
    chartUpdateTime: "6월 23일 오전 7시 업데이트"
  )
}
