import ComposableArchitecture
import Foundation

// REQ-113 · UI-7f — 서비스 이용 가이드: 주제 열림 → 곡 추천 → 투표 → 완성 네 장

@Reducer
struct ServiceGuideFeature {
  @ObservableState
  struct State: Equatable {
    var page = 0

    var isLastPage: Bool {
      self.page >= ServiceGuidePage.all.count - 1
    }
  }

  enum Action: Equatable {
    case pageChanged(Int)
    case nextTapped
    case closeTapped
    case delegate(ServiceGuideDelegate)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .pageChanged(page):
        guard ServiceGuidePage.all.indices.contains(page) else { return .none }
        state.page = page
        return .none
      case .nextTapped:
        // 미결정 — 원본은 「시작하기」를 누르면 첫 장으로 돌아간다. 마지막 장에서는 닫는다.
        guard !state.isLastPage else { return .send(.delegate(.dismiss)) }
        state.page += 1
        return .none
      case .closeTapped:
        return .send(.delegate(.dismiss))
      case .delegate:
        return .none
      }
    }
  }
}

enum ServiceGuideDelegate: Equatable {
  case dismiss
}

struct ServiceGuidePage: Equatable, Identifiable {
  /// 「01」
  let id: String
  let title: String
  let body: String

  /// 원본(UI-7f) 네 장
  static let all = [
    ServiceGuidePage(
      id: "01",
      title: "주제가 열려요",
      body: "‘비 오는 날 듣는 노래’처럼 하나의 주제로 릴레이리스트가 열려요. 위플리가 열기도 하고, 내가 직접 열 수도 있어요."
    ),
    ServiceGuidePage(
      id: "02",
      title: "어울리는 곡을 추천해요",
      body: "주제에 맞는 곡을 검색해서 추천해요. 이미 추천된 곡이면 그 곡에 점수가 더해져요."
    ),
    ServiceGuidePage(
      id: "03",
      title: "투표로 순위를 정해요",
      body: "상위 10곡을 한 장씩 넘기며 ‘어울려요 / 별로예요’로 투표해요. 순위는 마감 전까지 계속 바뀌어요."
    ),
    ServiceGuidePage(
      id: "04",
      title: "플레이리스트가 완성돼요",
      body: "마감되면 순위대로 플레이리스트가 완성되고, 참여한 모두에게 알려드려요. 내 플리에 담아 들어보세요."
    ),
  ]
}
