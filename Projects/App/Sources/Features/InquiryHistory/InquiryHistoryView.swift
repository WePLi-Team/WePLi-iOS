import ComposableArchitecture
import SwiftUI

// UI-17a — 내 문의 내역. 안내 한 줄 → 문의 · 이의 신청 결과 줄(누르면 상세)

struct InquiryHistoryView: View {
  let store: StoreOf<InquiryHistoryFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        InquiryNavBar(title: "내 문의 내역") { self.store.send(.backButtonTapped) }
        self.content()
      }
      .background(WePLiColor.background.ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
      .wepliToast(self.store.toast) { self.store.send(.toastDismissed) }
      .onAppear { self.store.send(.onAppear) }
    }
  }

  @ViewBuilder
  private func content() -> some View {
    if let inquiries = self.store.inquiries, inquiries.isEmpty {
      // 원본에 없는 빈 상태 — 10f 규칙(왜 비었는지 + 다음에 할 일)으로 채움, 디자인 확인 필요
      WePLiEmptyState(
        systemImage: "questionmark.bubble",
        title: "아직 문의한 내역이 없어요",
        message: "궁금한 점은 1:1 문의로 물어보세요.",
        actionTitle: "1:1 문의하기"
      ) { self.store.send(.composeTapped) }
    } else if let inquiries = self.store.inquiries {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          Text("1:1 문의 답변과 이의 신청 결과가 모두 여기로 와요")
            .wepliFont(.footnote, weight: .light)
            .foregroundStyle(WePLiColor.textTertiary)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 6)
          ForEach(inquiries) { inquiry in
            InquiryListRow(inquiry: inquiry) { self.store.send(.rowTapped(inquiry.id)) }
          }
        }
        .padding(.bottom, 60)
      }
    } else if self.store.loadFailed {
      VStack(spacing: 12) {
        // 원본에 없는 문구 — 디자인 확인 필요
        Text("문의 내역을 불러오지 못했어요").wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
        InquirySmallButton(title: "다시 시도") { self.store.send(.retryButtonTapped) }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      VStack(alignment: .leading, spacing: 28) {
        ForEach(0 ..< 3, id: \.self) { _ in
          VStack(alignment: .leading, spacing: 6) {
            WePLiSkeletonBlock(width: 60, height: 12)
            WePLiSkeletonBlock(width: 200, height: 15)
            WePLiSkeletonBlock(width: 120, height: 12)
          }
        }
        Spacer()
      }
      .padding(.horizontal, 20)
      .padding(.top, 30)
      .wepliPulse()
    }
  }
}

#Preview {
  NavigationStack {
    InquiryHistoryView(store: Store(initialState: InquiryHistoryFeature.State()) { InquiryHistoryFeature() })
  }
}
