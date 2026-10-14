import ComposableArchitecture
import SwiftUI

// REQ-023 · UI-2d — 곡 상세

struct SongDetailView: View {
  let store: StoreOf<SongDetailFeature>

  var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        ScrollView {
          if let song = self.store.song {
            VStack(spacing: 28) {
              SongHero(
                song: song,
                isPlaying: self.store.isPlaying,
                position: self.store.position,
                onPreview: { self.store.send(.previewButtonTapped) },
                onOpenInMusic: { self.store.send(.openInMusicTapped) },
                onArtist: { self.store.send(.artistTapped) }
              )
              SongActionBar(
                song: song,
                onLike: { self.store.send(.likeButtonTapped) },
                onComments: { self.store.send(.commentsTapped) },
                onAddToPlaylist: { self.store.send(.addToPlaylistTapped) }
              )
              .padding(.horizontal, 20)
              SongInfoCards(song: song) { self.store.send(.albumTapped) }
                .padding(.horizontal, 20)
              SongRelatedSections(
                song: song,
                onSong: { self.store.send(.relatedSongTapped($0)) },
                onAlbum: { self.store.send(.otherAlbumTapped($0)) }
              )
            }
            .padding(.bottom, 40)
          } else if self.store.loadFailed {
            // 원본에 오류 화면이 없어 임시 문구 — 디자인 확인 필요
            VStack(spacing: 12) {
              Text("곡 정보를 불러오지 못했어요")
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
      .onDisappear { self.store.send(.onDisappear) }
    }
  }

  private var topButtons: some View {
    HStack(spacing: 8) {
      WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") {
        self.store.send(.backButtonTapped)
      }
      Spacer()
      WePLiIconButton(systemName: "square.and.arrow.up", accessibilityLabel: "공유") {
        self.store.send(.shareButtonTapped)
      }
      WePLiIconButton(systemName: "ellipsis", accessibilityLabel: "더보기") {
        self.store.send(.moreButtonTapped)
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
  }
}

#Preview {
  NavigationStack {
    SongDetailView(store: Store(initialState: SongDetailFeature.State(songID: "bampyeonji")) { SongDetailFeature() })
  }
}
