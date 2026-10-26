import ComposableArchitecture
import SwiftUI

// REQ-050 · UI-14c–14k · UI-14n · UI-14o — 내 음악 앱으로 내보내기
// 원본은 단계마다 떠 있는 시트(14c · 14e · 14j)와 전체 높이 시트(14d · 14h · 14i · 14o), 전체 화면(14k)을 오간다.
// 한 시트 안에서 단계를 바꾸고, 다른 버전 고르기(14j)만 시트 위 시트로 연다.

struct ExportFlowView: View {
  @Perception.Bindable var store: StoreOf<ExportFlowFeature>

  var body: some View {
    WithPerceptionTracking {
      self.content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.25), value: self.store.step)
        .wepliToast(self.store.toast) { self.store.send(.toastDismissed) }
        .sheet(isPresented: Binding(
          get: { [isPicking = self.store.picking != nil] in isPicking },
          set: {
            if !$0 {
              self.store.send(.alternativesClosed)
            }
          }
        )) {
          ExportAlternativesSheet(store: self.store)
            .wepliSheetStyle(detents: [.large])
        }
    }
  }

  private var content: some View {
    Group {
      switch self.store.step {
      case .service: ExportServiceStep(store: self.store)
      case .settings: ExportSettingsStep(store: self.store)
      case .appleMusicPermission: ExportPermissionStep(store: self.store)
      case .matching: ExportMatchingStep(store: self.store)
      case .review: ExportReviewStep(store: self.store)
      case .done: ExportDoneStep(store: self.store)
      case .copyList: ExportCopyListStep(store: self.store)
      case .subscriptionNeeded: ExportSubscriptionStep(store: self.store)
      case let .problem(problem): ExportProblemStep(store: self.store, problem: problem)
      }
    }
    .transition(.opacity)
  }
}

#Preview {
  Color.black.sheet(isPresented: .constant(true)) {
    ExportFlowView(store: Store(initialState: ExportFlowFeature.State(
      relayID: "r1",
      title: "졸릴 때 잠 깨는 청량맛 노동요",
      recommenderCount: 248,
      songs: ExportSample.songs
    )) {
      ExportFlowFeature()
    })
    .wepliSheetStyle(detents: [.large])
  }
}
