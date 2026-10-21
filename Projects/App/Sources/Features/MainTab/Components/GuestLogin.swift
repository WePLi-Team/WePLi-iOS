import SwiftUI

// DEC-032 — 손님이 투표 · 추천 등을 눌렀을 때의 로그인 요청 시트와 마이 탭 손님 화면.
// 원본에 화면이 없어 디자인 시스템 부품(그라디언트 주요 버튼 · 라벤더 글자 버튼 · 빈 상태)으로 채운다.

struct GuestLoginSheet: View {
  let reason: GuestPromptReason
  let onLogin: () -> Void
  let onClose: () -> Void

  static let height: CGFloat = 300

  var body: some View {
    VStack(spacing: 0) {
      Image(systemName: "person.crop.circle.badge.checkmark")
        .font(.system(size: 30, weight: .light))
        .foregroundStyle(WePLiColor.accent)
        .frame(width: 64, height: 64)
        .background(WePLiColor.chipOn, in: Circle())
        .padding(.top, 28)
        .accessibilityHidden(true)

      Text(self.reason.title)
        .wepliFont(.title3)
        .foregroundStyle(WePLiColor.textPrimary)
        .padding(.top, 16)

      Text(GuestPromptReason.message)
        .wepliFont(.subheadline)
        .foregroundStyle(WePLiColor.textTertiary)
        .padding(.top, 8)

      Spacer(minLength: 20)

      WePLiPrimaryButton(title: "로그인하기", action: self.onLogin)

      Button(action: self.onClose) {
        Text("계속 둘러보기")
          .wepliFont(.body)
          .foregroundStyle(WePLiColor.accent)
          .frame(maxWidth: .infinity)
          .frame(height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .padding(.top, 4)
    }
    .multilineTextAlignment(.center)
    .padding(.horizontal, 20)
    .padding(.bottom, 12)
  }
}

/// 마이 탭 — 손님에게는 프로필 대신 로그인 안내(10f 빈 상태 규칙: 왜 비었는지 + 다음에 할 일)
struct GuestMyView: View {
  let onLogin: () -> Void

  var body: some View {
    WePLiEmptyState(
      systemImage: "person.crop.circle",
      title: "로그인하고 내 활동을 모아 보세요",
      message: "추천한 곡 · 투표한 릴레이 · 보관함이 여기에 모여요",
      actionTitle: "로그인하기",
      action: self.onLogin
    )
    .background(WePLiColor.background.ignoresSafeArea())
  }
}
