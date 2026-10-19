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
          VStack(spacing: 0) {
            // 재생 중이면 탭 바 위에 미니 플레이어(UI-4a 노트 02)
            MiniPlayerView(store: self.store.scope(state: \.player, action: \.player))
            MainTabBar(selectedTab: self.store.selectedTab) { tab in
              self.store.send(.tabSelected(tab))
            }
          }
        }
      }
      .ignoresSafeArea(.keyboard)
      .background(WePLiColor.background.ignoresSafeArea())
      .modifier(MainTabSheets(store: self.store))
      .modifier(MainTabCovers(store: self.store))
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
    case let .topPrediction(store): TopPredictionView(store: store)
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
    case let .exportedPlaylist(store): ExportedPlaylistView(store: store)
    case let .editProfile(store): EditProfileView(store: store)
    case let .library(store): LibraryView(store: store)
    case let .myPlaylist(store): MyPlaylistView(store: store)
    default: settingsDestination(store)
    }
  }

  /// 마이 설정 · 앱 정보 · 바통 릴레이 push 화면 — Xcode 16.2가 큰 switch 타입을 제때 못 맞춰 나눈다
  @ViewBuilder
  private static func settingsDestination(_ store: StoreOf<MainTabFeature.Path>) -> some View {
    switch store.case {
    case let .notificationSettings(store): NotificationSettingsView(store: store)
    case let .musicServices(store): MusicServicesView(store: store)
    case let .notices(store): NoticesView(store: store)
    case let .appInfo(store): AppInfoView(store: store)
    case let .helpCenter(store): HelpCenterView(store: store)
    case let .batonRelay(store): BatonRelayView(store: store)
    case let .liveTrend(store): LiveTrendView(store: store)
    case let .dailySong(store): DailySongView(store: store)
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

/// 탭 위에 뜨는 시트 — Xcode 16.2가 한 식으로는 타입을 제때 못 맞춰 body에서 나눈다
private struct MainTabSheets: ViewModifier {
  @Perception.Bindable var store: StoreOf<MainTabFeature>

  func body(content: Content) -> some View {
    WithPerceptionTracking {
      content
        .sheet(item: self.$store.scope(state: \.compose, action: \.compose)) { composeStore in
          ComposePostView(store: composeStore)
            .wepliSheetStyle(detents: [.large])
        }
        .sheet(item: self.$store.scope(state: \.createRelay, action: \.createRelay)) { createStore in
          CreateRelayView(store: createStore)
            .wepliSheetStyle(detents: [.large])
        }
        .sheet(item: self.$store.scope(state: \.exportFlow, action: \.exportFlow)) { exportStore in
          ExportFlowView(store: exportStore)
            .wepliSheetStyle(detents: [.large])
        }
        .sheet(item: self.$store.scope(state: \.liveExport, action: \.liveExport)) { liveStore in
          LiveExportView(store: liveStore)
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
    }
  }
}

/// 탭 위에 뜨는 전체 화면
private struct MainTabCovers: ViewModifier {
  @Perception.Bindable var store: StoreOf<MainTabFeature>

  func body(content: Content) -> some View {
    WithPerceptionTracking {
      content
        .fullScreenCover(item: self.$store.scope(state: \.businessCard, action: \.businessCard)) { cardStore in
          BusinessCardFlowView(store: cardStore)
        }
        .fullScreenCover(item: self.$store.scope(state: \.serviceGuide, action: \.serviceGuide)) { guideStore in
          ServiceGuideView(store: guideStore)
        }
        .fullScreenCover(item: self.$store.scope(state: \.listeningShare, action: \.listeningShare)) { shareStore in
          ListeningShareView(store: shareStore)
        }
        .fullScreenCover(item: self.$store.scope(state: \.songShare, action: \.songShare)) { shareStore in
          SongShareView(store: shareStore)
        }
        .fullScreenCover(isPresented: Binding(
          get: { self.store.player.isExpanded },
          set: { self.store.send(.player(.expandedChanged($0))) }
        )) {
          NowPlayingView(store: self.store.scope(state: \.player, action: \.player))
        }
    }
  }
}
