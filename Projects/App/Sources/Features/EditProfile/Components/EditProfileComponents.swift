import SwiftUI

// UI-3e 필드 라벨(n/한도) · 나의 성향 목록(행 66, 체크 원형 24)

struct ProfileFieldLabel: View {
  let title: String
  let isRequired: Bool
  let count: Int
  let limit: Int

  var body: some View {
    HStack(spacing: 2) {
      Text(self.title)
        .wepliFont(.subheadline, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
      if self.isRequired {
        Text("*")
          .wepliFont(.subheadline, weight: .semibold)
          .foregroundStyle(WePLiColor.accentStrong)
          .accessibilityLabel("필수")
      }
      Spacer()
      Text("\(self.count)/\(self.limit)")
        .wepliFont(.caption)
        .foregroundStyle(WePLiColor.textDisabled)
        .monospacedDigit()
        .accessibilityLabel("\(self.limit)자 중 \(self.count)자")
    }
  }
}

struct PersonaList: View {
  let selected: Persona?
  let onSelect: (Persona) -> Void

  var body: some View {
    VStack(spacing: 0) {
      ForEach(Array(Persona.allCases.enumerated()), id: \.element) { index, persona in
        let isOn = persona == self.selected
        Button {
          self.onSelect(persona)
        } label: {
          HStack(spacing: 12) {
            // 성향 3D 아이콘(tp1–5)은 에셋이 붙기 전까지 자리 표시
            RoundedRectangle(cornerRadius: 10)
              .fill(WePLiColor.imagePlaceholder)
              .frame(width: 36, height: 36)
              .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
              Text(persona.name)
                .wepliFont(.body, weight: .medium)
                .foregroundStyle(isOn ? WePLiColor.accent : WePLiColor.textPrimary)
              Text(persona.summary)
                .wepliFont(.footnote, weight: .light)
                .foregroundStyle(WePLiColor.textQuaternary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            WePLiSelectionCheck(isOn: isOn)
          }
          .padding(.horizontal, 16)
          .frame(height: 66)
          .contentShape(Rectangle())
          .overlay(alignment: .bottom) {
            if index < Persona.allCases.count - 1 {
              Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5).padding(.leading, 64)
            }
          }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
      }
    }
    .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 18))
  }
}
