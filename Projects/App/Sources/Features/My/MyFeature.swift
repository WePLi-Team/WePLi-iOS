import ComposableArchitecture
import Foundation

// REQ-070 · UI-1e — 마이 탭

@Reducer
struct MyFeature {
  @ObservableState
  struct State: Equatable {
    var profile: MyProfile?
    var appVersion = ""
    var isDeveloperModeEnabled = false
    var loadFailed = false

    var sections: [MyMenuSection] {
      MyMenuSection.allCases.filter {
        !$0.menus(isDeveloperModeEnabled: self.isDeveloperModeEnabled).isEmpty || $0 == .appInfo
      }
    }
  }

  enum Action: Equatable {
    case onAppear
    case profileLoaded(MyProfile)
    case profileFailed
    case businessCardButtonTapped
    case profileTapped
    case menuTapped(MyMenu)
    /// 「앱 버전」 → 앱 정보(UI-7g 노트 01)
    case appVersionTapped
    case logoutTapped
    case delegate(Delegate)
  }

  enum Delegate: Equatable {
    /// 내 명함 보기 · 만들기 (UI-11e · UI-2e)
    case showBusinessCard
    /// 내 정보 수정 (UI-3e)
    case editProfile
    case show(MyMenu)
    /// 앱 정보 · 약관(UI-7g)
    case showAppInfo
    case logout
  }

  @Dependency(\.myClient)
  var myClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.appVersion = self.myClient.appVersion()
        guard state.profile == nil else { return .none }
        state.loadFailed = false
        return .run { send in
          do {
            try await send(.profileLoaded(self.myClient.fetchProfile()))
          } catch {
            await send(.profileFailed)
          }
        }

      case let .profileLoaded(profile):
        state.profile = profile
        return .none

      case .profileFailed:
        state.loadFailed = true
        return .none

      case .businessCardButtonTapped:
        return .send(.delegate(.showBusinessCard))

      case .profileTapped:
        return .send(.delegate(.editProfile))

      case let .menuTapped(menu):
        return .send(.delegate(.show(menu)))

      case .appVersionTapped:
        return .send(.delegate(.showAppInfo))

      case .logoutTapped:
        return .send(.delegate(.logout))

      case .delegate:
        return .none
      }
    }
  }
}
