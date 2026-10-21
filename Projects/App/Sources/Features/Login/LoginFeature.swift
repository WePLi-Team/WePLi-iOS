import ComposableArchitecture
import Foundation

@Reducer
struct LoginFeature {
  @ObservableState
  struct State: Equatable {
    var isLoading: Bool = false
    var error: String?
    /// 탈퇴 유예 · 재가입 제한(UI-17e) — 로그인 직후 계정 상태가 정상이 아니면 먼저 띄운다
    @Presents var accountGrace: AccountGraceFeature.State?
  }

  enum Action {
    case appleLoginButtonTapped
    case googleLoginButtonTapped
    case accountChecked(AccountStatus)
    case accountGrace(PresentationAction<AccountGraceFeature.Action>)
    case loginResponse(Result<Void, Error>)
    case termsOfServiceTapped
    case privacyPolicyTapped
    /// 「먼저 둘러볼게요」(UI-16d · DEC-032)
    case browseTapped
    case delegate(Delegate)
  }

  enum Delegate: Equatable {
    case didLogIn
    /// 로그인 없이 메인 탭으로 — 투표 · 추천 등을 누르면 그때 로그인을 요청한다
    case browseAsGuest
  }

  @Dependency(\.authClient)
  var authClient
  @Dependency(\.accountClient)
  var accountClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .accountChecked, .accountGrace:
        return self.account(&state, action)

      case .appleLoginButtonTapped:
        state.isLoading = true
        state.error = nil
        return .run { send in
          do {
            try await authClient.signInWithApple()
            await send(.accountChecked((try? self.accountClient.status()) ?? .active))
          } catch {
            await send(.loginResponse(.failure(error)))
          }
        }

      case .googleLoginButtonTapped:
        state.isLoading = true
        state.error = nil
        return .run { send in
          do {
            try await authClient.signInWithGoogle()
            await send(.accountChecked((try? self.accountClient.status()) ?? .active))
          } catch {
            await send(.loginResponse(.failure(error)))
          }
        }

      case .loginResponse(.success):
        state.isLoading = false
        return .send(.delegate(.didLogIn))

      case let .loginResponse(.failure(error)):
        state.isLoading = false
        state.error = error.localizedDescription
        return .none

      case .termsOfServiceTapped:
        return .none

      case .privacyPolicyTapped:
        return .none

      case .browseTapped:
        return .send(.delegate(.browseAsGuest))

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$accountGrace, action: \.accountGrace) {
      AccountGraceFeature()
    }
  }

  /// 로그인 직후 계정 상태(UI-17e) — 정상이면 로그인을 마치고, 아니면 17e를 띄운다
  private func account(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case .accountChecked(.active):
      return .send(.loginResponse(.success(())))
    case let .accountChecked(.pendingDeletion(pending)):
      state.isLoading = false
      state.accountGrace = AccountGraceFeature.State(mode: .pending(pending))
    case let .accountChecked(.rejoinBlocked(block)):
      state.isLoading = false
      state.accountGrace = AccountGraceFeature.State(mode: .blocked(block))
    case .accountGrace(.presented(.delegate(.restored))):
      state.accountGrace = nil
      return .send(.loginResponse(.success(())))
    case .accountGrace(.presented(.delegate(.signedOut))):
      state.accountGrace = nil
    default:
      break
    }
    return .none
  }
}

// MARK: - AuthClient Dependency

struct AuthClient {
  var signInWithApple: @Sendable () async throws -> Void
  var signInWithGoogle: @Sendable () async throws -> Void
}

extension AuthClient: DependencyKey {
  static let liveValue = AuthClient(
    signInWithApple: {
      // TODO(#14): Implement Apple Sign-In — 지금은 1초 뒤 성공(메인 탭 임시 진입, #104)
      try await Task.sleep(nanoseconds: 1000000000)
    },
    signInWithGoogle: {
      // TODO(#14): Implement Google Sign-In — 지금은 1초 뒤 성공(메인 탭 임시 진입, #104)
      try await Task.sleep(nanoseconds: 1000000000)
    }
  )

  static let testValue = AuthClient(
    signInWithApple: {},
    signInWithGoogle: {}
  )

  static let previewValue = AuthClient(
    signInWithApple: {
      try await Task.sleep(nanoseconds: 500000000)
    },
    signInWithGoogle: {
      try await Task.sleep(nanoseconds: 500000000)
    }
  )
}

extension DependencyValues {
  var authClient: AuthClient {
    get { self[AuthClient.self] }
    set { self[AuthClient.self] = newValue }
  }
}
