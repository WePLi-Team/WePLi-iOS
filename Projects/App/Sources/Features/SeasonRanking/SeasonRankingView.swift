import ComposableArchitecture
import SwiftUI

// UI-8f — 시즌 랭킹. 큰 제목 「랭킹」 → 밑줄 탭(큐레이터 · 호스트) → 탭 내용

struct SeasonRankingView: View {
  let store: StoreOf<SeasonRankingFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        HStack {
          WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") { self.store.send(.backButtonTapped) }
          Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            Text("랭킹")
              .wepliFont(.screenTitle)
              .foregroundStyle(WePLiColor.textPrimary)
              .padding(.horizontal, 20)
              .padding(.top, 2)
              .padding(.bottom, 12)
              .accessibilityAddTraits(.isHeader)
            WePLiUnderlineTabs(items: SeasonRankingTab.allCases, selected: self.store.tab, title: \.title) {
              self.store.send(.tabSelected($0))
            }
            .padding(.horizontal, 20)
            self.content()
          }
          .padding(.bottom, 60)
        }
      }
      .background(WePLiColor.background.ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
      .wepliToast(Binding(get: { self.store.toast }, set: {
        if $0 == nil {
          self.store.send(.toastDismissed)
        }
      }))
      .onAppear { self.store.send(.onAppear) }
    }
  }

  @ViewBuilder
  private func content() -> some View {
    if let ranking = self.store.ranking {
      switch self.store.tab {
      case .curator:
        SeasonCuratorContent(ranking: ranking, now: self.store.now)
      case .host:
        SeasonHostList(hosts: ranking.hosts) { self.store.send(.followTapped($0)) }
      }
    } else if self.store.loadFailed {
      VStack(spacing: 12) {
        // 원본에 없는 문구 — 디자인 확인 필요
        Text("랭킹을 불러오지 못했어요").wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
        Button("다시 시도") { self.store.send(.retryButtonTapped) }
          .wepliFont(.subheadline, weight: .semibold)
          .foregroundStyle(WePLiColor.accent)
      }
      .frame(maxWidth: .infinity, minHeight: 300)
    } else {
      ProgressView().tint(WePLiColor.textTertiary).frame(maxWidth: .infinity, minHeight: 300)
    }
  }
}

#Preview {
  NavigationStack {
    SeasonRankingView(store: Store(initialState: SeasonRankingFeature.State()) { SeasonRankingFeature() })
  }
}
