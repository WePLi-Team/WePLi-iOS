import ComposableArchitecture
import SwiftUI

// REQ-077 · UI-5c — 보관함(내 활동)

struct LibraryView: View {
  let store: StoreOf<LibraryFeature>

  var body: some View {
    WithPerceptionTracking {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          Text("보관함")
            .wepliFont(.screenTitle)
            .foregroundStyle(WePLiColor.textPrimary)
            .padding(.horizontal, 20)
            .padding(.top, 2)
            .padding(.bottom, 14)
            .accessibilityAddTraits(.isHeader)
          LibrarySegmentControl(selected: self.store.segment) { self.store.send(.segmentSelected($0)) }
            .padding(.horizontal, 20)
          if let library = self.store.library {
            self.content(library)
          } else if self.store.loadFailed {
            // 원본에 오류 화면이 없어 임시 문구 — 디자인 확인 필요
            WePLiEmptyState(
              systemImage: "exclamationmark.triangle",
              title: "보관함을 불러오지 못했어요",
              message: "잠시 후 다시 시도해 주세요.",
              actionTitle: "다시 시도",
              action: { self.store.send(.retryButtonTapped) }
            )
            .padding(.vertical, 60)
          } else {
            VStack(spacing: 12) {
              ForEach(0 ..< 3, id: \.self) { _ in
                WePLiSongRowSkeleton()
              }
            }
            .padding(20)
            .wepliPulse()
          }
        }
        .padding(.bottom, 24)
      }
      .safeAreaInset(edge: .top, spacing: 0) { self.navigationBar }
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .onAppear { self.store.send(.onAppear) }
      .onDisappear { self.store.send(.onDisappear) }
    }
  }

  private var navigationBar: some View {
    HStack {
      WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") {
        self.store.send(.backButtonTapped)
      }
      Spacer()
      Button("편집") { self.store.send(.editButtonTapped) }
        .wepliFont(.callout, weight: .medium)
        .foregroundStyle(WePLiColor.accent)
        .padding(10)
    }
    .padding(.leading, 16)
    .padding(.trailing, 12)
    .frame(height: 48)
    .background(WePLiColor.background)
  }

  @ViewBuilder
  private func content(_ library: Library) -> some View {
    switch self.store.segment {
    case .playlists:
      LibraryPlaylistsSection(
        playlists: library.playlists,
        onNew: { self.store.send(.newPlaylistTapped) },
        onPlaylist: { self.store.send(.playlistTapped($0)) }
      )
    case .relays:
      LibraryRelaysSection(
        library: library,
        now: self.store.now,
        onContinue: { self.store.send(.continueVotingTapped($0)) },
        onRelay: { self.store.send(.relayTapped($0)) }
      )
    case .likes:
      LibraryLikesSection(
        library: library,
        onSong: { self.store.send(.likedSongTapped($0)) },
        onPost: { self.store.send(.savedPostTapped($0)) },
        onBrowse: { self.store.send(.backButtonTapped) }
      )
    }
  }
}

#Preview {
  NavigationStack {
    LibraryView(store: Store(initialState: LibraryFeature.State()) { LibraryFeature() })
  }
}
