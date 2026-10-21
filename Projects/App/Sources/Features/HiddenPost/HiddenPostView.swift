import ComposableArchitecture
import SwiftUI

// UI-17c — 내 가려진 글. 안내 → 내 글(나에게만 보여요) → 진행 상황, 아래에 이의 신청하기 · 운영정책 보기 · 글 삭제하기

struct HiddenPostView: View {
  @Perception.Bindable var store: StoreOf<HiddenPostFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        self.navigationBar
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
              Text("다른 사람에게 가려진 글이에요").wepliFont(.headline).foregroundStyle(WePLiColor.textPrimary)
              Text("신고가 5건 모여 운영팀이 확인하는 동안 가려졌어요. 위반이 아니면 그대로 다시 보여요.")
                .wepliFont(.subheadline, weight: .light)
                .foregroundStyle(WePLiColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            HiddenPostCard(post: self.store.post).padding(.top, 22)
            VStack(alignment: .leading, spacing: 14) {
              Text("진행 상황").wepliFont(.body, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
              HiddenPostTimeline(steps: self.store.post.steps)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
          }
          .padding(.bottom, 24)
        }
      }
      .safeAreaInset(edge: .bottom, spacing: 0) { self.actions }
      .background(WePLiColor.background.ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
      .confirmationDialog(self.$store.scope(state: \.deleteDialog, action: \.deleteDialog))
      .sheet(item: self.$store.scope(state: \.appeal, action: \.appeal)) { appealStore in
        AppealView(store: appealStore).wepliSheetStyle(detents: [.large])
      }
      .wepliToast(Binding(get: { self.store.toast }, set: {
        if $0 == nil {
          self.store.send(.toastDismissed)
        }
      }))
    }
  }

  private var navigationBar: some View {
    ZStack {
      Text("내 게시글").wepliFont(.button).foregroundStyle(WePLiColor.textPrimary).accessibilityAddTraits(.isHeader)
      HStack {
        WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") { self.store.send(.backButtonTapped) }
        Spacer()
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
  }

  private var actions: some View {
    VStack(spacing: 4) {
      WePLiPrimaryButton(title: "이의 신청하기") { self.store.send(.appealTapped) }
      Button("운영정책 보기") { self.store.send(.policyTapped) }
        .wepliFont(.body)
        .foregroundStyle(WePLiColor.accent)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
      Button("글 삭제하기") { self.store.send(.deleteTapped) }
        .wepliFont(.subheadline)
        .foregroundStyle(WePLiColor.destructive)
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .disabled(self.store.isDeleting)
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 8)
  }
}

#Preview {
  NavigationStack {
    HiddenPostView(store: Store(initialState: HiddenPostFeature.State(post: .mock)) { HiddenPostFeature() })
  }
}
