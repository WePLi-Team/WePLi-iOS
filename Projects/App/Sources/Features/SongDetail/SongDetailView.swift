import ComposableArchitecture
import SwiftUI

// REQ-023 · UI-2d v2 — 곡 상세

struct SongDetailView: View {
  let store: StoreOf<SongDetailFeature>
  /// 스크롤한 거리 — 히어로가 넓어지는 정도(UI-2d v2 노트 01)
  @State private var scrollY: CGFloat = 0

  var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        ScrollView {
          if let song = self.store.song {
            VStack(spacing: 0) {
              SongHero(song: song, progress: min(max(self.scrollY / SongHero.Metric.collapse, 0), 1))
                .background(alignment: .top) { self.scrollReader }
              SongControls(
                song: song,
                isPlaying: self.store.isPlaying,
                position: self.store.position,
                onPreview: { self.store.send(.previewButtonTapped) },
                onOpenInMusic: { self.store.send(.openInMusicTapped) },
                onLike: { self.store.send(.likeButtonTapped) },
                onRecommend: { self.store.send(.recommendTapped) },
                onAddToPlaylist: { self.store.send(.addToPlaylistTapped) }
              )
              VStack(alignment: .leading, spacing: 36) {
                if !song.relays.isEmpty {
                  SongRelaySection(relays: song.relays) { self.store.send(.relayTapped($0)) }
                }
                SongInfoList(song: song) { self.store.send(.albumTapped) }
                SongCommentSection(count: song.commentCount, comments: song.comments) {
                  self.store.send(.commentsTapped)
                }
                SongRelatedSections(
                  song: song,
                  onSong: { self.store.send(.relatedSongTapped($0)) },
                  onPlay: { self.store.send(.relatedPlayTapped($0)) },
                  onAlbum: { self.store.send(.otherAlbumTapped($0)) }
                )
              }
              .padding(.top, 36)
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
        .coordinateSpace(name: Self.scrollSpace)
        .onPreferenceChange(SongScrollOffsetKey.self) { self.scrollY = $0 }
        .ignoresSafeArea(edges: .top)

        self.topButtons
      }
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .onAppear { self.store.send(.onAppear) }
      .onDisappear { self.store.send(.onDisappear) }
    }
  }

  private static let scrollSpace = "songDetailScroll"

  private var scrollReader: some View {
    GeometryReader { proxy in
      Color.clear.preference(
        key: SongScrollOffsetKey.self,
        value: -proxy.frame(in: .named(Self.scrollSpace)).minY
      )
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

private struct SongScrollOffsetKey: PreferenceKey {
  static let defaultValue: CGFloat = 0

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

#Preview {
  NavigationStack {
    SongDetailView(store: Store(initialState: SongDetailFeature.State(songID: "bampyeonji")) { SongDetailFeature() })
  }
}
