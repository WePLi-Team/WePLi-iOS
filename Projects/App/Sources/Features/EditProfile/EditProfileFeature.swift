import ComposableArchitecture
import Foundation

// REQ-012 · UI-3e — 내 정보 수정

@Reducer
struct EditProfileFeature {
  @ObservableState
  struct State: Equatable {
    let original: MyProfile
    var nickname: String
    var bio: String
    var persona: Persona?
    var isSaving = false
    var toast: String?

    init(profile: MyProfile) {
      self.original = profile
      self.nickname = profile.nickname
      self.bio = profile.bio
      self.persona = profile.persona
    }

    /// 닉네임이 비면(공백만 포함) 「완료」를 끈다(UI-3e 노트 02). 성향은 필수 하나.
    var canSave: Bool {
      ProfileInput.isValidNickname(self.nickname) && self.persona != nil && !self.isSaving
    }
  }

  enum Action: Equatable {
    case nicknameChanged(String)
    case bioChanged(String)
    case personaSelected(Persona)
    case doneButtonTapped
    case saved(MyProfile)
    case saveFailed
    case toastDismissed
    case backButtonTapped
    case changePhotoTapped
    case withdrawTapped
    case delegate(Delegate)
  }

  enum Delegate: Equatable {
    case dismiss
    /// 저장된 프로필 — 마이 탭이 갱신한다
    case profileUpdated(MyProfile)
    /// 사진 고르기(사진 보관함)
    case pickPhoto
    /// 계정 관리 · 회원 탈퇴 (UI-7c)
    case showWithdraw
  }

  @Dependency(\.editProfileClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .nicknameChanged(text):
        state.nickname = ProfileInput.clamp(text, to: ProfileInput.nicknameLimit)
        return .none

      case let .bioChanged(text):
        state.bio = ProfileInput.clamp(text, to: ProfileInput.bioLimit)
        return .none

      case let .personaSelected(persona):
        state.persona = persona
        return .none

      case .doneButtonTapped:
        guard state.canSave else { return .none }
        state.isSaving = true
        var profile = state.original
        profile.nickname = state.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.bio = state.bio.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.persona = state.persona
        return .run { [profile] send in
          do {
            try await send(.saved(self.client.save(profile)))
          } catch {
            await send(.saveFailed)
          }
        }

      case let .saved(profile):
        state.isSaving = false
        state.nickname = profile.nickname
        state.bio = profile.bio
        state.toast = "내 정보를 저장했어요"
        return .send(.delegate(.profileUpdated(profile)))

      case .saveFailed:
        state.isSaving = false
        // 원본에 없는 문구 — 디자인 확인 필요
        state.toast = "저장하지 못했어요. 잠시 후 다시 시도해 주세요"
        return .none

      case .toastDismissed:
        state.toast = nil
        return .none

      case .backButtonTapped:
        return .send(.delegate(.dismiss))

      case .changePhotoTapped:
        return .send(.delegate(.pickPhoto))

      case .withdrawTapped:
        return .send(.delegate(.showWithdraw))

      case .delegate:
        return .none
      }
    }
  }
}
