import ComposableArchitecture
import SwiftUI

struct MainView: View {
  let store: StoreOf<MainFeature>

  var body: some View {
    WithPerceptionTracking {
      GeometryReader { geometry in
        let topSafeArea = geometry.safeAreaInsets.top

        ZStack(alignment: .top) {
          ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
              // 릴레이리스트 섹션
              RelayListSection(
                relayLists: store.relayLists,
                currentIndex: store.currentRelayListIndex,
                topSafeArea: topSafeArea,
                onPageChanged: { store.send(.relayListPageChanged($0)) }
              )

              // 위플리 TOP 100
              ChartSection(
                songs: store.chartSongs,
                updateTime: store.chartUpdateTime,
                onSongTapped: { store.send(.chartSongTapped($0)) },
                onSeeAllTapped: { store.send(.seeAllChartTapped) }
              )

              // 배너 섹션
              BannerSection(
                banners: store.banners,
                onBannerTapped: { store.send(.bannerTapped($0)) }
              )

              // 위플리 인기 랭킹
              ArtistRankingSection(
                artists: store.popularArtists,
                onArtistTapped: { store.send(.artistTapped($0)) }
              )

              // 위플리 추천 플레이리스트
              PlaylistSection(
                title: "위플리 추천 플레이리스트",
                playlists: store.recommendedPlaylists,
                onPlaylistTapped: { store.send(.playlistTapped($0)) },
                onSeeAllTapped: { store.send(.seeAllPlaylistTapped) }
              )

              // 테마별 플레이리스트
              PlaylistSection(
                title: "테마별 플레이리스트",
                playlists: store.themedPlaylists,
                onPlaylistTapped: { store.send(.playlistTapped($0)) },
                onSeeAllTapped: { store.send(.seeAllThemedPlaylistTapped) }
              )

              // YouTube Music
              YouTubeSection(
                videos: store.youtubeVideos,
                onVideoTapped: { store.send(.youtubeVideoTapped($0)) },
                onSeeAllTapped: { store.send(.seeAllYoutubeTapped) }
              )

              Spacer()
                .frame(height: 100)
            }
          }

          // 상단 앱바
          MainAppBar(
            topSafeArea: topSafeArea,
            onSearchTapped: { store.send(.searchButtonTapped) },
            onNotificationTapped: { store.send(.notificationButtonTapped) }
          )
        }
        .ignoresSafeArea(edges: .top)
      }
      .onAppear {
        store.send(.onAppear)
      }
    }
  }
}

// MARK: - Preview

#Preview {
  MainView(
    store: Store(initialState: MainFeature.State()) {
      MainFeature()
    }
  )
}
