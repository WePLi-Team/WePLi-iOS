import ComposableArchitecture
import SwiftUI

// REQ-013 · UI-7c — 계정 관리 → 탈퇴 1/2 사유 → 2/2 확인 → 완료. 한 화면 안에서 단계를 바꾼다(원본).

struct AccountManagementView: View {
  @Perception.Bindable var store: StoreOf<AccountManagementFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        self.navigationBar
        self.content
      }
      .background(WePLiColor.background.ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
      .wepliToast(self.store.toast) { self.store.send(.toastDismissed) }
      .animation(.easeInOut(duration: 0.2), value: self.store.step)
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private var navigationBar: some View {
    ZStack {
      Text(self.store.step.title)
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      HStack {
        WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") {
          self.store.send(.backButtonTapped)
        }
        Spacer()
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
  }

  @ViewBuilder private var content: some View {
    switch self.store.step {
    case .manage:
      ScrollView {
        AccountManageContent(store: self.store).padding(.top, 18).padding(.bottom, 40)
      }
    case .reason:
      WithdrawReasonContent(store: self.store)
    case .confirm:
      WithdrawConfirmContent(store: self.store)
    case .done:
      WithdrawDoneContent(deletesAt: self.store.deletesAt) { self.store.send(.doneTapped) }
    }
  }
}

#Preview("계정 관리") {
  NavigationStack {
    AccountManagementView(store: Store(initialState: AccountManagementFeature.State()) {
      AccountManagementFeature()
    })
  }
}

#Preview("탈퇴 사유") {
  AccountManagementView(store: Store(initialState: AccountManagementFeature.State(entry: .reason)) {
    AccountManagementFeature()
  })
}
