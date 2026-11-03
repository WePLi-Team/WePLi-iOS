import SwiftUI

// 앨범 아트 · 커버 · 프로필 사진 자리 — 지금은 이미지 자리 색만 칠한다.
// 실제 이미지 URL이 생기면 여기 한 곳에서 불러오기 · 캐시 · 다운샘플링을 붙인다.

struct WePLiArtwork: View {
  enum Style {
    /// 앨범 아트 · 플리 커버 — 둥근 사각
    case rounded(CGFloat)
    /// 프로필 · 가수 사진 — 원
    case circle
  }

  let size: CGFloat
  let style: Style

  var body: some View {
    switch self.style {
    case let .rounded(cornerRadius):
      RoundedRectangle(cornerRadius: cornerRadius)
        .fill(WePLiColor.imagePlaceholder)
        .frame(width: self.size, height: self.size)
    case .circle:
      Circle()
        .fill(WePLiColor.imagePlaceholder)
        .frame(width: self.size, height: self.size)
    }
  }
}

#Preview {
  HStack(spacing: 16) {
    WePLiArtwork(size: 60, style: .rounded(12))
    WePLiArtwork(size: 48, style: .circle)
  }
  .padding(40)
  .background(WePLiColor.background)
}
