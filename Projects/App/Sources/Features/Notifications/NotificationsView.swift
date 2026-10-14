import ComposableArchitecture
import SwiftUI

// REQ-081 · UI-4d — 알림

struct NotificationsView: View {
  let store: StoreOf<NotificationsFeature>

  var body: some View {
    WithPerceptionTracking {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
          // 32 Bold — #28의 screenTitle 토큰이 develop에 들어오면 교체
          Text("알림")
            .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 32, relativeTo: .largeTitle))
            .foregroundStyle(WePLiColor.textPrimary)
            .padding(.horizontal, 20)
            .padding(.top, 2)
            .padding(.bottom, 14)
            .accessibilityAddTraits(.isHeader)

          if self.store.permission.showsPrompt {
            NotificationPermissionCard { self.store.send(.enableButtonTapped) }
              .padding(.horizontal, 16)
              .padding(.bottom, 8)
          }

          if self.store.isLoading {
            ProgressView()
              .tint(WePLiColor.textTertiary)
              .frame(maxWidth: .infinity)
              .padding(.top, 60)
          } else if self.store.loadFailed {
            // 원본에 오류 화면이 없어 임시 문구 — 디자인 확인 필요
            Text("알림을 불러오지 못했어요")
              .wepliFont(.callout, weight: .semibold)
              .foregroundStyle(WePLiColor.textPrimary)
              .frame(maxWidth: .infinity)
              .padding(.top, 60)
          } else if self.store.notifications.isEmpty {
            // UI-10f 「알림 없음」
            VStack(spacing: 8) {
              Text("새 알림이 없어요")
                .wepliFont(.title3)
                .foregroundStyle(WePLiColor.textPrimary)
              Text("릴레이에 참여하면 마감과 순위 소식을 알려드려요.")
                .wepliFont(.subheadline)
                .foregroundStyle(WePLiColor.textTertiary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
            .padding(.horizontal, 32)
          } else {
            self.section(.today, topPadding: 18)
            self.section(.thisWeek, topPadding: 22)
          }
        }
        .padding(.bottom, 24)
      }
      .safeAreaInset(edge: .top, spacing: 0) { self.topBar }
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private var topBar: some View {
    HStack {
      WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") {
        self.store.send(.backButtonTapped)
      }
      Spacer()
      Button("모두 읽음") { self.store.send(.markAllReadButtonTapped) }
        .wepliFont(.callout, weight: .medium)
        .foregroundStyle(WePLiColor.accent)
        .padding(10)
        .disabled(self.store.unreadCount == 0)
    }
    .padding(.leading, 16)
    .padding(.trailing, 12)
    .frame(height: 48)
    .background(WePLiColor.background)
  }

  @ViewBuilder
  private func section(_ group: AppNotification.Group, topPadding: CGFloat) -> some View {
    let items = self.store.state.items(in: group)
    if !items.isEmpty {
      Text(group.title)
        .wepliFont(.subheadline, weight: .semibold)
        .foregroundStyle(WePLiColor.textQuaternary)
        .padding(.horizontal, 20)
        .padding(.top, topPadding)
        .padding(.bottom, 6)
        .accessibilityAddTraits(.isHeader)
      ForEach(items) { item in
        NotificationRow(notification: item) { self.store.send(.notificationTapped(item.id)) }
      }
    }
  }
}

#Preview {
  NavigationStack {
    NotificationsView(store: Store(initialState: NotificationsFeature.State()) { NotificationsFeature() })
  }
}
