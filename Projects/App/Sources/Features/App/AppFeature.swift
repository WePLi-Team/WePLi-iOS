import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
  @ObservableState
  struct State: Equatable {
    var isLoggedIn: Bool = false
    var login: LoginFeature.State = .init()
    var main: MainFeature.State = .init()
  }

  enum Action {
    case login(LoginFeature.Action)
    case main(MainFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Scope(state: \.login, action: \.login) {
      LoginFeature()
    }

    Scope(state: \.main, action: \.main) {
      MainFeature()
    }

    Reduce { state, action in
      switch action {
      // 로그인 성공 시 메인 화면으로 전환
      case .login(.loginResponse(.success)):
        state.isLoggedIn = true
        return .none

      case .login:
        return .none

      case .main:
        return .none
      }
    }
  }
}
