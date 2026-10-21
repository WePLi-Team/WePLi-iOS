import SwiftUI

// UI-11d 부품 — 대상 카드 · 설명 칸(500자) · 진행 타임라인

struct AppealTargetCard: View {
  let target: AppealTarget

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(self.target.label).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
      Text(self.target.title).wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
      Text(self.target.reasonLine).wepliFont(.footnote).foregroundStyle(WePLiColor.textTertiary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 18))
    .accessibilityElement(children: .combine)
  }
}

struct AppealTextBox: View {
  let text: String
  let onChange: (String) -> Void

  var body: some View {
    VStack(alignment: .trailing, spacing: 0) {
      ZStack(alignment: .topLeading) {
        if self.text.isEmpty {
          Text("운영팀이 다시 볼 수 있게 상황을 설명해 주세요")
            .wepliFont(.body)
            .foregroundStyle(WePLiColor.textDisabled)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .accessibilityHidden(true)
        }
        TextEditor(text: Binding(get: { self.text }, set: self.onChange))
          .wepliFont(.body)
          .foregroundStyle(WePLiColor.textPrimary)
          .scrollContentBackground(.hidden)
          .padding(.horizontal, 11)
          .padding(.top, 6)
          .accessibilityLabel("이의 신청 설명")
      }
      .frame(height: 150)
      Text("\(self.text.count)/\(AppealDraft.textLimit)")
        .wepliFont(.caption)
        .monospacedDigit()
        .foregroundStyle(WePLiColor.textDisabled)
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }
    .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 18))
  }
}

/// 접수 → 검토 중 → 결과 안내. 점은 지난 단계 라벤더 · 지금 단계 보조 강조색 · 남은 단계 회색
struct AppealTimeline: View {
  let steps: [AppealStep]

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(self.steps) { step in
        HStack(alignment: .top, spacing: 12) {
          VStack(spacing: 0) {
            Circle().fill(self.dot(step.phase)).frame(width: 12, height: 12).padding(.top, 4)
            if step.id != self.steps.last?.id {
              Rectangle().fill(Color.white.opacity(0.12)).frame(width: 2).frame(minHeight: 26)
            }
          }
          VStack(alignment: .leading, spacing: 2) {
            Text(step.title)
              .wepliFont(.body, weight: .semibold)
              .foregroundStyle(step.phase == .upcoming ? WePLiColor.textDisabled : WePLiColor.textPrimary)
            Text(step.detail).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
          }
          .padding(.bottom, 14)
        }
        .accessibilityElement(children: .combine)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
    .padding(.vertical, 18)
    .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 18))
  }

  private func dot(_ phase: AppealStep.Phase) -> Color {
    switch phase {
    case .done: WePLiColor.accent
    case .current: WePLiColor.accentStrong
    case .upcoming: WePLiColor.stepPending
    }
  }
}
