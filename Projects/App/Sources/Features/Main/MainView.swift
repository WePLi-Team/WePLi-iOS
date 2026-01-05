import ComposableArchitecture
import SwiftUI

struct MainView: View {
  let store: StoreOf<MainFeature>

  var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        Color.black
          .ignoresSafeArea()

        ScrollView(.vertical, showsIndicators: false) {
          VStack(spacing: 24) {
            // 릴레이리스트 섹션 (상단 safe area까지 확장)
            RelayListSection(
              relayLists: store.relayLists,
              currentIndex: store.currentRelayListIndex,
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
        .ignoresSafeArea(edges: .top)

        // 상단 앱바 (블러 배경)
        MainAppBar(
          onSearchTapped: { store.send(.searchButtonTapped) },
          onNotificationTapped: { store.send(.notificationButtonTapped) }
        )
      }
      .onAppear {
        store.send(.onAppear)
      }
    }
  }
}

// MARK: - MainAppBar

private struct MainAppBar: View {
  let onSearchTapped: () -> Void
  let onNotificationTapped: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        // 로고
        Text("w.")
          .font(.system(size: 24, weight: .bold))
          .foregroundColor(.white)

        Spacer()

        // 검색 버튼
        Button(action: onSearchTapped) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 20))
            .foregroundColor(.white)
        }
        .frame(width: 40, height: 40)

        // 알림 버튼
        Button(action: onNotificationTapped) {
          ZStack(alignment: .topTrailing) {
            Image(systemName: "bell")
              .font(.system(size: 20))
              .foregroundColor(.white)

            Circle()
              .fill(Color.red)
              .frame(width: 5, height: 5)
              .offset(x: 2, y: -2)
          }
        }
        .frame(width: 40, height: 40)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)

      Spacer()
    }
    .background(
      VStack {
        LinearGradient(
          colors: [Color.black.opacity(0.7), Color.black.opacity(0)],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: 120)
        Spacer()
      }
      .ignoresSafeArea(edges: .top)
    )
  }
}

// MARK: - RelayListSection

private struct RelayListSection: View {
  let relayLists: [RelayList]
  let currentIndex: Int
  let onPageChanged: (Int) -> Void

  var body: some View {
    GeometryReader { geometry in
      let topSafeArea = geometry.safeAreaInsets.top
      VStack(spacing: 16) {
        TabView(selection: Binding(
          get: { currentIndex },
          set: { onPageChanged($0) }
        )) {
          ForEach(Array(relayLists.enumerated()), id: \.element.id) { index, relayList in
            RelayListCard(relayList: relayList, topSafeArea: topSafeArea)
              .tag(index)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))

        // 커스텀 인디케이터
        HStack(spacing: 4) {
          ForEach(0 ..< relayLists.count, id: \.self) { index in
            Capsule()
              .fill(Color.white.opacity(index == currentIndex ? 0.7 : 0.3))
              .frame(width: index == currentIndex ? 20 : 4, height: 4)
          }
        }
        .padding(.bottom, 8)
      }
    }
    .frame(height: 450)
  }
}

// MARK: - RelayListCard

private struct RelayListCard: View {
  let relayList: RelayList
  var topSafeArea: CGFloat = 0

