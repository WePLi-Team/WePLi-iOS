import ComposableArchitecture
import SwiftUI

// REQ-102 · UI-6d — 취향 궁합: 점수 고리 → 문구 · 같은 성향 → 둘 다 자주 듣는 아티스트 → 추천해 볼 곡 → 둘이서 플레이리스트 만들기

struct TasteMatchView: View {
  let store: StoreOf<TasteMatchFeature>

  var body: some View {
    WithPerceptionTracking {
      ScrollView {
        if let match = self.store.match {
          VStack(spacing: 0) {
            TasteMatchScore(match: match, name: self.store.name).padding(.top, 18)
            TasteMatchDetails(store: self.store, match: match)
              .padding(EdgeInsets(top: 28, leading: 20, bottom: 60, trailing: 20))
          }
        } else if self.store.loadFailed {
          VStack(spacing: 12) {
            Text(TasteMatchText.loadFailed).wepliFont(.callout, weight: .semibold)
              .foregroundStyle(WePLiColor.textPrimary)
            Button("다시 시도") { self.store.send(.retryButtonTapped) }
              .wepliFont(.subheadline, weight: .semibold)
              .foregroundStyle(WePLiColor.accent)
          }
          .frame(maxWidth: .infinity, minHeight: 300)
        } else {
          ProgressView().tint(WePLiColor.textTertiary).frame(maxWidth: .infinity, minHeight: 300)
        }
      }
      .safeAreaInset(edge: .top, spacing: 0) { self.navigationBar }
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .wepliToast(Binding(get: { self.store.toast }, set: {
        if $0 == nil {
          self.store.send(.toastDismissed)
        }
      }))
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private var navigationBar: some View {
    ZStack {
      Text("취향 궁합").wepliFont(.button).foregroundStyle(WePLiColor.textPrimary).accessibilityAddTraits(.isHeader)
      HStack {
        WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") { self.store.send(.backButtonTapped) }
        Spacer()
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
    .background(WePLiColor.background)
  }
}

#Preview {
  NavigationStack {
    TasteMatchView(store: Store(initialState: TasteMatchFeature.State(userID: "chuuuuu", name: "chuuuuu__")) {
      TasteMatchFeature()
    })
  }
}
