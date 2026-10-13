import SwiftUI

// REQ-002 · 주요 CTA — 높이 54 캡슐, CTA 그라디언트 + 글자 #171821
// 비활성: rgba(255,255,255,0.08) + 글자 #6B6B7C (2b · 3e · 4e · 7c 등)

struct WePLiPrimaryButton: View {
  let title: String
  var isEnabled = true
  let action: () -> Void

  static let height: CGFloat = 54

  var body: some View {
    Button(action: self.action) {
      Text(self.title)
        .wepliFont(.button)
        .foregroundStyle(self.isEnabled ? WePLiColor.textOnCTA : WePLiColor.textDisabled)
        .frame(maxWidth: .infinity)
        .frame(height: Self.height)
        .background {
          if self.isEnabled {
            Capsule().fill(WePLiGradient.cta)
          } else {
            Capsule().fill(WePLiColor.disabledFill)
          }
        }
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .disabled(!self.isEnabled)
  }
}

#Preview("활성 · 비활성") {
  VStack(spacing: 16) {
    WePLiPrimaryButton(title: "투표하기") {}
    WePLiPrimaryButton(title: "곡을 선택해주세요", isEnabled: false) {}
  }
  .padding(20)
  .background(WePLiColor.background)
}
