import ComposableArchitecture
import SwiftUI

// REQ-073 · UI-11d — 이의 신청. 대상 카드 → 사유 · 설명 · 기준 안내 → 「이의 신청 보내기」, 보내면 진행 타임라인
// 사유는 라벤더 선택 칩(34 · 14pt), 보내기는 그라데이션 버튼(DEC-009)

struct AppealView: View {
  let store: StoreOf<AppealFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        self.navigationBar
        ScrollView {
          VStack(alignment: .leading, spacing: 18) {
            AppealTargetCard(target: self.store.target)
            if self.store.isSent {
              AppealTimeline(steps: AppealStep.afterSending)
              Text("결과는 알림과 고객센터 › 내 문의 내역으로 알려드려요. 검토 중에도 다른 기능은 그대로 쓸 수 있어요.")
                .wepliFont(.footnote)
                .foregroundStyle(WePLiColor.textTertiary)
                .padding(.horizontal, 4)
            } else {
              self.form
            }
          }
          .padding(.horizontal, 16)
          .padding(.top, 16)
          .padding(.bottom, 120)
        }
        .scrollDismissesKeyboard(.interactively)
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        if !self.store.isSent {
          WePLiPrimaryButton(
            title: "이의 신청 보내기",
            isEnabled: self.store.draft.canSend && !self.store.isSending
          ) { self.store.send(.sendTapped) }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
      }
      .background(WePLiColor.background.ignoresSafeArea())
      .animation(.easeOut(duration: 0.25), value: self.store.isSent)
      .wepliToast(Binding(get: { self.store.toast }, set: {
        if $0 == nil {
          self.store.send(.toastDismissed)
        }
      }))
    }
  }

  private var navigationBar: some View {
    ZStack {
      Text("이의 신청").wepliFont(.button).foregroundStyle(WePLiColor.textPrimary).accessibilityAddTraits(.isHeader)
      HStack {
        WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") { self.store.send(.closeTapped) }
        Spacer()
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
    .padding(.top, 8)
  }

  private var form: some View {
    VStack(alignment: .leading, spacing: 18) {
      VStack(alignment: .leading, spacing: 8) {
        Text("어떤 점이 잘못되었나요?")
          .wepliFont(.body, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
          .padding(.horizontal, 4)
        HStack(spacing: 8) {
          ForEach(AppealReason.allCases, id: \.self) { reason in
            WePLiChip(title: reason.title, isOn: self.store.draft.reason == reason, size: .large) {
              self.store.send(.reasonSelected(reason))
            }
          }
        }
      }
      AppealTextBox(text: self.store.draft.text) { self.store.send(.textChanged($0)) }
      Text("이의 신청은 게시글·이용 제한마다 한 번 할 수 있고, 24시간 안에 결과를 알려드려요. 결과가 바뀌면 글이 바로 복구되고 제한 기록도 지워져요.")
        .wepliFont(.caption)
        .foregroundStyle(WePLiColor.textQuaternary)
        .padding(.horizontal, 4)
    }
  }
}

#Preview {
  AppealView(store: Store(initialState: AppealFeature.State(target: AppealTarget(
    id: "post-1",
    kind: .post,
    title: "비 오는 날 듣는 플리",
    reason: "욕설 · 비하 표현 신고 누적"
  ))) {
    AppealFeature()
  })
}
