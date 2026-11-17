import SwiftUI

// REQ-002 · UI-12d 「상단 버튼 · 뒤로가기」
// iOS 26: 44pt 원형 글래스 버튼 · iOS 16: 배경 없는 아이콘(터치 영역 44pt 유지)

public struct WePLiIconButton: View {
  public let systemName: String
  public let accessibilityLabel: String
  public let action: () -> Void

  @Environment(\.wepliChrome)
  private var chrome

  public static let size: CGFloat = 44

  public var body: some View {
    Button(action: self.action) {
      Image(systemName: self.systemName)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(self.chrome == .glass ? WePLiColor.textPrimary : WePLiColor.accent)
        .frame(width: Self.size, height: Self.size)
        .modifier(GlassCircle(isOn: self.chrome == .glass))
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(self.accessibilityLabel)
  }

  public init(systemName: String, accessibilityLabel: String, action: @escaping () -> Void) {
    self.systemName = systemName
    self.accessibilityLabel = accessibilityLabel
    self.action = action
  }
}

private struct GlassCircle: ViewModifier {
  let isOn: Bool

  func body(content: Content) -> some View {
    if self.isOn {
      content.wepliGlass(in: Circle())
    } else {
      content
    }
  }
}

#Preview("iOS 26 · iOS 16") {
  HStack(spacing: 24) {
    WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") {}
    WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") {}
      .environment(\.wepliChrome, .material)
  }
  .padding(40)
  .background(WePLiColor.background)
}
