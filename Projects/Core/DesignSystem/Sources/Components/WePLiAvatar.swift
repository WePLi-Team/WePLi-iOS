import SwiftUI

/// 사진이 붙기 전까지 이름 첫 글자로 그리는 자리 표시(백엔드 미정)
public struct WePLiAvatar: View {
  public let name: String
  public var cornerRadius: CGFloat?

  public var body: some View {
    let hue = Double(self.name.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 360) / 360
    let fill = Color(hue: hue, saturation: 0.3, brightness: 0.4)
    Group {
      if let cornerRadius = self.cornerRadius {
        RoundedRectangle(cornerRadius: cornerRadius).fill(fill)
      } else {
        Circle().fill(fill)
      }
    }
    .overlay {
      Text(self.name.prefix(1).uppercased())
        .wepliFont(.subheadline, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary.opacity(0.85))
    }
    .accessibilityHidden(true)
  }

  public init(name: String, cornerRadius: CGFloat? = nil) {
    self.name = name
    self.cornerRadius = cornerRadius
  }
}
