import SwiftUI

// REQ-003 · UI-10f 「로딩」 — 스피너만 쓰지 않고 실제 배치와 같은 회색 틀이 천천히 깜빡인다.

enum WePLiSkeleton {
  /// 깜빡임: 불투명도 1 ↔ 0.45, 0.9초
  static let dimmedOpacity: Double = 0.45
  static let pulseDuration: Double = 0.9
}

/// 회색 틀 하나. 배치는 화면이 정한다.
struct WePLiSkeletonBlock: View {
  var width: CGFloat?
  let height: CGFloat
  var cornerRadius: CGFloat = 6
  var color = WePLiColor.surface2

  var body: some View {
    RoundedRectangle(cornerRadius: self.cornerRadius)
      .fill(self.color)
      .frame(width: self.width, height: self.height)
      .frame(maxWidth: self.width == nil ? .infinity : nil, alignment: .leading)
  }
}

private struct WePLiPulse: ViewModifier {
  @State private var isDimmed = false

  @Environment(\.accessibilityReduceMotion)
  private var reduceMotion

  func body(content: Content) -> some View {
    content
      .opacity(self.isDimmed ? WePLiSkeleton.dimmedOpacity : 1)
      .onAppear {
        guard !self.reduceMotion else { return }
        withAnimation(.easeInOut(duration: WePLiSkeleton.pulseDuration).repeatForever(autoreverses: true)) {
          self.isDimmed = true
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("불러오는 중")
  }
}

extension View {
  /// 스켈레톤 묶음에 붙여 천천히 깜빡이게 한다. 동작 줄이기 설정이면 깜빡이지 않는다.
  func wepliPulse() -> some View {
    self.modifier(WePLiPulse())
  }
}

/// 곡 행 스켈레톤 — 52pt 아트 + 두 줄
struct WePLiSongRowSkeleton: View {
  var titleRatio: CGFloat = 0.7
  var subtitleRatio: CGFloat = 0.4

  var body: some View {
    HStack(spacing: 12) {
      WePLiSkeletonBlock(width: 52, height: 52, cornerRadius: 4)
      GeometryReader { proxy in
        VStack(alignment: .leading, spacing: 8) {
          WePLiSkeletonBlock(width: proxy.size.width * self.titleRatio, height: 14)
          WePLiSkeletonBlock(
            width: proxy.size.width * self.subtitleRatio,
            height: 12,
            color: WePLiColor.surface1
          )
        }
        .frame(maxHeight: .infinity)
      }
      .frame(height: 52)
    }
  }
}

/// 홈 배치 스켈레톤 — 히어로 420 + 제목 바 + 곡 행 3개 (UI-10f)
struct WePLiHomeSkeleton: View {
  var body: some View {
    VStack(spacing: 14) {
      Rectangle().fill(WePLiColor.surface1).frame(height: 420)
      VStack(alignment: .leading, spacing: 10) {
        WePLiSkeletonBlock(width: 160, height: 20)
        WePLiSkeletonBlock(width: 220, height: 14, color: WePLiColor.surface1)
      }
      .padding(.horizontal, 20)
      VStack(spacing: 12) {
        WePLiSongRowSkeleton(titleRatio: 0.7, subtitleRatio: 0.4)
        WePLiSongRowSkeleton(titleRatio: 0.6, subtitleRatio: 0.35)
        WePLiSongRowSkeleton(titleRatio: 0.75, subtitleRatio: 0.45)
      }
      .padding(.horizontal, 20)
    }
    .wepliPulse()
  }
}

#Preview {
  WePLiHomeSkeleton()
    .frame(maxHeight: .infinity, alignment: .top)
    .background(WePLiColor.background)
}
