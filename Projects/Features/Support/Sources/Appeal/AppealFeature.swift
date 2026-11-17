import ComposableArchitecture
import Foundation
import WePLiSharedModels

// REQ-073 · UI-11d · DEC-024 — 이의 신청. 사유 하나와 설명을 보내면 진행 상태로 바뀐다(되돌릴 수 없음)

@Reducer
public struct AppealFeature {
  @ObservableState
  public struct State: Equatable {
    public let target: AppealTarget
    public var draft = AppealDraft()
    public var isSending = false
    public var isSent = false
    public var toast: String?

    public init(target: AppealTarget) {
      self.target = target
    }
  }

  public enum Action: Equatable {
    case closeTapped
    case reasonSelected(AppealReason)
    case textChanged(String)
    case sendTapped
    case sent
    case sendFailed(alreadyAppealed: Bool)
    case toastDismissed
    case delegate(AppealDelegate)
  }

  @Dependency(\.appealClient)
  public var client

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .closeTapped:
        return .send(.delegate(.dismiss))
      case let .reasonSelected(reason):
        state.draft.reason = reason
        return .none
      case let .textChanged(text):
        state.draft.text = String(text.prefix(AppealDraft.textLimit))
        return .none
      case .sendTapped:
        guard state.draft.canSend, !state.isSending, !state.isSent, let reason = state.draft.reason else {
          return .none
        }
        state.isSending = true
        let target = state.target
        let text = state.draft.text
        return .run { send in
          do {
            try await self.client.submit(target, reason, text)
            await send(.sent)
          } catch {
            await send(.sendFailed(alreadyAppealed: (error as? AppealError) == .alreadyAppealed))
          }
        }
      case .sent:
        state.isSending = false
        state.isSent = true
        return .none
      case let .sendFailed(alreadyAppealed):
        state.isSending = false
        // 원본에 없는 문구 — 디자인 확인 필요
        state.toast = alreadyAppealed ? "이미 이의 신청한 내용이에요. 결과를 알려드릴게요" : "이의 신청을 보내지 못했어요. 다시 시도해 주세요"
        return .none
      case .toastDismissed:
        state.toast = nil
        return .none
      case .delegate:
        return .none
      }
    }
  }

  public init() {}
}

public enum AppealDelegate: Equatable {
  case dismiss
}