  var body: some View {
    ZStack(alignment: .bottom) {
      // 배경 이미지 (플레이스홀더)
      LinearGradient(
        colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      // 하단 그라디언트
      LinearGradient(
        colors: [
          Color.black.opacity(0),
          Color.black.opacity(0.1),
          Color.black.opacity(0.2),
          Color.black.opacity(0.6),
          Color.black,
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .frame(height: 342)

      // 콘텐츠
      VStack(alignment: .leading, spacing: 0) {
        // 상단 safe area + 앱바 높이만큼 여백
        Spacer()
          .frame(height: topSafeArea + 60)

        VStack(alignment: .leading, spacing: 4) {
          // 제목
          Text(relayList.title)
            .font(.system(size: 28, weight: .semibold))
            .foregroundColor(.white)
            .lineSpacing(6)

          // 참여자 수
          Text("\(relayList.participantCount.formatted())명 참여")
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(Color(hex: "D8D8DD"))
        }

        Spacer()
          .frame(height: 32)

        // 첫 곡 정보
        if let firstSong = relayList.firstSong {
          FirstSongView(song: firstSong)
        }

        Spacer()
          .frame(height: 16)

        // 타이머 또는 완성 상태
        TimerView(relayList: relayList)
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 20)
    }
  }
}

// MARK: - FirstSongView

private struct FirstSongView: View {
  let song: Song

  var body: some View {
    HStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 6) {
        Text(song.title)
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(.white)
          .lineLimit(1)

        HStack(spacing: 8) {
          if let albumName = song.albumName {
            Text(albumName)
              .font(.system(size: 14, weight: .light))
              .foregroundColor(Color(hex: "B5B5C0"))
          }

          if song.albumName != nil, song.releaseYear != nil {
            Circle()
              .fill(Color(hex: "B5B5C0"))
              .frame(width: 4, height: 4)
          }

          if let year = song.releaseYear {
            Text(year)
              .font(.system(size: 14, weight: .light))
              .foregroundColor(Color(hex: "B5B5C0"))
          }
        }
      }

      Spacer()

      // 앨범 아트 (플레이스홀더)
      RoundedRectangle(cornerRadius: 8)
        .fill(
          LinearGradient(
            colors: [Color.orange, Color.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 60, height: 60)
    }
  }
}

// MARK: - TimerView

private struct TimerView: View {
  let relayList: RelayList

  var body: some View {
    HStack {
      if relayList.isCompleted {
        Text("릴레이리스트가 완성되었어요 🎉")
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(Color(hex: "F0F0F0"))
      } else {
        Text("플리 완성까지")
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(Color(hex: "F0F0F0"))

        Spacer()

        Text(relayList.remainingTimeText)
          .font(.system(size: 14, weight: .light))
          .foregroundColor(Color(hex: "C2C2C2"))
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color.white.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

// MARK: - ChartSection

private struct ChartSection: View {
  let songs: [ChartSong]
  let updateTime: String
  let onSongTapped: (ChartSong) -> Void
  let onSeeAllTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      // 헤더
      VStack(alignment: .leading, spacing: 4) {
        Text("위플리 TOP 100")
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(Color(hex: "F0F0F0"))

        Text(updateTime)
          .font(.system(size: 12, weight: .light))
          .foregroundColor(Color(hex: "A3A3A3"))
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)

      // 노래 목록
      VStack(spacing: 8) {
        ForEach(songs) { chartSong in
          ChartSongRow(chartSong: chartSong)
            .onTapGesture { onSongTapped(chartSong) }
        }
      }
      .padding(.vertical, 12)
    }
  }
}

// MARK: - ChartSongRow

private struct ChartSongRow: View {
  let chartSong: ChartSong

  var body: some View {
    HStack(spacing: 0) {
      // 앨범 아트
      RoundedRectangle(cornerRadius: 4)
        .fill(
          LinearGradient(
            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 52, height: 52)
        .padding(.leading, 20)

      // 순위
      Text("\(chartSong.rank)")
        .font(.system(size: 12, weight: .light))
        .foregroundColor(Color.white.opacity(0.8))
        .frame(width: 26)

      // 노래 정보
      VStack(alignment: .leading, spacing: 4) {
        Text(chartSong.song.title)
          .font(.system(size: 14, weight: .light))
          .foregroundColor(.white)
          .lineLimit(1)

        Text(chartSong.song.artist)
          .font(.system(size: 12, weight: .light))
          .foregroundColor(Color.white.opacity(0.7))
          .lineLimit(1)
      }

      Spacer()

      // 더보기 버튼
      Button(action: {}) {
        Image(systemName: "ellipsis")
          .font(.system(size: 16))
          .foregroundColor(.white)
      }
      .frame(width: 44, height: 44)
      .padding(.trailing, 20)
    }
    .frame(height: 52)
  }
}

// MARK: - BannerSection

private struct BannerSection: View {
  let banners: [Banner]
  let onBannerTapped: (Banner) -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 16) {
        ForEach(banners) { banner in
          BannerCard(banner: banner)
            .onTapGesture { onBannerTapped(banner) }
        }
      }
      .padding(.horizontal, 20)
    }
  }
}

// MARK: - BannerCard

private struct BannerCard: View {
  let banner: Banner

  var body: some View {
    ZStack(alignment: .leading) {
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(hex: "141417"))

      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(banner.subtitle)
            .font(.system(size: 10, weight: .regular))
            .foregroundColor(Color(hex: "F0F0F0"))

          Text(banner.title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
        }
        .padding(.leading, 20)

        Spacer()

        // 배너 이미지 영역 (플레이스홀더)
        RoundedRectangle(cornerRadius: 4)
          .fill(Color.gray.opacity(0.3))
          .frame(width: 100, height: 76)
          .padding(.trailing, 12)
      }
    }
    .frame(width: 335, height: 84)
  }
}

// MARK: - ArtistRankingSection

private struct ArtistRankingSection: View {
  let artists: [Artist]
  let onArtistTapped: (Artist) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      // 헤더
      VStack(alignment: .leading, spacing: 4) {
        Text("위플리 인기 랭킹")
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(Color(hex: "F0F0F0"))

        Text("위플리 차트에서 인기가 많은 가수들을 모아봤어요")
          .font(.system(size: 12, weight: .light))
          .foregroundColor(Color(hex: "A3A3A3"))
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)

