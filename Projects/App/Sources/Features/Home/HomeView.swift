import ComposableArchitecture
import SwiftUI

// REQ-020 · UI-12a(DEC-008) — 통합 홈. 히어로(위로 상태 바까지) 위에 머리가 얹히고, 아래로 섹션이 36 간격으로 이어진다.
// 17섹션: 히어로 · TOP 100 · 배너(#101) → 내 참여 · 사람(#102) → 발견 · 내 취향 · 둘러보기(#103)

struct HomeView: View {
  @Perception.Bindable var store: StoreOf<HomeFeature>

  var body: some View {
    WithPerceptionTracking {
      ScrollView {
        if let feed = self.store.feed {
          VStack(spacing: 0) {
            HomeHeroPager(
              heroes: feed.heroes,
              now: self.store.now,
              page: Binding(get: { self.store.heroPage }, set: { self.store.send(.heroPageChanged($0)) }),
              onTap: { self.store.send(.heroTapped($0)) },
              onPlayAll: { self.store.send(.completedPlayAllTapped($0)) }
            )
            .overlay(alignment: .top) {
              HomeHeader(unread: feed.unreadNotifications) { self.store.send(.notificationsTapped) }
                .padding(.top, 58)
            }
            VStack(alignment: .leading, spacing: 36) {
              HomeChartSection(
                feed: feed,
                onSong: { self.store.send(.chartSongTapped($0)) },
                onMore: { self.store.send(.chartMoreTapped($0)) },
                onPlayAll: { self.store.send(.chartPlayAllTapped) }
              )
              HomeBannerSection(banners: feed.banners) { self.store.send(.bannerTapped($0)) }
              self.participation(feed)
              self.discovery(feed)
              self.browse(feed)
            }
            .padding(.top, 24)
            .padding(.bottom, 120)
          }
        } else if self.store.loadFailed {
          // 원본에 오류 화면이 없어 임시 문구 — 디자인 확인 필요
          VStack(spacing: 12) {
            Text("홈을 불러오지 못했어요")
              .wepliFont(.callout, weight: .semibold)
              .foregroundStyle(WePLiColor.textPrimary)
            Button("다시 시도") { self.store.send(.retryButtonTapped) }
              .wepliFont(.body, weight: .semibold)
              .foregroundStyle(WePLiColor.accent)
          }
          .frame(maxWidth: .infinity, minHeight: 500)
        } else {
          ProgressView().tint(WePLiColor.textTertiary).frame(maxWidth: .infinity, minHeight: 500)
        }
      }
      .ignoresSafeArea(edges: .top)
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .wepliToast(Binding(get: { self.store.toast }, set: {
        if $0 == nil {
          self.store.send(.toastDismissed)
        }
      }))
      .onAppear { self.store.send(.onAppear) }
      .onDisappear { self.store.send(.onDisappear) }
    }
  }

  /// 오늘의 플리 → 시간대 추천 → 내 최애 가수 → Fa♥orite
  @ViewBuilder
  private func discovery(_ feed: HomeFeed) -> some View {
    if !feed.todayPicks.isEmpty {
      HomeTodayPicksSection(
        picks: feed.todayPicks,
        onOpen: { self.store.send(.todayHeaderTapped) },
        onTap: { self.store.send(.todayPickTapped($0)) }
      )
    }
    if !feed.timeOfDayColumns.isEmpty {
      HomeTimeOfDaySection(columns: feed.timeOfDayColumns, hour: HomeTimeOfDay.hour(of: self.store.now)) {
        self.store.send(.timeOfDaySongTapped($0))
      }
    }
    HomeFavoriteArtistSection(
      artist: feed.isNewUser ? nil : feed.favoriteArtist,
      isPlaying: self.store.isFavoriteArtistPlaying,
      onTap: { self.store.send(.favoriteArtistTapped) },
      onPlay: { self.store.send(.favoriteArtistPlayTapped) },
      onPick: { self.store.send(.newUserActionTapped(.pickFavoriteArtist)) }
    )
    HomeFavoritesSection(
      favorites: feed.favorites,
      isNewUser: feed.isNewUser,
      onSong: { self.store.send(.favoriteSongTapped($0)) },
      onPlayAll: { self.store.send(.chartPlayAllTapped) },
      onListenTop100: { self.store.send(.newUserActionTapped(.listenTop100)) }
    )
  }

  /// 커뮤니티 인기글 → 인기 랭킹 → 추천 플리 → 테마별 플리 → Youtube Cover
  @ViewBuilder
  private func browse(_ feed: HomeFeed) -> some View {
    if !feed.popularPosts.isEmpty {
      HomePopularPostsSection(posts: feed.popularPosts) { self.store.send(.popularPostTapped($0)) }
    }
    if !feed.popularArtists.isEmpty {
      HomePopularArtistsSection(names: feed.popularArtists) { self.store.send(.popularArtistTapped($0)) }
    }
    if !feed.recommendedPlaylists.isEmpty {
      HomeRecommendedPlaylistsSection(playlists: feed.recommendedPlaylists) { self.store.send(.playlistTapped($0)) }
    }
    if !feed.themePlaylists.isEmpty {
      HomeThemePlaylistsSection(playlists: feed.themePlaylists) { self.store.send(.playlistTapped($0)) }
    }
    if !feed.videos.isEmpty {
      HomeVideosSection(videos: feed.videos) { self.store.send(.videoTapped($0)) }
    }
  }

  /// 내 추천곡 → 투표 중 릴레이 → 1위 예측 → 친구 → 지금 위플리에서 듣는 중
  @ViewBuilder
  private func participation(_ feed: HomeFeed) -> some View {
    if feed.isNewUser || !feed.myRecommendations.isEmpty {
      HomeMyRecommendationsSection(
        items: feed.isNewUser ? [] : feed.myRecommendations,
        isNewUser: feed.isNewUser,
        onTap: { self.store.send(.myRecommendationTapped($0)) },
        onRecommendFirst: { self.store.send(.newUserActionTapped(.recommendFirstSong)) }
      )
    }
    if !feed.votingRelays.isEmpty {
      HomeVotingRelaysSection(relays: feed.votingRelays, now: self.store.now) {
        self.store.send(.votingRelayTapped($0))
      }
    }
    if let prediction = feed.prediction {
      HomePredictionSection(
        prediction: prediction,
        onOpen: { self.store.send(.predictionHeaderTapped) },
        onPick: { self.store.send(.predictionOptionTapped($0)) }
      )
    }
    if feed.isNewUser || !feed.friends.isEmpty {
      HomeFriendsSection(
        friends: feed.friends,
        isNewUser: feed.isNewUser,
        onTap: { self.store.send(.friendTapped($0)) },
        onFindFriends: { self.store.send(.newUserActionTapped(.findFriends)) }
      )
    }
    if !feed.liveListening.songs.isEmpty {
      HomeLiveListeningSection(
        live: feed.liveListening,
        onOpen: { self.store.send(.liveHeaderTapped) },
        onTap: { self.store.send(.liveSongTapped($0)) }
      )
    }
  }
}

#Preview {
  NavigationStack {
    HomeView(store: Store(initialState: HomeFeature.State()) {
      HomeFeature()
    })
  }
}
