import ComposableArchitecture
import SwiftUI

// REQ-012 · UI-3e — 내 정보 수정

struct EditProfileView: View {
  let store: StoreOf<EditProfileFeature>

  var body: some View {
    WithPerceptionTracking {
      ScrollView {
        VStack(alignment: .leading, spacing: 28) {
          self.photo
            .frame(maxWidth: .infinity)
          self.nicknameField
          VStack(alignment: .leading, spacing: 10) {
            Text("나의 성향")
              .wepliFont(.subheadline, weight: .semibold)
              .foregroundStyle(WePLiColor.textPrimary)
            PersonaList(selected: self.store.persona) { self.store.send(.personaSelected($0)) }
          }
          self.bioField
          Button("회원 탈퇴") { self.store.send(.withdrawTapped) }
            .wepliFont(.footnote)
            .foregroundStyle(WePLiColor.textQuaternary)
            .underline()
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 40)
      }
      .scrollDismissesKeyboard(.interactively)
      .safeAreaInset(edge: .top, spacing: 0) { self.navigationBar }
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .wepliToast(
        Binding(
          get: { self.store.toast },
          set: {
            if $0 == nil {
              self.store.send(.toastDismissed)
            }
          }
        )
      )
    }
  }

  private var navigationBar: some View {
    ZStack {
      Text("내 정보 수정")
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      HStack {
        WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") {
          self.store.send(.backButtonTapped)
        }
        Spacer()
        Button("완료") { self.store.send(.doneButtonTapped) }
          .wepliFont(.button)
          .foregroundStyle(self.store.canSave ? WePLiColor.accent : WePLiColor.textDisabled.opacity(0.7))
          .disabled(!self.store.canSave)
          .padding(.horizontal, 8)
          .frame(minHeight: 44)
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
    .background(WePLiColor.background)
  }

  private var photo: some View {
    VStack(spacing: 10) {
      Circle()
        .fill(WePLiColor.surface4)
        .frame(width: 96, height: 96)
        .overlay {
          Image(systemName: "person.fill")
            .font(.system(size: 40))
            .foregroundStyle(WePLiColor.textQuaternary)
        }
        .overlay(alignment: .bottomTrailing) {
          Image(systemName: "camera")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(WePLiColor.textMuted)
            .frame(width: 32, height: 32)
            .background(WePLiColor.surface4, in: Circle())
            .overlay(Circle().stroke(WePLiColor.background, lineWidth: 3))
            .offset(x: 2, y: 2)
        }
        .accessibilityHidden(true)
      Button("사진 변경") { self.store.send(.changePhotoTapped) }
        .wepliFont(.subheadline, weight: .medium)
        .foregroundStyle(WePLiColor.accent)
    }
  }

  private var nicknameField: some View {
    VStack(alignment: .leading, spacing: 8) {
      ProfileFieldLabel(
        title: "닉네임",
        isRequired: true,
        count: self.store.nickname.count,
        limit: ProfileInput.nicknameLimit
      )
      TextField(
        "변경할 닉네임을 입력해주세요.",
        text: Binding(get: { self.store.nickname }, set: { self.store.send(.nicknameChanged($0)) })
      )
      .wepliFont(.callout)
      .foregroundStyle(WePLiColor.textPrimary)
      .padding(.horizontal, 16)
      .frame(height: 52)
      .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 14))
      .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(WePLiColor.accent.opacity(0.35), lineWidth: 1))
      .submitLabel(.done)
      Text("다른 사람들에게 보이는 이름이에요")
        .wepliFont(.caption)
        .foregroundStyle(WePLiColor.textQuaternary)
    }
  }

  private var bioField: some View {
    VStack(alignment: .leading, spacing: 8) {
      ProfileFieldLabel(title: "소개", isRequired: false, count: self.store.bio.count, limit: ProfileInput.bioLimit)
      ZStack(alignment: .topLeading) {
        if self.store.bio.isEmpty {
          Text("나를 소개하는 문장을 적어주세요")
            .wepliFont(.body)
            .foregroundStyle(WePLiColor.textDisabled)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .accessibilityHidden(true)
        }
        TextEditor(text: Binding(get: { self.store.bio }, set: { self.store.send(.bioChanged($0)) }))
          .wepliFont(.body)
          .foregroundStyle(WePLiColor.textMuted)
          .scrollContentBackground(.hidden)
          .padding(.horizontal, 11)
          .padding(.vertical, 6)
          .accessibilityLabel("소개")
      }
      .frame(height: 96)
      .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 14))
    }
  }
}

#Preview {
  NavigationStack {
    EditProfileView(store: Store(initialState: EditProfileFeature.State(profile: .mock)) { EditProfileFeature() })
  }
}
