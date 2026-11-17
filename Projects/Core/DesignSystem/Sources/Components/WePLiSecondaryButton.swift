import SwiftUI

/// 보조 캡슐 버튼 — 흰색 10%, 높이 50
public struct WePLiSecondaryButton: View {
  public let title: String
  public let action: () -> Void

  public var body: some View {
    Button(action: self.action) {
      Text(self.title)
        .wepliFont(.body, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(WePLiColor.secondaryButtonFill, in: Capsule())
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
  }

  public init(title: String, action: @escaping () -> Void) {
    self.title = title
    self.action = action
  }
}
