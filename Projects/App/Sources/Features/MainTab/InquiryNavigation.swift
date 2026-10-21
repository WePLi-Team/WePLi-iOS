import ComposableArchitecture
import Foundation

// UI-17a · UI-7b — 고객센터 · 내 문의 내역 → 문의 상세. 상세의 「추가로 문의하기」는 고객센터 문의 시트로,
// 「내 게시글 보기」는 게시글 상세로, 문의 취소는 목록에서 빼고 돌아간다.

struct InquiryNavigation: Reducer {
  typealias State = MainTabFeature.State
  typealias Action = MainTabFeature.Action
  typealias Path = MainTabFeature.Path

  @Dependency(\.continuousClock)
  var clock

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      guard let (source, action) = action.pathElement else { return .none }
      switch action {
      case let .helpCenter(.delegate(.showInquiry(inquiry))),
           let .inquiryHistory(.delegate(.showInquiry(inquiry))):
        state[stack: source.tab].append(.inquiryDetail(InquiryDetailFeature.State(inquiry: inquiry)))
      case .helpCenter(.delegate(.showHistory)):
        state[stack: source.tab].append(.inquiryHistory(InquiryHistoryFeature.State()))
      case let .inquiryDetail(.delegate(.showPost(postID))):
        state[stack: source.tab].append(.postDetail(PostDetailFeature.State(postID: postID)))
      case let .inquiryDetail(.delegate(.followUp(category))):
        return self.compose(category, from: source, &state)
      case .inquiryHistory(.delegate(.compose)):
        return self.compose(nil, from: source, &state)
      case let .inquiryDetail(.delegate(.cancelled(id))):
        state[stack: source.tab].pop(from: source.id)
        return Self.removeCancelled(id, in: source.tab, state)
      default:
        break
      }
      return .none
    }
  }

  /// 아래에 고객센터가 있으면 거기까지 돌아가 문의 시트를 열고, 없으면 고객센터를 열어 시트를 띄운다
  private func compose(_ category: InquiryCategory?, from source: PathSource, _ state: inout State) -> Effect<Action> {
    let stack = state[stack: source.tab]
    guard let helpID = stack.ids.last(where: { stack[id: $0, case: \.helpCenter] != nil }) else {
      var help = HelpCenterFeature.State()
      help.draft.category = category
      help.isComposing = true
      state[stack: source.tab].append(.helpCenter(help))
      return .none
    }
    state[stack: source.tab].pop(to: helpID)
    guard let category else {
      state[stack: source.tab][id: helpID, case: \.helpCenter]?.isComposing = true
      return .none
    }
    // 화면이 돌아가는 동안 시트를 띄우면 무시되므로 잠시 뒤에 띄운다
    let target = PathSource(tab: source.tab, id: helpID)
    return .run { send in
      try await self.clock.sleep(for: .milliseconds(450))
      await send(.path(target, .helpCenter(.followUpRequested(category))))
    }
  }

  /// 취소한 문의는 아래에 남은 고객센터 · 내 문의 내역에서도 뺀다
  private static func removeCancelled(_ id: Inquiry.ID, in tab: MainTabFeature.Tab, _ state: State) -> Effect<Action> {
    let stack = state[stack: tab]
    let sends: [Effect<Action>] = stack.ids.compactMap { elementID in
      let target = PathSource(tab: tab, id: elementID)
      if stack[id: elementID, case: \.helpCenter] != nil {
        return .send(.path(target, .helpCenter(.inquiryCancelled(id))))
      }
      if stack[id: elementID, case: \.inquiryHistory] != nil {
        return .send(.path(target, .inquiryHistory(.cancelled(id))))
      }
      return nil
    }
    return .merge(sends)
  }
}
