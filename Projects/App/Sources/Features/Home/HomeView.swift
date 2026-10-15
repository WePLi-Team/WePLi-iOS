import ComposableArchitecture
import SwiftUI

// REQ-020 · UI-12a(DEC-008) — 통합 홈. 히어로(위로 상태 바까지) 위에 머리가 얹히고, 아래로 섹션이 36 간격으로 이어진다.
// 1단계: 히어로 · TOP 100 · 배너(#101). 나머지 섹션은 #102 · #103.

struct HomeView: View {
  @Perception.Bindable var store: StoreOf<HomeFeature>

  var body: some View {
    WithPerceptionTracking {
      ScrollView {
        if let feed = self.store.feed {
          VStack(spacing: 0) {
            HomeHeroPager(
              heroes: feed.heroes,
              now: self.store.now,
              page: Binding(get: { self.store.heroPage }, set: { self.store.send(.heroPageChanged($0)) }),
              onTap: { self.store.send(.heroTapped($0)) },
              onPlayAll: { self.store.send(.completedPlayAllTapped($0)) }
            )
            .overlay(alignment: .top) {
              HomeHeader(unread: feed.unreadNotifications) { self.store.send(.notificationsTapped) }
                .padding(.top, 58)
            }
            VStack(alignment: .leading, spacing: 36) {
              HomeChartSection(
                feed: feed,
                onSong: { self.store.send(.chartSongTapped($0)) },
                onMore: { self.store.send(.chartMoreTapped($0)) },
                onPlayAll: { self.store.send(.chartPlayAllTapped) }
              )
              HomeBannerSection(banners: feed.banners) { self.store.send(.bannerTapped($0)) }
            }
            .padding(.top, 24)
            .padding(.bottom, 120)
          }
        } else if self.store.loadFailed {
          // 원본에 오류 화면이 없어 임시 문구 — 디자인 확인 필요
          VStack(spacing: 12) {
            Text("홈을 불러오지 못했어요")
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
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .onAppear { self.store.send(.onAppear) }
      .onDisappear { self.store.send(.onDisappear) }
    }
  }
}

#Preview {
  NavigationStack {
    HomeView(store: Store(initialState: HomeFeature.State()) {
      HomeFeature()
    })
  }
}
