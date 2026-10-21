import ComposableArchitecture
import SwiftUI

// UI-17b — 커뮤니티 운영정책. 시행일 → 금지되는 행동 → 이용 제한 단계 표(지금 내 단계만 라벤더) → 알아두세요 → 이의 신청하기

struct CommunityPolicyView: View {
  @Perception.Bindable var store: StoreOf<CommunityPolicyFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        self.navigationBar
        ScrollView {
          VStack(alignment: .leading, spacing: 30) {
            Text(CommunityPolicyText.effectiveDate).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
            self.section("금지되는 행동") { PolicyBullets(lines: CommunityPolicyText.bannedActions) }
            self.section("이용 제한 단계", subtitle: "위반이 확인될 때마다 한 단계씩 올라가요") {
              PolicyStepTable(steps: CommunityPolicyText.steps, current: self.store.standing?.step)
            }
            self.section("알아두세요") { PolicyBullets(lines: CommunityPolicyText.notes) }
            // 원본은 늘 보이지만 제한이 없으면 이의 신청할 대상이 없어 뺀다
            if self.store.standing?.appealTarget != nil {
              Button("이의 신청하기") { self.store.send(.appealTapped) }
                .wepliFont(.subheadline, weight: .semibold)
                .foregroundStyle(WePLiColor.textPrimary)
                .padding(.horizontal, 18)
                .frame(height: 40)
                .background(WePLiColor.secondaryButtonFill, in: Capsule())
                .buttonStyle(.plain)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 20)
          .padding(.top, 18)
          .padding(.bottom, 60)
        }
      }
      .background(WePLiColor.background.ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
      .sheet(item: self.$store.scope(state: \.appeal, action: \.appeal)) { appealStore in
        AppealView(store: appealStore).wepliSheetStyle(detents: [.large])
      }
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private var navigationBar: some View {
    ZStack {
      Text("커뮤니티 운영정책").wepliFont(.button).foregroundStyle(WePLiColor.textPrimary).accessibilityAddTraits(.isHeader)
      HStack {
        WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") { self.store.send(.backButtonTapped) }
        Spacer()
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
  }

  private func section(_ title: String, subtitle: String? = nil, @ViewBuilder content: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(title).wepliFont(.headline).foregroundStyle(WePLiColor.textPrimary).accessibilityAddTraits(.isHeader)
        if let subtitle {
          Text(subtitle).wepliFont(.caption).foregroundStyle(WePLiColor.textTertiary)
        }
      }
      content()
    }
  }
}

/// 점 목록 — 4pt 점 #6B6B7C, 14/300 #D8D8DD
struct PolicyBullets: View {
  let lines: [String]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ForEach(self.lines, id: \.self) { line in
        HStack(alignment: .top, spacing: 10) {
          Circle().fill(WePLiColor.textDisabled).frame(width: 4, height: 4).padding(.top, 9).accessibilityHidden(true)
          Text(line).wepliFont(.subheadline, weight: .light).lineSpacing(4).foregroundStyle(WePLiColor.textMuted)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }
}

/// 이용 제한 단계 표 — 지금 내 단계만 번호 · 제목이 라벤더, 오른쪽에 「지금 내 단계」
struct PolicyStepTable: View {
  let steps: [PolicyStep]
  let current: Int?

  var body: some View {
    VStack(spacing: 0) {
      ForEach(self.steps) { step in
        let isCurrent = step.id == self.current
        HStack(alignment: .top, spacing: 8) {
          Text(step.countLabel)
            .wepliFont(.subheadline, weight: .bold)
            .monospacedDigit()
            .foregroundStyle(isCurrent ? WePLiColor.accent : WePLiColor.textQuaternary)
            .frame(width: 44, alignment: .leading)
          VStack(alignment: .leading, spacing: 2) {
            Text(step.title)
              .wepliFont(.body, weight: .semibold)
              .foregroundStyle(isCurrent ? WePLiColor.accent : WePLiColor.textPrimary)
            Text(step.detail).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textTertiary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          if isCurrent {
            Text("지금 내 단계").wepliFont(.caption, weight: .bold).foregroundStyle(WePLiColor.accent)
          }
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5) }
        .accessibilityElement(children: .combine)
      }
    }
  }
}

#Preview {
  NavigationStack {
    CommunityPolicyView(store: Store(initialState: CommunityPolicyFeature.State()) { CommunityPolicyFeature() })
  }
}
