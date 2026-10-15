import ComposableArchitecture
import Foundation

// REQ-110 · UI-7a · DEC-004 — 공지 · 이벤트(push). 목록과 상세를 한 화면에서 오간다(원본).

@Reducer
struct NoticesFeature {
  @ObservableState
  struct State: Equatable {
    var tab: Notice.Kind = .notice
    var notices: [Notice]?
    var loadFailed = false
    /// 열어 본 글 — 상세에서 돌아오면 점이 사라진다
    var selectedID: Notice.ID?

    var list: [Notice] {
      self.notices?.list(for: self.tab) ?? []
    }

    var selected: Notice? {
      self.selectedID.flatMap { id in self.notices?.first { $0.id == id } }
    }
  }

  enum Action: Equatable {
    case onAppear
    case loaded([Notice])
    case loadFailed
    case retryButtonTapped
    case tabSelected(Notice.Kind)
    case noticeTapped(Notice.ID)
    case backButtonTapped
    case backToListTapped
    case delegate(NoticesDelegate)
  }

  @Dependency(\.noticesClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.notices == nil else { return .none }
        return self.load(&state)
      case let .loaded(notices):
        state.notices = notices
        return .none
      case .loadFailed:
        state.loadFailed = true
        return .none
      case .retryButtonTapped:
        return self.load(&state)
      case let .tabSelected(tab):
        state.tab = tab
        state.selectedID = nil
        return .none
      case let .noticeTapped(id):
        guard let index = state.notices?.firstIndex(where: { $0.id == id }) else { return .none }
        state.selectedID = id
        guard state.notices?[index].isUnread == true else { return .none }
        state.notices?[index].isUnread = false
        return .run { _ in await self.client.markRead(id) }
      case .backButtonTapped:
        // 상세면 목록으로, 목록이면 마이로
        guard state.selectedID == nil else {
          state.selectedID = nil
          return .none
        }
        return .send(.delegate(.dismiss))
      case .backToListTapped:
        state.selectedID = nil
        return .none
      case .delegate:
        return .none
      }
    }
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.loadFailed = false
    return .run { send in
      do {
        try await send(.loaded(self.client.fetch()))
      } catch {
        await send(.loadFailed)
      }
    }
  }
}

enum NoticesDelegate: Equatable {
  case dismiss
}
