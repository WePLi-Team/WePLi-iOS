import ComposableArchitecture
import SwiftUI

// REQ-025 · UI-3d — 플레이리스트 상세

struct PlaylistDetailView: View {
  let store: StoreOf<PlaylistDetailFeature>

  var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        ScrollView {
          if let playlist = self.store.playlist {
            VStack(spacing: 0) {
              PlaylistHeader(
                playlist: playlist,
                isIntroductionExpanded: self.store.isIntroductionExpanded,
                onPlay: { self.store.send(.playButtonTapped) },
                onShuffle: { self.store.send(.shuffleButtonTapped) },
                onIntroduction: { self.store.send(.introductionTapped) }
              )
              VStack(alignment: .leading, spacing: 32) {
                PlaylistArtistSection(artists: playlist.artists) { self.store.send(.artistTapped($0)) }
                PlaylistTrackSection(
                  playlist: playlist,
                  onTrack: { self.store.send(.trackTapped($0)) },
                  onMore: { self.store.send(.trackMoreTapped($0)) }
                )
              }
              .padding(.horizontal, 20)
              .padding(.top, 30)
            }
            .padding(.bottom, 40)
          } else if self.store.loadFailed {
            // 원본에 오류 화면이 없어 임시 문구 — 디자인 확인 필요
            VStack(spacing: 12) {
              Text("플레이리스트를 불러오지 못했어요")
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

  private var topButtons: some View {
    HStack(spacing: 8) {
      WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") {
        self.store.send(.backButtonTapped)
      }
      Spacer()
      let isSaved = self.store.playlist?.isSaved == true
      Button {
        self.store.send(.saveButtonTapped)
      } label: {
        Image(systemName: isSaved ? "heart.fill" : "heart")
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(isSaved ? WePLiColor.highlight : WePLiColor.textPrimary)
          .frame(width: WePLiIconButton.size, height: WePLiIconButton.size)
          .wepliGlass(in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(isSaved ? "저장됨" : "저장")
      .accessibilityAddTraits(isSaved ? .isSelected : [])
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
    PlaylistDetailView(store: Store(initialState: PlaylistDetailFeature.State(playlistID: "p")) {
      PlaylistDetailFeature()
    })
  }
}
