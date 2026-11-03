import SwiftUI

// 불러오는 중 · 불러오기 실패 — 화면마다 같은 모양을 따로 그리던 것을 모은다.
// 실패 화면은 원본에 없는 임시 모양 · 문구라(디자인 확인 필요) 디자인이 나오면 여기 한 곳만 고친다.

/// 불러오는 중 — `minHeight`가 없으면 남은 공간을 채운다
struct WePLiLoadingView: View {
  var minHeight: CGFloat?

  var body: some View {
    ProgressView()
      .tint(WePLiColor.textTertiary)
      .frame(maxWidth: .infinity, minHeight: self.minHeight, maxHeight: self.minHeight == nil ? .infinity : nil)
  }
}

/// 불러오기 실패 — 「…를 불러오지 못했어요」 + 「다시 시도」
struct WePLiLoadFailedView: View {
  let message: String
  var minHeight: CGFloat?
  let onRetry: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      Text(self.message)
        .wepliFont(.callout, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
      Button("다시 시도", action: self.onRetry)
        .wepliFont(.subheadline, weight: .semibold)
        .foregroundStyle(WePLiColor.accent)
    }
    .frame(maxWidth: .infinity, minHeight: self.minHeight, maxHeight: self.minHeight == nil ? .infinity : nil)
  }
}

#Preview {
  VStack {
    WePLiLoadingView(minHeight: 200)
    WePLiLoadFailedView(message: "홈을 불러오지 못했어요", minHeight: 200) {}
  }
  .background(WePLiColor.background)
}
