import ComposableArchitecture
import SwiftUI

// REQ-079 · UI-13a — 지금 듣는 음악: 연결과 공개 범위(전체 화면). 닫기 · 제목 · 2단계 표시 · 단계 · 아래 버튼

struct ListeningShareView: View {
  let store: StoreOf<ListeningShareFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        ZStack {
          Text("지금 듣는 음악").wepliFont(.button).foregroundStyle(WePLiColor.textPrimary).accessibilityAddTraits(.isHeader)
          HStack {
            WePLiIconButton(systemName: "xmark", accessibilityLabel: "닫기") { self.store.send(.closeTapped) }
            Spacer()
          }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        self.stepBar.padding(.horizontal, 20).padding(.top, 8)
        ScrollView {
          Group {
            switch self.store.step {
            case .connect: ListeningConnectStep(store: self.store)
            case .visibility: ListeningVisibilityStep(store: self.store)
            case .done: ListeningDoneStep(store: self.store)
            }
          }
          .padding(.horizontal, 20)
          .padding(.top, 22)
          .padding(.bottom, 32)
        }
        self.bottomButton().padding(.horizontal, 20).padding(.bottom, 24)
      }
      .background(WePLiColor.background.ignoresSafeArea())
      .animation(.easeInOut(duration: 0.2), value: self.store.step)
      .wepliToast(self.store.toast) { self.store.send(.toastDismissed) }
      .onAppear { self.store.send(.onAppear) }
    }
  }

  /// 원본은 3단계를 2칸으로 보여준다 — 연결했어요에서는 두 칸 모두 켜진다
  private var stepBar: some View {
    HStack(spacing: 6) {
      self.stepSegment("1  음악 서비스 연결", step: .connect, isOn: true)
      self.stepSegment("2  공개 범위", step: .visibility, isOn: self.store.step != .connect)
    }
  }

  private func stepSegment(_ title: String, step: ListeningShareStep, isOn: Bool) -> some View {
    Button {
      self.store.send(.stepTapped(step))
    } label: {
      VStack(alignment: .leading, spacing: 6) {
        Capsule().fill(isOn ? WePLiColor.accent : Color.white.opacity(0.12)).frame(height: 3)
        Text(title).wepliFont(.caption, weight: .semibold)
          .foregroundStyle(isOn ? WePLiColor.textPrimary : WePLiColor.textDisabled)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func bottomButton() -> some View {
    switch self.store.step {
    case .connect:
      WePLiPrimaryButton(title: "다음", isEnabled: self.store.canContinue) { self.store.send(.nextTapped) }
    case .visibility:
      WePLiPrimaryButton(title: "완료", isEnabled: !self.store.isSaving) { self.store.send(.doneTapped) }
    case .done:
      // 원본은 연결했어요에 버튼이 없다 — 닫기(X)로 닫는다
      EmptyView()
    }
  }
}

#Preview {
  ListeningShareView(store: Store(initialState: ListeningShareFeature.State(nickname: "김동")) { ListeningShareFeature()
  })
}
