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
