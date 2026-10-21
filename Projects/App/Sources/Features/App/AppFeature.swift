import ComposableArchitecture
import Foundation

// 앱 루트 — 로그인 화면과 메인 탭을 오간다. 탈퇴 신청 뒤 로그아웃하면 로그인 화면으로 돌아온다.
// 로그인은 아직 임시(#104): 버튼을 누르면 성공으로 보고 메인 탭으로 들어간다. 실제 연동은 #14.

@Reducer
struct AppFeature {
  @ObservableState
  enum State: Equatable {
    case login(LoginFeature.State)
    case mainTab(MainTabFeature.State)

    init() {
      self = .login(LoginFeature.State())
    }
  }

  enum Action {
    case login(LoginFeature.Action)
    case mainTab(MainTabFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .login(.delegate(.didLogIn)):
        state = .mainTab(MainTabFeature.State())
        return .none

      case .mainTab(.delegate(.signedOut)):
        // 탈퇴 신청 뒤 로그아웃(UI-7c) — 로그인 화면으로 돌아간다
        state = .login(LoginFeature.State())
        return .none

      case .login, .mainTab:
        return .none
      }
    }
    .ifCaseLet(\.login, action: \.login) {
      LoginFeature()
    }
    .ifCaseLet(\.mainTab, action: \.mainTab) {
      MainTabFeature()
    }
  }
}
