import ComposableArchitecture
import Foundation

@Reducer
struct LoginFeature {
  @ObservableState
  struct State: Equatable {
    var isLoading: Bool = false
    var error: String?
  }

  enum Action {
    case appleLoginButtonTapped
    case googleLoginButtonTapped
    case loginResponse(Result<Void, Error>)
    case termsOfServiceTapped
    case privacyPolicyTapped
  }

  @Dependency(\.authClient)
  var authClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .appleLoginButtonTapped:
        state.isLoading = true
        state.error = nil
        return .run { send in
          do {
            try await authClient.signInWithApple()
            await send(.loginResponse(.success(())))
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
            await send(.loginResponse(.success(())))
          } catch {
            await send(.loginResponse(.failure(error)))
          }
        }

      case .loginResponse(.success):
        state.isLoading = false
        return .none

      case let .loginResponse(.failure(error)):
        state.isLoading = false
        state.error = error.localizedDescription
        return .none

      case .termsOfServiceTapped:
        return .none

      case .privacyPolicyTapped:
        return .none
      }
    }
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
      // TODO: Implement Apple Sign-In
      try await Task.sleep(nanoseconds: 1000000000)
    },
    signInWithGoogle: {
      // TODO: Implement Google Sign-In
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
