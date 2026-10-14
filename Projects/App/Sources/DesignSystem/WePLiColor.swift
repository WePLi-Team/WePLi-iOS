import SwiftUI

// REQ-004 · 디자인 토큰 — 값의 원본: docs/design/README.md 「토큰」 · UI-12d
// 화면 코드에서는 hex를 쓰지 않고 이 이름만 쓴다.

enum WePLiColor {
  // MARK: 배경 · 표면

  static let background = Color(rgbHex: 0x000000)
  static let surface1 = Color(rgbHex: 0x141417)
  static let surface2 = Color(rgbHex: 0x1C1C22)
  static let surface3 = Color(rgbHex: 0x212129)
  static let surface4 = Color(rgbHex: 0x2A2A33)

  // MARK: 텍스트

  static let textPrimary = Color(rgbHex: 0xF0F0F0)
  static let textSecondary = Color(rgbHex: 0xB5B5C0)
  static let textTertiary = Color(rgbHex: 0xA3A3A3)
  static let textQuaternary = Color(rgbHex: 0x8E8E99)
  /// 꺼진 칩 · 배지 글자 (10a)
  static let textMuted = Color(rgbHex: 0xD8D8DD)
  static let textDisabled = Color(rgbHex: 0x6B6B7C)
  /// CTA 그라디언트 위 글자
  static let textOnCTA = Color(rgbHex: 0x171821)

  // MARK: 강조

  /// 라벤더 — 1–3위 · 활성 탭 · 링크
  static let accent = Color(rgbHex: 0xC8CFFF)
  static let accentStrong = Color(rgbHex: 0x9DABFF)
  static let accentChip = Color(rgbHex: 0x849BEB)
  /// 시안 — 완료 · 상승 · 토스트 체크
  static let positive = Color(rgbHex: 0xA4FFFF)
  /// 핑크 — 좋아요 · 하락 · 곧 마감
  static let highlight = Color(rgbHex: 0xFE82DB)
  /// 위험 동작
  static let destructive = Color(rgbHex: 0xFF453A)

  // MARK: 상태 · 오버레이

  static let disabledFill = Color.white.opacity(0.08)
  /// 본문과 댓글 사이 8pt 띠 (UI-2c)
  static let sectionBand = Color(rgbHex: 0x0E0E10)
  /// 하단 선택 트레이 바탕 rgba(30,30,36,0.9) (UI-2a)
  static let trayBackground = Color(rgbHex: 0x1E1E24, opacity: 0.9)
  /// 보조 캡슐 버튼 바탕 (10f 빈 상태 버튼)
  static let secondaryButtonFill = Color.white.opacity(0.1)
  /// 릴레이 완성 배지 안쪽 (UI-3c)
  static let completionBadgeFill = Color(rgbHex: 0x0C0C12)
  /// 릴레이 타이머 숫자 (UI-3c)
  static let timerText = Color(rgbHex: 0xC2C2C2)
  /// 타이머 캡슐 안쪽 빛 rgba(78,80,122) (UI-3c)
  static let timerGlow = Color(rgbHex: 0x4E507A, opacity: 0.25)
  static let dim = Color.black.opacity(0.55)

  // MARK: iOS 26 글래스 (UI-12d)

  static let glassFill = Color(rgbHex: 0x2C2C34, opacity: 0.55)
  static let glassStroke = Color.white.opacity(0.16)
  static let tabInactiveGlass = Color(rgbHex: 0x9292A1)

  // MARK: iOS 16 반투명 소재 (UI-12d)

  static let barMaterial = Color(rgbHex: 0x1C1C1F, opacity: 0.9)
  static let barLine = Color.white.opacity(0.12)
  static let sheetBackground = Color(rgbHex: 0x1C1C1E)
  static let groupedBackground = Color(rgbHex: 0x2C2C2E)
  static let separator = Color(rgbHex: 0x545458, opacity: 0.65)
  static let searchFieldFill = Color(rgbHex: 0x767680, opacity: 0.24)
  static let tabInactiveClassic = Color(rgbHex: 0x8E8E93)
}

extension Color {
  /// 0xRRGGBB 정수로 sRGB 색을 만든다. 디자인 시스템 안에서만 쓴다.
  init(rgbHex: UInt32, opacity: Double = 1) {
    self.init(
      .sRGB,
      red: Double((rgbHex >> 16) & 0xFF) / 255,
      green: Double((rgbHex >> 8) & 0xFF) / 255,
      blue: Double(rgbHex & 0xFF) / 255,
      opacity: opacity
    )
  }
}
