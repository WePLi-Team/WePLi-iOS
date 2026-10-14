import ComposableArchitecture
import Foundation

// REQ-012 · REQ-070 · REQ-075 · REQ-077 · REQ-082 — 마이 탭 이동: 내 정보 수정 · 보관함 · 투표 · 알림 설정 · 명함 만들기

struct MyNavigation: Reducer {
  typealias State = MainTabFeature.State
  typealias Action = MainTabFeature.Action

  @Dependency(\.date.now)
  var now

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .my(.delegate(.showBusinessCard)):
        // 미결정 — 명함이 이미 있으면 내 명함(UI-11e)으로 보낸다(11e 노트). 11e가 없어 지금은 늘 만들기로 연다.
        state.businessCard = BusinessCardFeature.State(
          nickname: state.my.profile?.nickname ?? "",
          persona: state.my.profile?.persona?.name,
          today: self.now
        )
        return .none

      case .businessCard(.presented(.delegate(.dismiss))):
        state.businessCard = nil
        return .none

      case .my(.delegate(.editProfile)):
        guard let profile = state.my.profile else { return .none }
        state.myPath.append(.editProfile(EditProfileFeature.State(profile: profile)))
        return .none

      case let .myPath(.element(id: _, action: .editProfile(.delegate(.profileUpdated(profile))))):
        // 저장하면 마이 탭 프로필 카드에 바로 반영한다
        state.my.profile = profile
        return .none

      case let .myPath(.element(id: elementID, action: .editProfile(.delegate(.dismiss)))),
           let .myPath(.element(id: elementID, action: .library(.delegate(.dismiss)))),
           let .myPath(.element(id: elementID, action: .vote(.delegate(.dismiss)))):
        state.myPath.pop(from: elementID)
        return .none

      case .my(.delegate(.show(.notificationSettings))):
        state.myPath.append(.notificationSettings(NotificationSettingsFeature.State()))
        return .none

      case let .myPath(.element(id: elementID, action: .notificationSettings(.delegate(.dismiss)))):
        state.myPath.pop(from: elementID)
        return .none

      case let .my(.delegate(.show(menu))):
        // 마이의 「내 활동」 세 메뉴는 보관함의 해당 세그먼트로(UI-5c 노트 01)
        let segment: LibrarySegment? = switch menu {
        case .myPlaylists: .playlists
        case .joinedRelays: .relays
        case .likesAndSaves: .likes
        case .notificationSettings, .serviceGuide, .noticesAndTerms, .developerMode: nil
        }
        guard let segment else { return .none }
        state.myPath.append(.library(LibraryFeature.State(segment: segment)))
        return .none

      case let .myPath(.element(id: elementID, action: .library(.delegate(.continueVoting(relayID))))):
        let topic = state.myPath[id: elementID, case: \.library]?.library?.liveRelays
          .first { $0.id == relayID }?.title ?? ""
        state.myPath.append(.vote(CardVoteFeature.State(relayID: relayID, topic: topic)))
        return .none

      default:
        return .none
      }
    }
  }
}
