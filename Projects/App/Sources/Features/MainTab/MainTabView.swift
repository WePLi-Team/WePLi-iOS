import ComposableArchitecture
import SwiftUI

// REQ-001 — 탭마다 자기 내비게이션 스택을 갖고, 탭을 바꿔도 각 탭의 화면 상태를 유지한다.
// 탭 내용은 각 기능 이슈에서 채운다. 지금은 10f 빈 상태 규칙(이유 + 다음 할 일)의 자리 표시.

struct MainTabView: View {
  @Perception.Bindable var store: StoreOf<MainTabFeature>

  @Environment(\.wepliChrome)
  private var chrome

  var body: some View {
    WithPerceptionTracking {
      ZStack {
        ForEach(MainTabFeature.Tab.allCases, id: \.self) { tab in
          let isSelected = self.store.selectedTab == tab
          self.stack(for: tab)
            .opacity(isSelected ? 1 : 0)
            .allowsHitTesting(isSelected)
            .accessibilityHidden(!isSelected)
        }
      }
      // 스크롤 콘텐츠는 탭 바 아래까지 그려지고, 마지막 줄은 탭 바에 가리지 않는다.
      .safeAreaInset(edge: .bottom, spacing: 0) {
        // iOS 26 검색 탭에서는 다른 탭이 홈 버튼 하나로 접히고 검색 화면이 하단 바를 그린다(UI-4c).
        if !(self.chrome == .glass && self.store.selectedTab == .search), !self.store.hidesTabBar {
          MainTabBar(selectedTab: self.store.selectedTab) { tab in
            self.store.send(.tabSelected(tab))
          }
        }
      }
      .ignoresSafeArea(.keyboard)
      .background(WePLiColor.background.ignoresSafeArea())
      .sheet(item: self.$store.scope(state: \.compose, action: \.compose)) { composeStore in
        ComposePostView(store: composeStore)
          .wepliSheetStyle(detents: [.large])
      }
      .sheet(item: self.$store.scope(state: \.createRelay, action: \.createRelay)) { createStore in
        CreateRelayView(store: createStore)
          .wepliSheetStyle(detents: [.large])
      }
      .sheet(item: self.$store.scope(state: \.replySongPicker, action: \.replySongPicker)) { pickerStore in
        SongPickerView(store: pickerStore)
          .wepliSheetStyle(detents: [.large])
      }
      .sheet(item: self.$store.scope(state: \.songMenu, action: \.songMenu)) { menuStore in
        SongMenuView(store: menuStore)
          .wepliSheetStyle(detents: [.height(SongMenuView.height)])
      }
      .fullScreenCover(item: self.$store.scope(state: \.businessCard, action: \.businessCard)) { cardStore in
        BusinessCardFlowView(store: cardStore)
      }
      .fullScreenCover(item: self.$store.scope(state: \.songShare, action: \.songShare)) { shareStore in
        SongShareView(store: shareStore)
      }
    }
  }
}

extension MainTabView {
  /// 탭마다 NavigationStack — 릴레이 탭은 StackState 경로와 묶는다(DEC-007)
  @ViewBuilder
  private func stack(for tab: MainTabFeature.Tab) -> some View {
    switch tab {
    case .relay: self.tabStack(.relay, state: \.relayPath, action: \.relayPath)
    case .community: self.tabStack(.community, state: \.communityPath, action: \.communityPath)
    case .my: self.tabStack(.my, state: \.myPath, action: \.myPath)
    case .search: self.tabStack(.search, state: \.searchPath, action: \.searchPath)
    case .home: self.tabStack(.home, state: \.homePath, action: \.homePath)
    }
  }

  private func tabStack(
    _ tab: MainTabFeature.Tab,
    state: WritableKeyPath<MainTabFeature.State, StackState<MainTabFeature.Path.State>>,
    action: CaseKeyPath<MainTabFeature.Action, StackActionOf<MainTabFeature.Path>>
  ) -> some View {
    NavigationStack(path: self.$store.scope(state: state, action: action)) {
      self.root(for: tab)
    } destination: { store in
      Self.destination(store)
    }
  }

  /// 탭 공용 push 화면 — 음악 · 게시글 화면
  @ViewBuilder
  private static func destination(_ store: StoreOf<MainTabFeature.Path>) -> some View {
    switch store.case {
    case let .songDetail(store): SongDetailView(store: store)
    case let .artist(store): ArtistView(store: store)
    case let .playlistDetail(store): PlaylistDetailView(store: store)
    case let .postDetail(store): PostDetailView(store: store)
    case let .relayDetail(store): RelayDetailView(store: store)
    case let .vote(store): CardVoteView(store: store)
    case let .worldCup(store): SongWorldCupView(store: store)
    default: accountDestination(store)
    }
  }

  /// 탭 공용 push 화면 — 알림 · 내 정보 · 보관함 · 내 플리
  @ViewBuilder
  private static func accountDestination(_ store: StoreOf<MainTabFeature.Path>) -> some View {
    switch store.case {
    case let .notifications(store): NotificationsView(store: store)
    case let .myRecommendation(store): MyRecommendationView(store: store)
    case let .completedPlaylist(store): CompletedPlaylistView(store: store)
    case let .editProfile(store): EditProfileView(store: store)
    case let .library(store): LibraryView(store: store)
    case let .notificationSettings(store): NotificationSettingsView(store: store)
    case let .myPlaylist(store): MyPlaylistView(store: store)
    default: EmptyView()
    }
  }

  @ViewBuilder
  private func root(for tab: MainTabFeature.Tab) -> some View {
    switch tab {
    case .relay:
      RelayListView(store: self.store.scope(state: \.relay, action: \.relay))
    case .my:
      MyView(store: self.store.scope(state: \.my, action: \.my))
    case .community:
      CommunityFeedView(store: self.store.scope(state: \.community, action: \.community))
    case .search:
      SearchView(store: self.store.scope(state: \.search, action: \.search))
    case .home:
      HomeView(store: self.store.scope(state: \.home, action: \.home))
    }
  }
}

#Preview("iOS 26") {
  MainTabView(store: Store(initialState: MainTabFeature.State()) { MainTabFeature() })
}

#Preview("iOS 16") {
  MainTabView(store: Store(initialState: MainTabFeature.State()) { MainTabFeature() })
    .environment(\.wepliChrome, .material)
}
