import ComposableArchitecture
import Foundation

// REQ-001 · UI-12d — 메인 탭: 홈 · 릴레이 · 커뮤니티 · 마이 + 검색

@Reducer
struct MainTabFeature {
  enum Tab: String, CaseIterable, Equatable {
    case home
    case relay
    case community
    case my
    case search

    /// iOS 26 글래스 캡슐에 들어가는 탭(검색은 따로 떠 있는 원형 버튼)
    static let capsuleTabs: [Tab] = [.home, .relay, .community, .my]

    var title: String {
      switch self {
      case .home: "홈"
      case .relay: "릴레이"
      case .community: "커뮤니티"
      case .my: "마이"
      case .search: "검색"
      }
    }

    /// Figma 아이콘(home · stars · message · profile · search)에 가까운 SF Symbol
    var systemImage: String {
      switch self {
      case .home: "house"
      case .relay: "sparkles"
      case .community: "bubble.left"
      case .my: "person"
      case .search: "magnifyingglass"
      }
    }
  }

  @ObservableState
  struct State: Equatable {
    var selectedTab: Tab = .home
  }

  enum Action: Equatable {
    case tabSelected(Tab)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .tabSelected(tab):
        state.selectedTab = tab
        return .none
      }
    }
  }
}
