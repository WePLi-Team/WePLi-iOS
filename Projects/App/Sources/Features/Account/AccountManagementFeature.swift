import ComposableArchitecture
import Foundation

// REQ-013 · UI-7c — 계정 관리(push). 로그인 정보 · 차단한 사용자 · 회원 탈퇴를 한곳에 모았다(7c 노트 01).
// 탈퇴는 사유 → 확인 → 완료 3단계(노트 02). 완료 「확인」은 로그아웃해 로그인 화면으로 돌아간다.

@Reducer
struct AccountManagementFeature {
  @ObservableState
  struct State: Equatable {
    var step: AccountStep = .manage
    /// 내 정보 수정 「회원 탈퇴」로 열면 사유 단계부터 — 뒤로 가면 이 단계에서 화면을 닫는다
    var entry: AccountStep = .manage
    var account: AccountInfo?
    var blocked: [BlockedUser] = []
    var reasons: Set<WithdrawReason> = []
    var hasAgreed = false
    var isWithdrawing = false
    var deletesAt: Date?
    var toast: String?

    init(entry: AccountStep = .manage) {
      self.entry = entry
      self.step = entry
    }
  }

  enum Action: Equatable {
    case onAppear
    case loaded(AccountInfo, [BlockedUser])
    case backButtonTapped
    case linkGoogleTapped
    case googleLinked(String)
    case unblockTapped(BlockedUser.ID)
    case unblockFailed(BlockedUser, Int)
    case withdrawTapped
    case reasonToggled(WithdrawReason)
    case nextTapped
    case agreeToggled
    case confirmTapped
    case withdrawn(Date)
    case withdrawFailed
    case keepUsingTapped
    case doneTapped
    case toastDismissed
    case delegate(AccountManagementDelegate)
  }

  @Dependency(\.accountClient)
  var client
  @Dependency(\.friendProfileClient)
  var friendClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.account == nil else { return .none }
        return .run { send in
          let account = try await self.client.account()
          let blocked = await (try? self.client.blockedUsers()) ?? []
          await send(.loaded(account, blocked))
        }
      case let .loaded(account, blocked):
        state.account = account
        state.blocked = blocked
        return .none
      case .backButtonTapped:
        return self.back(&state)
      case .linkGoogleTapped, .googleLinked, .unblockTapped, .unblockFailed:
        return self.manage(&state, action)
      case .withdrawTapped, .reasonToggled, .nextTapped, .agreeToggled, .keepUsingTapped:
        self.steps(&state, action)
        return .none
      case .confirmTapped, .withdrawn, .withdrawFailed, .doneTapped:
        return self.withdraw(&state, action)
      case .toastDismissed:
        state.toast = nil
        return .none
      case .delegate:
        return .none
      }
    }
  }

  /// 뒤로 — 한 단계씩, 완료에서는 계정 관리로(원본). 연 단계에서는 화면을 닫는다
  private func back(_ state: inout State) -> Effect<Action> {
    if state.step == .done {
      return .send(.doneTapped)
    }
    guard state.step > state.entry, let previous = AccountStep(rawValue: state.step.rawValue - 1) else {
      return .send(.delegate(.dismiss))
    }
    state.step = previous
    return .none
  }

  private func manage(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case .linkGoogleTapped:
      return .run { send in
        if let email = try? await self.client.linkGoogle() {
          await send(.googleLinked(email))
        }
      }
    case let .googleLinked(email):
      state.account?.linked[.google] = email
    case let .unblockTapped(id):
      // 원본: 확인 없이 바로 줄을 뺀다. 실패하면 되돌린다
      guard let index = state.blocked.firstIndex(where: { $0.id == id }) else { return .none }
      let user = state.blocked.remove(at: index)
      return .run { send in
        do {
          try await self.friendClient.setBlocked(user.id, false)
        } catch {
          await send(.unblockFailed(user, index))
        }
      }
    case let .unblockFailed(user, index):
      state.blocked.insert(user, at: min(index, state.blocked.count))
      // 원본에 없는 문구 — 디자인 확인 필요
      state.toast = "차단을 풀지 못했어요. 다시 시도해 주세요"
    default:
      break
    }
    return .none
  }

  private func steps(_ state: inout State, _ action: Action) {
    switch action {
    case .withdrawTapped:
      state.step = .reason
    case let .reasonToggled(reason):
      if state.reasons.contains(reason) {
        state.reasons.remove(reason)
      } else {
        state.reasons.insert(reason)
      }
    case .nextTapped:
      guard !state.reasons.isEmpty else { return }
      state.step = .confirm
    case .agreeToggled:
      state.hasAgreed.toggle()
    case .keepUsingTapped:
      // 「계속 이용할래요」 — 처음으로 돌아가고 고른 사유 · 동의를 지운다(원본)
      state.reasons = []
      state.hasAgreed = false
      state.step = .manage
    default:
      break
    }
  }

  private func withdraw(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case .confirmTapped:
      guard state.hasAgreed, !state.isWithdrawing else { return .none }
      state.isWithdrawing = true
      let reasons = state.reasons
      return .run { send in
        do {
          try await send(.withdrawn(self.client.withdraw(reasons)))
        } catch {
          await send(.withdrawFailed)
        }
      }
    case let .withdrawn(deletesAt):
      state.isWithdrawing = false
      state.deletesAt = deletesAt
      state.step = .done
    case .withdrawFailed:
      state.isWithdrawing = false
      // 원본에 없는 문구 — 디자인 확인 필요
      state.toast = "탈퇴를 신청하지 못했어요. 다시 시도해 주세요"
    case .doneTapped:
      return .run { send in
        await self.client.signOut()
        await send(.delegate(.signedOut))
      }
    default:
      break
    }
    return .none
  }
}

enum AccountManagementDelegate: Equatable {
  case dismiss
  /// 탈퇴 신청 뒤 로그아웃 — 앱 루트가 로그인 화면으로 돌아간다
  case signedOut
}