      // 아티스트 목록
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(artists) { artist in
            ArtistProfileView(artist: artist)
              .onTapGesture { onArtistTapped(artist) }
          }
        }
        .padding(.horizontal, 20)
      }
    }
  }
}

// MARK: - ArtistProfileView

private struct ArtistProfileView: View {
  let artist: Artist

  var body: some View {
    VStack(spacing: 4) {
      // 프로필 이미지 (원형 마스크)
      Circle()
        .fill(
          LinearGradient(
            colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .frame(width: 80, height: 80)

      // 아티스트 이름
      Text(artist.name)
        .font(.system(size: 12, weight: .light))
        .foregroundColor(Color(hex: "B5B5C0"))
        .lineLimit(1)
        .frame(width: 92)
        .multilineTextAlignment(.center)
    }
  }
}

// MARK: - PlaylistSection

private struct PlaylistSection: View {
  let title: String
  let playlists: [Playlist]
  let onPlaylistTapped: (Playlist) -> Void
  let onSeeAllTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // 헤더
      Button(action: onSeeAllTapped) {
        HStack(spacing: 4) {
          Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Color(hex: "F0F0F0"))

          Image(systemName: "chevron.right")
            .font(.system(size: 12))
            .foregroundColor(Color(hex: "D8D8DD"))
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)

      // 플레이리스트 목록
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(playlists) { playlist in
            PlaylistItemView(playlist: playlist)
              .onTapGesture { onPlaylistTapped(playlist) }
          }
        }
        .padding(.horizontal, 20)
      }
    }
  }
}

// MARK: - PlaylistItemView

private struct PlaylistItemView: View {
  let playlist: Playlist

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // 커버 이미지 (플레이스홀더)
      RoundedRectangle(cornerRadius: 12)
        .fill(
          LinearGradient(
            colors: [Color.purple.opacity(0.6), Color.pink.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 136, height: 136)

      // 제목
      Text(playlist.title)
        .font(.system(size: 13, weight: .light))
        .foregroundColor(.white)
        .lineLimit(2)
        .frame(width: 136, alignment: .leading)
        .padding(.top, 12)
    }
  }
}

// MARK: - YouTubeSection

private struct YouTubeSection: View {
  let videos: [YouTubeVideo]
  let onVideoTapped: (YouTubeVideo) -> Void
  let onSeeAllTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // 헤더
      Button(action: onSeeAllTapped) {
        HStack(spacing: 4) {
          // YouTube 아이콘 (플레이스홀더)
          Image(systemName: "play.rectangle.fill")
            .font(.system(size: 12))
            .foregroundColor(.red)

          Text("Youtube Music")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Color(hex: "F0F0F0"))

          Image(systemName: "chevron.right")
            .font(.system(size: 12))
            .foregroundColor(Color(hex: "D8D8DD"))
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)

      // 영상 목록
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(videos) { video in
            YouTubeVideoItemView(video: video)
              .onTapGesture { onVideoTapped(video) }
          }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
      }
    }
  }
}

// MARK: - YouTubeVideoItemView

private struct YouTubeVideoItemView: View {
  let video: YouTubeVideo

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // 썸네일 (플레이스홀더)
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.gray.opacity(0.3))
        .frame(width: 240, height: 135)

      // 제목
      Text(video.title)
        .font(.system(size: 15, weight: .regular))
        .foregroundColor(Color(hex: "F0F0F0"))
        .lineLimit(1)
        .frame(width: 240, alignment: .leading)
        .padding(.top, 11)

      // 채널명
      Text(video.channelName)
        .font(.system(size: 13, weight: .light))
        .foregroundColor(Color(hex: "B5B5C0"))
        .padding(.top, 4)
    }
  }
}

// MARK: - Color Extension

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3:
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
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
