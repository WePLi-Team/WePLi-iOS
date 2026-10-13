import SwiftUI

// REQ-002 · REQ-005 · UI-12d 「시트」
// 중간 · 전체 높이(presentationDetents)는 iOS 16부터 그대로 쓴다.
// 모서리: iOS 26 34 · iOS 16 10 (presentationCornerRadius는 16.4+, 그 아래는 시스템 기본)
// iOS 26의 떠 있는 바깥 여백은 시스템 시트가 그린다.

private struct WePLiSheetModifier: ViewModifier {
  let detents: Set<PresentationDetent>

  @Environment(\.wepliChrome) private var chrome

  func body(content: Content) -> some View {
    content
      .presentationDetents(self.detents)
      .presentationDragIndicator(.visible)
      .modifier(SheetCornerAndBackground(chrome: self.chrome))
  }
}

private struct SheetCornerAndBackground: ViewModifier {
  let chrome: WePLiChrome

  func body(content: Content) -> some View {
    if #available(iOS 16.4, *) {
      content
        .presentationCornerRadius(self.chrome.sheetCornerRadius)
        .presentationBackground(self.chrome == .glass ? WePLiColor.surface3 : WePLiColor.sheetBackground)
    } else {
      content
    }
  }
}

extension View {
  /// 시트 안쪽 루트 뷰에 붙인다. 기본은 중간 · 전체 높이.
  func wepliSheetStyle(detents: Set<PresentationDetent> = [.medium, .large]) -> some View {
    self.modifier(WePLiSheetModifier(detents: detents))
  }
}
