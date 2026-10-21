import ComposableArchitecture
import SwiftUI

// UI-7c 탈퇴 1/2 사유(여러 개) · 2/2 확인(5줄 + 동의) · 완료
// 원본 「다음」은 흰 버튼 — 흰 버튼 금지(DEC-009)라 그라디언트 주요 버튼. 확인 줄의 분홍 점은 회색 점(DEC-009)

struct WithdrawReasonContent: View {
  let store: StoreOf<AccountManagementFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: 16) {
        Text("떠나시는 이유를\n알려주세요").wepliFont(.title2, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
          .accessibilityAddTraits(.isHeader)
        Text("더 나은 위플리를 만드는 데 참고할게요 (여러 개 선택)")
          .wepliFont(.subheadline)
          .foregroundStyle(WePLiColor.textTertiary)
        VStack(spacing: 0) {
          ForEach(WithdrawReason.allCases, id: \.self) { reason in
            WithdrawCheckRow(
              title: reason.title,
              isOn: self.store.reasons.contains(reason)
            ) { self.store.send(.reasonToggled(reason)) }
              .padding(.horizontal, 16)
              .frame(height: 54)
              .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5) }
          }
        }
        .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 20))
        Spacer()
        WePLiPrimaryButton(title: "다음", isEnabled: !self.store.reasons.isEmpty) { self.store.send(.nextTapped) }
      }
      .padding(.horizontal, 20)
      .padding(.top, 18)
      .padding(.bottom, 24)
    }
  }
}

struct WithdrawConfirmContent: View {
  let store: StoreOf<AccountManagementFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: 16) {
        Text("탈퇴 전에\n꼭 확인해주세요").wepliFont(.title2, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
          .accessibilityAddTraits(.isHeader)
        ScrollView {
          VStack(alignment: .leading, spacing: 14) {
            ForEach(AccountText.rules(self.store.account?.primary ?? .apple), id: \.self) { rule in
              HStack(alignment: .top, spacing: 10) {
                Circle().fill(WePLiColor.textDisabled).frame(width: 5, height: 5).padding(.top, 9)
                Text(rule).wepliFont(.subheadline).foregroundStyle(WePLiColor.textMuted).lineSpacing(4)
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
            }
          }
          .padding(18)
          .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 20))
          WithdrawCheckRow(title: "위 내용을 모두 확인했어요", isOn: self.store.hasAgreed, tint: WePLiColor.destructive) {
            self.store.send(.agreeToggled)
          }
          .padding(4)
          .padding(.top, 12)
        }
        VStack(spacing: 4) {
          self.withdrawButton
          Button("계속 이용할래요") { self.store.send(.keepUsingTapped) }
            .wepliFont(.body)
            .foregroundStyle(WePLiColor.accent)
            .frame(height: 44)
            .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 18)
      .padding(.bottom, 12)
    }
  }

  private var withdrawButton: some View {
    let isEnabled = self.store.hasAgreed && !self.store.isWithdrawing
    return Button {
      self.store.send(.confirmTapped)
    } label: {
      Text("탈퇴하기")
        .wepliFont(.button)
        .foregroundStyle(isEnabled ? Color.white : Color.white.opacity(0.4))
        .frame(maxWidth: .infinity)
        .frame(height: WePLiPrimaryButton.height)
        .background(WePLiColor.destructive.opacity(isEnabled ? 1 : 0.25), in: Capsule())
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled)
  }
}

struct WithdrawDoneContent: View {
  let deletesAt: Date?
  let onConfirm: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      Spacer()
      AccountLogo(height: 28.7).padding(.bottom, 8)
      Text("탈퇴를 신청했어요").wepliFont(.title2, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      if let deletesAt {
        Text("\(AccountText.day(deletesAt))에 모든 정보가 삭제돼요.\n그 전에 다시 로그인하면 되살릴 수 있어요.")
          .wepliFont(.body)
          .foregroundStyle(WePLiColor.textSecondary)
          .lineSpacing(4)
      }
      ExportSecondaryButton(title: "확인", action: self.onConfirm).padding(.top, 30)
      Spacer()
    }
    .multilineTextAlignment(.center)
    .padding(.horizontal, 24)
  }
}

/// 22pt 네모 체크 — 켜면 색 채움 + 체크(사유는 라벤더, 동의는 빨강 · 원본)
struct WithdrawCheckRow: View {
  let title: String
  let isOn: Bool
  var tint = WePLiColor.accent
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 6)
          .fill(self.isOn ? self.tint : Color.clear)
          .overlay {
            if self.isOn {
              Image(systemName: "checkmark").font(.system(size: 11, weight: .heavy))
                .foregroundStyle(self.tint == WePLiColor.accent ? WePLiColor.textOnCTA : Color.white)
            } else {
              RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.25), lineWidth: 1.5)
            }
          }
          .frame(width: 22, height: 22)
        Text(self.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(minHeight: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(self.isOn ? [.isButton, .isSelected] : .isButton)
  }
}

/// 미결정 — 로고 에셋이 없어 글자 로고로 자리 표시
struct AccountLogo: View {
  let height: CGFloat

  var body: some View {
    Text("WePLi")
      .font(.custom(WePLiFont.Weight.bold.postScriptName, size: self.height * 0.8, relativeTo: .title))
      .foregroundStyle(WePLiColor.textPrimary)
      .frame(height: self.height)
      .accessibilityHidden(true)
  }
}
