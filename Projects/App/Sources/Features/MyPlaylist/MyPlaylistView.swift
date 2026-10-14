import ComposableArchitecture
import SwiftUI

// REQ-078 · UI-10d — 내 플레이리스트 · 편집
// 보기: 커버 112 · 이름 20 Bold · 「N곡 · 비공개」 · 재생(그라디언트) · 게시글로 공유
// 편집: 커버 변경 덮개 · 이름 입력(30자) · 곡 왼쪽 − (#FF453A) · 오른쪽 ▲▼ · 플레이리스트 삭제

struct MyPlaylistView: View {
  @Perception.Bindable var store: StoreOf<MyPlaylistFeature>

  var body: some View {
    WithPerceptionTracking {
      ScrollView {
        if let playlist = self.store.playlist {
          VStack(spacing: 0) {
            self.header(playlist)
            if !self.store.isEditing {
              self.actions.padding(.top, 20)
            }
            VStack(spacing: 0) {
              ForEach(playlist.tracks) { track in
                MyPlaylistTrackRow(track: track, isEditing: self.store.isEditing) { self.store.send($0) }
              }
            }
            .padding(.top, 16)
            if self.store.isEditing {
              Button {
                self.store.send(.deleteTapped)
              } label: {
                Text("플레이리스트 삭제")
                  .wepliFont(.callout)
                  .foregroundStyle(WePLiColor.destructive)
                  .frame(maxWidth: .infinity)
                  .frame(height: 52)
                  .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
              }
              .buttonStyle(.plain)
              .padding(.horizontal, 16)
              .padding(.top, 18)
            }
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
          .frame(maxWidth: .infinity, minHeight: 400)
        } else {
          ProgressView().tint(WePLiColor.textTertiary).frame(maxWidth: .infinity, minHeight: 400)
        }
      }
      .safeAreaInset(edge: .top, spacing: 0) { self.navigationBar }
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .animation(.easeInOut(duration: 0.2), value: self.store.isEditing)
      .confirmationDialog(self.$store.scope(state: \.deleteDialog, action: \.deleteDialog))
      .wepliToast(Binding(get: { self.store.toast }, set: {
        if $0 == nil {
          self.store.send(.toastDismissed)
        }
      }))
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private var navigationBar: some View {
    HStack {
      WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") { self.store.send(.backButtonTapped) }
      Spacer()
      Button(self.store.isEditing ? "완료" : "편집") { self.store.send(.editButtonTapped) }
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.accent)
        .disabled(self.store.playlist == nil || self.store.isSaving)
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
    .background(WePLiColor.background)
  }

  private var cover: some View {
    Button {
      self.store.send(.coverTapped)
    } label: {
      RoundedRectangle(cornerRadius: 14)
        .fill(WePLiColor.surface4)
        .frame(width: 112, height: 112)
        .overlay {
          Image(systemName: "music.note.list")
            .font(.system(size: 30, weight: .light))
            .foregroundStyle(WePLiColor.textQuaternary)
        }
        .overlay {
          if self.store.isEditing {
            RoundedRectangle(cornerRadius: 14)
              .fill(WePLiColor.dim)
              .overlay {
                Text("커버 변경")
                  .wepliFont(.footnote, weight: .semibold)
                  .foregroundStyle(WePLiColor.textPrimary)
              }
          }
        }
    }
    .buttonStyle(.plain)
    .disabled(!self.store.isEditing)
    .accessibilityLabel(self.store.isEditing ? "커버 변경" : "커버")
  }

  private func header(_ playlist: MyPlaylist) -> some View {
    HStack(spacing: 16) {
      self.cover

      VStack(alignment: .leading, spacing: 6) {
        if self.store.isEditing {
          TextField("", text: Binding(get: { playlist.name }, set: { self.store.send(.nameChanged($0)) }))
            .wepliFont(.button)
            .foregroundStyle(WePLiColor.textPrimary)
            .tint(WePLiColor.accent)
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(WePLiColor.surface2, in: RoundedRectangle(cornerRadius: 10))
            .accessibilityLabel("플레이리스트 이름")
        } else {
          Text(playlist.name)
            .wepliFont(.title3, weight: .bold)
            .foregroundStyle(WePLiColor.textPrimary)
            .lineLimit(2)
        }
        Text(playlist.meta)
          .wepliFont(.footnote)
          .foregroundStyle(WePLiColor.textQuaternary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 20)
    .padding(.top, 12)
  }

  private var actions: some View {
    HStack(spacing: 10) {
      Button {
        self.store.send(.playTapped)
      } label: {
        Label("재생", systemImage: "play.fill")
          .wepliFont(.body, weight: .semibold)
          .foregroundStyle(WePLiColor.textOnCTA)
          .frame(maxWidth: .infinity)
          .frame(height: 46)
          .background(Capsule().fill(WePLiGradient.cta))
      }
      .buttonStyle(.plain)
      Button {
        self.store.send(.shareAsPostTapped)
      } label: {
        Text("게시글로 공유")
          .wepliFont(.body, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
          .frame(maxWidth: .infinity)
          .frame(height: 46)
          .background(WePLiColor.secondaryButtonFill, in: Capsule())
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 20)
  }
}

#Preview {
  NavigationStack {
    MyPlaylistView(store: Store(initialState: MyPlaylistFeature.State(playlistID: "album")) {
      MyPlaylistFeature()
    })
  }
}
