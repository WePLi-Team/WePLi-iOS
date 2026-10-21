import ComposableArchitecture
import Foundation

// UI-17e · DEC-004 — 로그인 직후 계정 상태 화면(전체 화면, 내비게이션 바 없음).
// 탈퇴 유예: 14일 안에 다시 로그인하면 먼저 뜨고 「계정 되살리기」로 바로 돌아온다.
// 재가입 제한: 이용 제한 중에 탈퇴한 계정은 제한이 끝날 때까지 다시 가입할 수 없다.

@Reducer
struct AccountGraceFeature {
  @ObservableState
  struct State: Equatable {
    var mode: Mode
    var isRestoring = false
    var isRestored = false
    var toast: String?
    /// 고객센터(UI-7b) — 로그인 전이라 시트로 연다
    @Presents var helpCenter: HelpCenterFeature.State?
    /// 운영정책 — 17b 화면이 생기기 전까지 앱 정보(7g)의 「커뮤니티 운영정책」 본문을 시트로 연다
    @Presents var policy: AppInfoFeature.State?
  }

  enum Mode: Equatable {
    case pending(PendingDeletion)
    case blocked(RejoinBlock)
  }

  enum Action: Equatable {
    case restoreTapped
    case restored
    case restoreFailed
    case homeTapped
    case leaveTapped
    case policyTapped
    case helpTapped
    case toastDismissed
    case helpCenter(PresentationAction<HelpCenterFeature.Action>)
    case policy(PresentationAction<AppInfoFeature.Action>)
    case delegate(AccountGraceDelegate)
  }

  @Dependency(\.accountClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .restoreTapped:
        guard !state.isRestoring else { return .none }
        state.isRestoring = true
        return .run { send in
          do {
            try await self.client.restore()
            await send(.restored)
          } catch {
            await send(.restoreFailed)
          }
        }
      case .restored:
        state.isRestoring = false
        state.isRestored = true
        return .none
      case .restoreFailed:
        state.isRestoring = false
        // 원본에 없는 문구 — 디자인 확인 필요
        state.toast = "계정을 되살리지 못했어요. 다시 시도해 주세요"
        return .none
      case .homeTapped:
        return .send(.delegate(.restored))
      case .leaveTapped:
        // 원본에 동작이 없다 — 로그아웃하고 로그인 화면에 남는다
        return .run { send in
          await self.client.signOut()
          await send(.delegate(.signedOut))
        }
      case .policyTapped:
        var policy = AppInfoFeature.State()
        policy.document = AppDocument.all.first { $0.id == "policy" }
        state.policy = policy
        return .none
      case .policy(.presented(.backButtonTapped)):
        state.policy = nil
        return .none
      case .helpTapped:
        state.helpCenter = HelpCenterFeature.State()
        return .none
      case .helpCenter(.presented(.delegate(.dismiss))):
        state.helpCenter = nil
        return .none
      case .toastDismissed:
        state.toast = nil
        return .none
      case .helpCenter, .policy, .delegate:
        return .none
      }
    }
    .ifLet(\.$helpCenter, action: \.helpCenter) {
      HelpCenterFeature()
    }
    .ifLet(\.$policy, action: \.policy) {
      AppInfoFeature()
    }
  }
}

enum AccountGraceDelegate: Equatable {
  /// 되살린 뒤 「홈으로」 — 로그인을 마친다
  case restored
  case signedOut
}
