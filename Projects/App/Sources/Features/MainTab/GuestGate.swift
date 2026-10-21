import ComposableArchitecture
import Foundation

// DEC-032 · UI-16d — 「먼저 둘러볼게요」로 들어온 손님은 둘러보기만 하고,
// 계정이 있어야 하는 동작(투표 · 추천 · 예측 · 글쓰기 · 댓글 · 좋아요 · 팔로우 · 릴레이 만들기)을 누르면 로그인을 요청한다.
// 탭 화면 · 탭 스택 reducer가 모두 navigation 안에 있어, 여기서 막으면 그 동작은 어디에도 닿지 않는다.

struct GuestGate<Base: Reducer<MainTabFeature.State, MainTabFeature.Action>>: Reducer {
  let base: Base

  func reduce(into state: inout MainTabFeature.State, action: MainTabFeature.Action) -> Effect<MainTabFeature.Action> {
    switch action {
    case .loginPromptDismissed:
      state.loginPrompt = nil
      return .none
    case .guestLoginTapped:
      state.loginPrompt = nil
      return .send(.delegate(.loginRequested))
    default:
      break
    }
    if state.isGuest, let reason = Self.reason(for: action) {
      state.loginPrompt = reason
      return .none
    }
    return self.base.reduce(into: &state, action: action)
  }

  /// 로그인이 필요한 동작이면 그 이유 — 탭 화면에서 바로 하는 동작
  static func reason(for action: MainTabFeature.Action) -> GuestPromptReason? {
    switch action {
    case .home(.predictionPredictTapped): return .prediction
    case .community(.delegate(.showCompose)): return .write
    case .community(.likeTapped): return .like
    case .relay(.delegate(.showCreateRelay)): return .createRelay
    default: break
    }
    guard let (_, element) = action.pathElement else { return nil }
    return Self.reason(for: element)
  }

  /// 탭 스택 화면에서 하는 동작
  private static func reason(for action: MainTabFeature.Path.Action) -> GuestPromptReason? {
    switch action {
    case .relayDetail(.delegate(.showVote)), .library(.delegate(.continueVoting)):
      .vote
    case .relayDetail(.delegate(.showRecommend)), .batonRelay(.acceptTapped), .dailySong(.pickTapped):
      .recommend
    case .topPrediction(.predictTapped):
      .prediction
    case .postDetail(.sendButtonTapped), .postDetail(.songReplyButtonTapped):
      .comment
    case .postDetail(.postLikeTapped), .postDetail(.commentLikeTapped), .friendProfile(.postLikeTapped),
         .songDetail(.likeButtonTapped):
      .like
    case .friendProfile(.followTapped):
      .follow
    default:
      nil
    }
  }
}

/// 로그인 요청 시트의 제목 — 원본에 시트가 없어 디자인 시스템 부품으로 채운다(DEC-032)
enum GuestPromptReason: String, Equatable, Identifiable {
  case vote
  case recommend
  case prediction
  case write
  case comment
  case like
  case follow
  case createRelay

  var id: String {
    self.rawValue
  }

  var title: String {
    switch self {
    case .vote: "투표하려면 로그인이 필요해요"
    case .recommend: "곡을 추천하려면 로그인이 필요해요"
    case .prediction: "1위를 예측하려면 로그인이 필요해요"
    case .write: "글을 쓰려면 로그인이 필요해요"
    case .comment: "댓글을 남기려면 로그인이 필요해요"
    case .like: "좋아요를 누르려면 로그인이 필요해요"
    case .follow: "팔로우하려면 로그인이 필요해요"
    case .createRelay: "릴레이를 만들려면 로그인이 필요해요"
    }
  }

  static let message = "Apple이나 Google 계정으로 바로 시작할 수 있어요. 투표와 추천이 실시간 순위에 반영돼요."
}
