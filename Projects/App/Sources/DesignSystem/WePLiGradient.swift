import SwiftUI

// REQ-004 · 그라디언트 토큰 — docs/design/README.md 「토큰」

enum WePLiGradient {
  /// 로고 · 배지 · 강조 텍스트 (#9DABFF → #C8CFFF → #A4FFFF)
  static let brand = LinearGradient(
    stops: [
      .init(color: Color(rgbHex: 0x9DABFF), location: 0),
      .init(color: Color(rgbHex: 0xC8CFFF), location: 0.3927),
      .init(color: Color(rgbHex: 0xA4FFFF), location: 1),
    ],
    startPoint: .leading,
    endPoint: .trailing
  )

  /// 주요 CTA 버튼 (linear-gradient 97.483deg, #FFD8E6 0% · #F0D4F3 14% · #C3D2FF 71% · #B5D3F7 100%)
  static let cta = LinearGradient(
    stops: [
      .init(color: Color(rgbHex: 0xFFD8E6), location: 0),
      .init(color: Color(rgbHex: 0xF0D4F3), location: 0.14),
      .init(color: Color(rgbHex: 0xC3D2FF), location: 0.71),
      .init(color: Color(rgbHex: 0xB5D3F7), location: 1),
    ],
    startPoint: UnitPoint(x: 0, y: 0.43),
    endPoint: UnitPoint(x: 1, y: 0.57)
  )

  /// 하단 고정 버튼 · 탭 바 위 콘텐츠 페이드
  static let bottomFade = LinearGradient(
    colors: [Color.black.opacity(0), Color.black.opacity(0.85)],
    startPoint: .top,
    endPoint: .bottom
  )
}
