import SwiftUI

// UI-1e 프로필 카드 — 사진 64 · 카메라 배지 22 · 닉네임 20 SemiBold · 이메일 14 Light · 나의 성향 칩

struct MyProfileCard: View {
  let profile: MyProfile
  let onTap: () -> Void

  enum Metric {
    static let photo: CGFloat = 64
    static let cameraBadge: CGFloat = 22
    static let cornerRadius: CGFloat = 24
    static let chipHeight: CGFloat = 30
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Button(action: self.onTap) {
        HStack(spacing: 14) {
          self.photo
          VStack(alignment: .leading, spacing: 2) {
            Text(self.profile.nickname)
              .wepliFont(.title3)
              .foregroundStyle(WePLiColor.textPrimary)
            Text(self.profile.email)
              .wepliFont(.subheadline, weight: .light)
              .foregroundStyle(WePLiColor.textSecondary)
              .lineLimit(1)
              .truncationMode(.tail)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          Image(systemName: "chevron.right")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(WePLiColor.textDisabled)
            .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityHint("내 정보 수정")

      Rectangle()
        .fill(Color.white.opacity(0.08))
        .frame(height: 0.5)

      if let persona = self.profile.persona {
        self.personaRow(persona)
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 18)
    .padding(.bottom, 16)
    .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: Metric.cornerRadius))
    .padding(.horizontal, 16)
  }

  private var photo: some View {
    Circle()
      .fill(WePLiColor.imagePlaceholder)
      .overlay {
        Image(systemName: "person.fill")
          .font(.system(size: 28))
          .foregroundStyle(WePLiColor.textQuaternary)
      }
      .frame(width: Metric.photo, height: Metric.photo)
      .overlay(alignment: .bottomTrailing) {
        Image(systemName: "camera")
          .font(.system(size: 10, weight: .bold))
          .foregroundStyle(WePLiColor.textMuted)
          .frame(width: Metric.cameraBadge, height: Metric.cameraBadge)
          .background(WePLiColor.surface4, in: Circle())
          .overlay(Circle().stroke(WePLiColor.surface1, lineWidth: 2))
          .offset(x: 2, y: 2)
      }
      .accessibilityLabel("프로필 사진")
  }

  private func personaRow(_ persona: Persona) -> some View {
    HStack(spacing: 10) {
      Text("나의 성향")
        .wepliFont(.footnote)
        .foregroundStyle(WePLiColor.textTertiary)
        .fixedSize()
      Text(persona.name)
        .wepliFont(.footnote, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
        .padding(.horizontal, 12)
        .frame(height: Metric.chipHeight - 2)
        .background(WePLiColor.surface1, in: Capsule())
        .padding(1)
        .background(WePLiColor.accentStrong.opacity(0.32), in: Capsule())
        .fixedSize()
      Text(persona.summary)
        .wepliFont(.footnote, weight: .light)
        .foregroundStyle(WePLiColor.textSecondary)
        .lineLimit(1)
    }
    .accessibilityElement(children: .combine)
  }
}
