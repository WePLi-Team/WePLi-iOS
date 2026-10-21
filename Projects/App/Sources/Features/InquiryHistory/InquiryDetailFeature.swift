import ComposableArchitecture
import Foundation

// UI-17a — 문의 답변 · 이의 신청 결과 상세(push).
// 답변: 「답변이 도움이 됐나요?」(먼저 반영 · 실패 시 되돌림) · 추가로 문의하기(7b 문의 시트)
// 이의 신청 결과: 결과 · 진행 기록 · 내 게시글 보기 / 답변 대기: 문의 취소(확인 창)

@Reducer
struct InquiryDetailFeature {
  @ObservableState
  struct State: Equatable {
    var inquiry: Inquiry
    var isCancelling = false
    var toast: String?
    @Presents var cancelDialog: ConfirmationDialogState<InquiryCancelDialog>?

    /// 「문의 답변」 · 「이의 신청 결과」
    var title: String {
      switch self.inquiry.kind {
      case .question: "문의 답변"
      case .appealResult: "이의 신청 결과"
      }
    }
  }

  enum Action: Equatable {
    case backButtonTapped
    case helpfulTapped(Bool)
    case rateFailed(previous: Bool?)
    case followUpTapped
    case showPostTapped
    case cancelTapped
    case cancelDialog(PresentationAction<InquiryCancelDialog>)
    case cancelled
    case cancelFailed
    case toastDismissed
    case delegate(InquiryDetailDelegate)
  }

  @Dependency(\.helpCenterClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .backButtonTapped:
        return .send(.delegate(.dismiss))
      case let .helpfulTapped(isHelpful):
        guard state.inquiry.isHelpful != isHelpful else { return .none }
        let previous = state.inquiry.isHelpful
        state.inquiry.isHelpful = isHelpful
        let id = state.inquiry.id
        return .run { send in
          do {
            try await self.client.rateAnswer(id, isHelpful)
          } catch {
            await send(.rateFailed(previous: previous))
          }
        }
      case let .rateFailed(previous):
        state.inquiry.isHelpful = previous
        state.toast = InquiryText.failedToast
        return .none
      case .followUpTapped:
        guard case let .question(category, _) = state.inquiry.kind else { return .none }
        return .send(.delegate(.followUp(category)))
      case .showPostTapped:
        guard case let .appealResult(result) = state.inquiry.kind, let postID = result.postID else { return .none }
        return .send(.delegate(.showPost(postID)))
      case .cancelTapped, .cancelDialog, .cancelled, .cancelFailed:
        return self.cancel(&state, action)
      case .toastDismissed:
        state.toast = nil
        return .none
      case .delegate:
        return .none
      }
    }
    .ifLet(\.$cancelDialog, action: \.cancelDialog)
  }

  private func cancel(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case .cancelTapped:
      guard state.inquiry.status == .waiting, !state.isCancelling else { return .none }
      // 원본에 확인 창이 없어 채운 문구 — 디자인 확인 필요
      state.cancelDialog = ConfirmationDialogState(titleVisibility: .visible) {
        TextState("문의를 취소할까요?")
      } actions: {
        ButtonState(role: .destructive, action: .confirm) { TextState("문의 취소") }
        ButtonState(role: .cancel) { TextState("닫기") }
      } message: {
        TextState("보낸 내용은 지워지고 답변을 받을 수 없어요.")
      }
      return .none
    case .cancelDialog(.presented(.confirm)):
      state.isCancelling = true
      let id = state.inquiry.id
      return .run { send in
        do {
          try await self.client.cancel(id)
          await send(.cancelled)
        } catch {
          await send(.cancelFailed)
        }
      }
    case .cancelled:
      state.isCancelling = false
      return .send(.delegate(.cancelled(state.inquiry.id)))
    case .cancelFailed:
      state.isCancelling = false
      state.toast = InquiryText.failedToast
      return .none
    default:
      return .none
    }
  }
}

enum InquiryCancelDialog: Equatable {
  case confirm
}

enum InquiryDetailDelegate: Equatable {
  case dismiss
  /// 추가로 문의하기 — 같은 유형으로 7b 문의 시트를 연다
  case followUp(InquiryCategory)
  /// 이의 신청이 받아들여져 다시 보이는 내 게시글
  case showPost(String)
  /// 취소한 문의 — 목록에서 빼고 돌아간다
  case cancelled(Inquiry.ID)
}
