import ComposableArchitecture
import Foundation

// UI-17b · DEC-027 · DEC-031 — 커뮤니티 운영정책. 7d 이용 제한 · 7e 가려진 글 · 7g 앱 정보에서 연다.
// 지금 내 단계만 라벤더로 보이고, 이용 제한 중이면 이의 신청(UI-11d)을 연다.

@Reducer
struct CommunityPolicyFeature {
  @ObservableState
  struct State: Equatable {
    var standing: CommunityStanding?
    @Presents var appeal: AppealFeature.State?

    init(standing: CommunityStanding? = nil) {
      self.standing = standing
    }
  }

  enum Action: Equatable {
    case onAppear
    case standingLoaded(CommunityStanding)
    case backButtonTapped
    case appealTapped
    case appeal(PresentationAction<AppealFeature.Action>)
    case delegate(CommunityPolicyDelegate)
  }

  @Dependency(\.communityPolicyClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.standing == nil else { return .none }
        return .run { send in
          // 못 받으면 단계 표시 없이 정책만 보인다
          let standing = await (try? self.client.standing()) ?? .clean
          await send(.standingLoaded(standing))
        }
      case let .standingLoaded(standing):
        state.standing = standing
        return .none
      case .backButtonTapped:
        return .send(.delegate(.dismiss))
      case .appealTapped:
        guard let target = state.standing?.appealTarget else { return .none }
        state.appeal = AppealFeature.State(target: target)
        return .none
      case .appeal(.presented(.delegate(.dismiss))):
        state.appeal = nil
        return .none
      case .appeal, .delegate:
        return .none
      }
    }
    .ifLet(\.$appeal, action: \.appeal) { AppealFeature() }
  }
}

enum CommunityPolicyDelegate: Equatable {
  case dismiss
}
