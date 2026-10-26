import ComposableArchitecture
import SwiftUI

// UI-17e — 탈퇴 유예(계정 되살리기 → 다시 만나서 반가워요) · 재가입 제한(아직 다시 가입할 수 없어요)

struct AccountGraceView: View {
  @Perception.Bindable var store: StoreOf<AccountGraceFeature>

  var body: some View {
    WithPerceptionTracking {
      self.content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WePLiColor.background.ignoresSafeArea())
        .wepliToast(self.store.toast) { self.store.send(.toastDismissed) }
        .animation(.easeInOut(duration: 0.25), value: self.store.isRestored)
        .sheet(item: self.$store.scope(state: \.helpCenter, action: \.helpCenter)) { helpStore in
          NavigationStack { HelpCenterView(store: helpStore) }
            .wepliSheetStyle(detents: [.large])
        }
        .sheet(item: self.$store.scope(state: \.policy, action: \.policy)) { policyStore in
          NavigationStack { AppInfoView(store: policyStore) }
            .wepliSheetStyle(detents: [.large])
        }
    }
  }

  @ViewBuilder private var content: some View {
    switch self.store.mode {
    case let .pending(pending):
      if self.store.isRestored {
        AccountRestoredContent { self.store.send(.homeTapped) }
      } else {
        AccountPendingContent(pending: pending, isRestoring: self.store.isRestoring) {
          self.store.send(.restoreTapped)
        } onLeave: {
          self.store.send(.leaveTapped)
        }
      }
    case let .blocked(block):
      AccountBlockedContent(block: block) {
        self.store.send(.policyTapped)
      } onHelp: {
        self.store.send(.helpTapped)
      }
    }
  }
}

#Preview("탈퇴 유예") {
  AccountGraceView(store: Store(initialState: AccountGraceFeature.State(mode: .pending(.preview))) {
    AccountGraceFeature()
  })
}

#Preview("재가입 제한") {
  AccountGraceView(store: Store(initialState: AccountGraceFeature.State(mode: .blocked(.preview))) {
    AccountGraceFeature()
  })
}
