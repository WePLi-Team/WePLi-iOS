import ComposableArchitecture
import SwiftUI

// REQ-001 — 탭마다 자기 내비게이션 스택을 갖고, 탭을 바꿔도 각 탭의 화면 상태를 유지한다.
// 탭 내용은 각 기능 이슈에서 채운다. 지금은 10f 빈 상태 규칙(이유 + 다음 할 일)의 자리 표시.

struct MainTabView: View {
  let store: StoreOf<MainTabFeature>

  var body: some View {
    WithPerceptionTracking {
      ZStack {
        ForEach(MainTabFeature.Tab.allCases, id: \.self) { tab in
          let isSelected = self.store.selectedTab == tab
          NavigationStack {
            self.root(for: tab)
          }
          .opacity(isSelected ? 1 : 0)
          .allowsHitTesting(isSelected)
          .accessibilityHidden(!isSelected)
        }
      }
      // 스크롤 콘텐츠는 탭 바 아래까지 그려지고, 마지막 줄은 탭 바에 가리지 않는다.
      .safeAreaInset(edge: .bottom, spacing: 0) {
        MainTabBar(selectedTab: self.store.selectedTab) { tab in
          self.store.send(.tabSelected(tab))
        }
      }
      .ignoresSafeArea(.keyboard)
      .background(WePLiColor.background.ignoresSafeArea())
    }
  }
}

extension MainTabView {
  @ViewBuilder
  private func root(for tab: MainTabFeature.Tab) -> some View {
    switch tab {
    case .relay:
      RelayListView(store: self.store.scope(state: \.relay, action: \.relay))
    case .my:
      MyView(store: self.store.scope(state: \.my, action: \.my))
    case .community:
      CommunityFeedView(store: self.store.scope(state: \.community, action: \.community))
    case .home, .search:
      TabPlaceholder(tab: tab)
        .navigationTitle(tab.title)
    }
  }
}

private struct TabPlaceholder: View {
  let tab: MainTabFeature.Tab

  var body: some View {
    WePLiEmptyState(
      systemImage: self.tab.systemImage,
      title: "\(self.tab.title) 화면을 준비하고 있어요",
      message: "곧 이 탭에서 만나요."
    )
    .background(WePLiColor.background)
  }
}

#Preview("iOS 26") {
  MainTabView(store: Store(initialState: MainTabFeature.State()) { MainTabFeature() })
}

#Preview("iOS 16") {
  MainTabView(store: Store(initialState: MainTabFeature.State()) { MainTabFeature() })
    .environment(\.wepliChrome, .material)
}
