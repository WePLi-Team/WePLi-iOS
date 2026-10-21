import ComposableArchitecture
import Foundation

// UI-17c · DEC-024 · DEC-031 — 내 가려진 글(push). 커뮤니티 맨 위 7e 안내 카드에서 연다.
// 진행 상황을 보여주고 이의 신청(UI-11d) · 운영정책(UI-17b) · 삭제 중 고르게 한다.

@Reducer
struct HiddenPostFeature {
  @ObservableState
  struct State: Equatable {
    let post: HiddenPost
    var isDeleting = false
    var toast: String?
    @Presents var appeal: AppealFeature.State?
    @Presents var deleteDialog: ConfirmationDialogState<HiddenPostDeleteDialog>?

    init(post: HiddenPost) {
      self.post = post
    }
  }

  enum Action: Equatable {
    case backButtonTapped
    case appealTapped
    case appeal(PresentationAction<AppealFeature.Action>)
    case policyTapped
    case deleteTapped
    case deleteDialog(PresentationAction<HiddenPostDeleteDialog>)
    case deleted
    case deleteFailed
    case toastDismissed
    case delegate(HiddenPostDelegate)
  }

  @Dependency(\.hiddenPostClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .backButtonTapped:
        return .send(.delegate(.dismiss))
      case .appealTapped:
        state.appeal = AppealFeature.State(target: state.post.appealTarget)
        return .none
      case .appeal(.presented(.delegate(.dismiss))):
        state.appeal = nil
        return .none
      case .policyTapped:
        return .send(.delegate(.showPolicy))
      case .deleteTapped:
        // 원본에 확인 창이 없지만 되돌릴 수 없는 동작이라 확인을 받는다(문구 확인 필요)
        state.deleteDialog = ConfirmationDialogState(titleVisibility: .visible) {
          TextState("글을 삭제할까요?")
        } actions: {
          ButtonState(role: .destructive, action: .confirm) { TextState("글 삭제하기") }
          ButtonState(role: .cancel) { TextState("취소") }
        } message: {
          TextState("삭제하면 되돌릴 수 없고 이의 신청도 할 수 없어요.")
        }
        return .none
      case .deleteDialog(.presented(.confirm)):
        guard !state.isDeleting else { return .none }
        state.isDeleting = true
        let id = state.post.id
        return .run { send in
          do {
            try await self.client.delete(id)
            await send(.deleted)
          } catch {
            await send(.deleteFailed)
          }
        }
      case .deleted:
        state.isDeleting = false
        return .send(.delegate(.deleted(state.post.id)))
      case .deleteFailed:
        state.isDeleting = false
        // 원본에 없는 문구 — 디자인 확인 필요
        state.toast = "글을 삭제하지 못했어요"
        return .none
      case .toastDismissed:
        state.toast = nil
        return .none
      case .appeal, .deleteDialog, .delegate:
        return .none
      }
    }
    .ifLet(\.$appeal, action: \.appeal) { AppealFeature() }
    .ifLet(\.$deleteDialog, action: \.deleteDialog)
  }
}

enum HiddenPostDeleteDialog: Equatable {
  case confirm
}

enum HiddenPostDelegate: Equatable {
  case dismiss
  /// 운영정책(UI-17b)
  case showPolicy
  /// 삭제한 글 — 커뮤니티 안내 카드를 지우고 돌아간다
  case deleted(HiddenPost.ID)
}
