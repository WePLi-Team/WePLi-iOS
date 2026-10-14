import ComposableArchitecture
import Foundation

// DEC-007 — 탭마다 StackState를 따로 두고, push 화면 목록(Path)은 모든 탭이 같이 쓴다.
// 상세 화면(곡 · 아티스트 · 플리 · 게시글 …)이 어느 탭에서 열렸든 같은 규칙으로 다음 화면을 잇는다.

/// 탭 스택 안의 한 화면 — 탭과 화면 id
struct PathSource: Equatable, Sendable {
  let tab: MainTabFeature.Tab
  let id: StackElementID
}

extension MainTabFeature.State {
  /// 탭의 스택. 홈은 아직 스택이 없어 검색 스택을 쓰지 않도록 부르는 쪽에서 막는다.
  subscript(stack tab: MainTabFeature.Tab) -> StackState<MainTabFeature.Path.State> {
    get {
      switch tab {
      case .relay: self.relayPath
      case .community: self.communityPath
      case .my: self.myPath
      case .search, .home: self.searchPath
      }
    }
    set {
      switch tab {
      case .relay: self.relayPath = newValue
      case .community: self.communityPath = newValue
      case .my: self.myPath = newValue
      case .search, .home: self.searchPath = newValue
      }
    }
  }
}

extension MainTabFeature.Action {
  /// 탭 스택의 화면에서 온 액션
  var pathElement: (source: PathSource, action: MainTabFeature.Path.Action)? {
    switch self {
    case let .relayPath(.element(id, action)): (PathSource(tab: .relay, id: id), action)
    case let .communityPath(.element(id, action)): (PathSource(tab: .community, id: id), action)
    case let .myPath(.element(id, action)): (PathSource(tab: .my, id: id), action)
    case let .searchPath(.element(id, action)): (PathSource(tab: .search, id: id), action)
    default: nil
    }
  }

  /// 탭 스택의 한 화면에 보낼 액션
  static func path(_ source: PathSource, _ action: MainTabFeature.Path.Action) -> Self {
    switch source.tab {
    case .relay: .relayPath(.element(id: source.id, action: action))
    case .community: .communityPath(.element(id: source.id, action: action))
    case .my: .myPath(.element(id: source.id, action: action))
    case .search, .home: .searchPath(.element(id: source.id, action: action))
    }
  }
}
