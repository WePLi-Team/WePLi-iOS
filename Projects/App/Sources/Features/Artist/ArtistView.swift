import ComposableArchitecture
import SwiftUI

// REQ-024 · UI-5b — 아티스트. 큰 이미지 헤더 위에 투명 내비게이션(뒤로 · 공유)이 떠 있다.

struct ArtistView: View {
  let store: StoreOf<ArtistFeature>

  var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        ScrollView {
          if let artist = self.store.artist {
            VStack(spacing: 0) {
              ArtistHero(
                artist: artist,
                onLike: { self.store.send(.likeButtonTapped) },
                onPlayAll: { self.store.send(.playAllTapped) }
              )
              self.sections(artist)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 60)
            }
          } else if self.store.loadFailed {
            // 원본에 오류 화면이 없어 임시 문구 — 디자인 확인 필요
            VStack(spacing: 12) {
              Text("아티스트 정보를 불러오지 못했어요")
                .wepliFont(.callout, weight: .semibold)
                .foregroundStyle(WePLiColor.textPrimary)
              Button("다시 시도") { self.store.send(.retryButtonTapped) }
                .wepliFont(.body, weight: .semibold)
                .foregroundStyle(WePLiColor.accent)
            }
            .frame(maxWidth: .infinity, minHeight: 500)
          } else {
            ProgressView()
              .tint(WePLiColor.textTertiary)
              .frame(maxWidth: .infinity, minHeight: 500)
          }
        }
        .ignoresSafeArea(edges: .top)

        self.topButtons
      }
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private func sections(_ artist: ArtistDetail) -> some View {
    VStack(alignment: .leading, spacing: 32) {
      ArtistPopularSongs(
        songs: artist.popularSongs,
        onHeader: { self.store.send(.popularSongsTapped) },
        onSong: { self.store.send(.songTapped($0)) },
        onMenu: { self.store.send(.songMenuTapped($0)) }
      )
      ArtistAlbums(albums: artist.albums) { self.store.send(.albumTapped($0)) }
      if !artist.places.isEmpty {
        ArtistPlaces(artist: artist) { self.store.send(.placeTapped($0)) }
      }
      if !artist.relatedArtists.isEmpty {
        ArtistRelated(names: artist.relatedArtists) { self.store.send(.relatedArtistTapped($0)) }
      }
    }
  }

  private var topButtons: some View {
    HStack {
      WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") {
        self.store.send(.backButtonTapped)
      }
      Spacer()
      WePLiIconButton(systemName: "square.and.arrow.up", accessibilityLabel: "공유") {
        self.store.send(.shareButtonTapped)
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
  }
}

#Preview {
  NavigationStack {
    ArtistView(store: Store(initialState: ArtistFeature.State(artistID: "아이유")) {
      ArtistFeature()
    })
  }
}
