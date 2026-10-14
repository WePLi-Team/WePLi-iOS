import ComposableArchitecture
import Foundation

// REQ-030 · REQ-031 · REQ-033 — 릴레이 탭 이동: 릴레이 상세 → 카드 투표

struct RelayNavigation: Reducer {
  typealias State = MainTabFeature.State
  typealias Action = MainTabFeature.Action

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .relay(.delegate(.showRelay(id))):
        state.relayPath.append(.detail(RelayDetailFeature.State(relayID: id)))
        return .none

      case let .relayPath(.element(id: elementID, action: .detail(.delegate(.showVote(relayID))))):
        // 상세 제목은 줄바꿈이 있어 투표 화면 주제에서는 한 줄로 보인다
        let title = state.relayPath[id: elementID, case: \.detail]?.detail?.title ?? ""
        let topic = title.replacingOccurrences(of: "\n", with: " ")
        state.relayPath.append(.vote(CardVoteFeature.State(relayID: relayID, topic: topic)))
        return .none

      case let .relayPath(.element(id: elementID, action: .detail(.delegate(.dismiss)))),
           let .relayPath(.element(id: elementID, action: .vote(.delegate(.dismiss)))):
        state.relayPath.pop(from: elementID)
        return .none

      default:
        return .none
      }
    }
  }
}
