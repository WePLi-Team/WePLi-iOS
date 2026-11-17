import SwiftUI

/// 듣는 중 막대 3개 — 0.8초, 막대마다 0.18초씩 늦게
public struct WePLiEqualizer: View {
  @State private var isAnimating = false

  @Environment(\.accessibilityReduceMotion)
  private var reduceMotion

  public var body: some View {
    HStack(alignment: .bottom, spacing: 2) {
      ForEach(0 ..< 3, id: \.self) { index in
        RoundedRectangle(cornerRadius: 1)
          .fill(WePLiColor.accent)
          .frame(width: 3, height: 12)
          .scaleEffect(y: self.isAnimating ? 1 : 0.25, anchor: .bottom)
          .animation(
            self.reduceMotion ? nil : .easeInOut(duration: 0.8).repeatForever().delay(Double(index) * 0.18),
            value: self.isAnimating
          )
      }
    }
    .frame(width: 13, height: 12)
    .onAppear { self.isAnimating = true }
    .accessibilityHidden(true)
  }

  public init() {}
}
