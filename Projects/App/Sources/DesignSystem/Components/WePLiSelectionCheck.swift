import SwiftUI

// DEC-017 「목록에서 고르기」 — 빈 동그라미 없이 고른 줄만 오른쪽 체크(#C8CFFF 선 2.6)
// 고르지 않은 줄은 같은 크기의 빈 자리를 둬서 글자 폭이 바뀌지 않게 한다

struct WePLiSelectionCheck: View {
  let isOn: Bool
  var size: CGFloat = 20

  var body: some View {
    CheckShape()
      .stroke(WePLiColor.accent, style: StrokeStyle(lineWidth: 2.6 * self.size / 20, lineCap: .round, lineJoin: .round))
      .opacity(self.isOn ? 1 : 0)
      .frame(width: self.size, height: self.size)
      .accessibilityHidden(true)
  }
}

/// 원본 path `M5 12.5l4.5 4.5L19 7.5` (viewBox 24)
private struct CheckShape: Shape {
  func path(in rect: CGRect) -> Path {
    let unit = rect.width / 24
    var path = Path()
    path.move(to: CGPoint(x: 5 * unit, y: 12.5 * unit))
    path.addLine(to: CGPoint(x: 9.5 * unit, y: 17 * unit))
    path.addLine(to: CGPoint(x: 19 * unit, y: 7.5 * unit))
    return path
  }
}
