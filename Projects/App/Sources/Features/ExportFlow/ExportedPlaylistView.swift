import ComposableArchitecture
import SwiftUI

// REQ-050 · UI-14m — 내보낸 플리 · 변경 기록. 위플리가 내 음악 앱 속 플리를 무엇 때문에 바꿨는지 보여준다.

struct ExportedPlaylistView: View {
  let store: StoreOf<ExportedPlaylistFeature>

  @Dependency(\.date.now)
  private var now

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        ZStack {
          Text("내보낸 플리").wepliFont(.button).foregroundStyle(WePLiColor.textPrimary).accessibilityAddTraits(.isHeader)
          HStack {
            WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") {
              self.store.send(.backButtonTapped)
            }
            Spacer()
          }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        if let playlist = self.store.playlist {
          ScrollView { self.content(playlist) }
        } else if self.store.loadFailed {
          self.failed
        } else {
          Spacer()
          ProgressView().tint(WePLiColor.textTertiary)
          Spacer()
        }
      }
      .background(WePLiColor.background.ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
      .onAppear { self.store.send(.onAppear) }
      .wepliToast(self.store.toast) { self.store.send(.toastDismissed) }
    }
  }

  private var failed: some View {
    VStack(spacing: 12) {
      Spacer()
      // 원본에 없는 문구 — 디자인 확인 필요
      Text("내보낸 플리를 불러오지 못했어요").wepliFont(.body).foregroundStyle(WePLiColor.textSecondary)
      Button("다시 시도") { self.store.send(.retryButtonTapped) }
        .wepliFont(.subheadline, weight: .semibold)
        .foregroundStyle(WePLiColor.accent)
      Spacer()
    }
  }

  private func content(_ playlist: ExportedPlaylist) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 16) {
        ExportArtwork(size: 84, radius: 8)
        VStack(alignment: .leading, spacing: 6) {
          Text(playlist.title).wepliFont(.headline).foregroundStyle(WePLiColor.textPrimary)
          HStack(spacing: 6) {
            ExportServiceIcon(service: playlist.service, size: 18)
            Text("\(playlist.service.name) · \(playlist.exportedAtText)")
              .wepliFont(.footnote, weight: .light)
              .foregroundStyle(WePLiColor.textTertiary)
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 18)
      self.syncStatus(playlist).padding(.horizontal, 20).padding(.top, 16)
      VStack(alignment: .leading, spacing: 4) {
        Text("변경 기록").wepliFont(.headline).foregroundStyle(WePLiColor.textPrimary).accessibilityAddTraits(.isHeader)
        Text("WePLi가 \(playlist.service.name) 플리에 반영한 내용이에요")
          .wepliFont(.caption, weight: .light)
          .foregroundStyle(WePLiColor.textTertiary)
      }
      .padding(.horizontal, 20)
      .padding(.top, 30)
      .padding(.bottom, 8)
      ForEach(playlist.history) { change in
        self.historyRow(change)
      }
      Text("\(playlist.service.name)에서 곡을 직접 고치면 자동 반영을 멈추고 알려드려요.")
        .wepliFont(.caption, weight: .light)
        .foregroundStyle(WePLiColor.textQuaternary)
        .padding(.horizontal, 20)
        .padding(.top, 10)
      self.actions(playlist)
    }
    .padding(.bottom, 40)
  }

  private func syncStatus(_ playlist: ExportedPlaylist) -> some View {
    let detail = playlist.endsAt.map { "마감까지 \(ExportText.untilDeadline(from: self.now, to: $0))" } ?? "완성"
    return HStack(spacing: 8) {
      if playlist.isSyncOn {
        Circle().fill(WePLiGradient.vsRing).frame(width: 7, height: 7)
        Text("자동 반영 중").wepliFont(.subheadline, weight: .semibold).foregroundStyle(WePLiColor.accent)
        Text("· \(detail)").wepliFont(.subheadline, weight: .light).foregroundStyle(WePLiColor.textTertiary)
      } else {
        Circle().fill(WePLiColor.textDisabled).frame(width: 7, height: 7)
        Text("자동 반영 멈춤").wepliFont(.subheadline, weight: .semibold).foregroundStyle(WePLiColor.textTertiary)
        Text("· 지금 담긴 곡 그대로").wepliFont(.subheadline, weight: .light).foregroundStyle(WePLiColor.textTertiary)
      }
    }
    .accessibilityElement(children: .combine)
  }

  private func historyRow(_ change: ExportChange) -> some View {
    HStack(alignment: .top, spacing: 14) {
      Text(change.timeText)
        .wepliFont(.caption, weight: .light)
        .foregroundStyle(WePLiColor.textQuaternary)
        .frame(width: 62, alignment: .leading)
        .padding(.top, 2)
      VStack(alignment: .leading, spacing: 0) {
        Text(change.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
        Text(change.detail).wepliFont(.footnote, weight: .light).foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .accessibilityElement(children: .combine)
  }

  private func actions(_ playlist: ExportedPlaylist) -> some View {
    VStack(spacing: 0) {
      HStack(spacing: 10) {
        ExportSecondaryButton(title: "지금 반영하기") { self.store.send(.syncNowTapped) }
        ExportSecondaryButton(title: "\(playlist.service.name)에서 열기") { self.store.send(.openInServiceTapped) }
      }
      .padding(.top, 28)
      Button(playlist.isSyncOn ? "자동 반영 멈추기" : "자동 반영 다시 켜기") { self.store.send(.syncToggleTapped) }
        .wepliFont(.subheadline)
        .foregroundStyle(WePLiColor.textTertiary)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
    }
    .padding(.horizontal, 20)
  }
}

#Preview {
  NavigationStack {
    ExportedPlaylistView(store: Store(initialState: ExportedPlaylistFeature.State(playlistID: "live-cafe")) {
      ExportedPlaylistFeature()
    })
  }
}
