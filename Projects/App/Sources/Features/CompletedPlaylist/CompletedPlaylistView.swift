import ComposableArchitecture
import SwiftUI

// REQ-040 · UI-14b — 완성 플리 · 기준 화면. 홈 히어로 완성 카드 · 릴레이 상세 완성 · 완성 알림이 여기로 온다.

struct CompletedPlaylistView: View {
  let store: StoreOf<CompletedPlaylistFeature>

  var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        ScrollView {
          if let playlist = self.store.playlist {
            self.content(playlist)
          } else if self.store.loadFailed {
            // 원본에 오류 화면이 없어 임시 문구 — 디자인 확인 필요
            VStack(spacing: 12) {
              Text("완성 플리를 불러오지 못했어요")
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
        HStack {
          WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") { self.store.send(.backButtonTapped) }
          Spacer()
          WePLiIconButton(systemName: "ellipsis", accessibilityLabel: "더보기") { self.store.send(.moreTapped) }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
      }
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .wepliToast(self.store.toast) { self.store.send(.toastDismissed) }
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private func content(_ playlist: CompletedPlaylist) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      CompletedPlaylistHero(
        playlist: playlist,
        onExport: { self.store.send(.exportTapped) },
        onPlayAll: { self.store.send(.playAllTapped) }
      )
      CompletedPlaylistActions(
        playlist: playlist,
        onLike: { self.store.send(.likeTapped) },
        onComments: { self.store.send(.commentsTapped) },
        onShare: { self.store.send(.shareTapped) },
        onSave: { self.store.send(.saveTapped) }
      )
      if let best = playlist.myBest {
        CompletedPlaylistMyResult(song: best.song, rank: best.rank, predictionResult: playlist.predictionResult)
      }
      CompletedPlaylistRanking(
        playlist: playlist,
        onSong: { self.store.send(.songTapped($0)) },
        onMore: { self.store.send(.songMoreTapped($0)) }
      )
      CompletedPlaylistComments(count: playlist.commentCount, comments: playlist.comments) {
        self.store.send(.commentsTapped)
      }
      if let next = playlist.nextRelay {
        CompletedPlaylistNextRelay(host: playlist.host, relay: next, isAlertOn: playlist.isNextRelayAlertOn) {
          self.store.send(.nextRelayAlertTapped)
        }
      }
      if !playlist.similar.isEmpty {
        CompletedPlaylistSimilar(playlists: playlist.similar) { self.store.send(.similarTapped($0)) }
      }
    }
    .padding(.bottom, 40)
  }
}

#Preview {
  NavigationStack {
    CompletedPlaylistView(store: Store(initialState: CompletedPlaylistFeature.State(relayID: "wake-up")) {
      CompletedPlaylistFeature()
    })
  }
}
