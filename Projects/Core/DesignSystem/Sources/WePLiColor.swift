import SwiftUI

// REQ-004 · 디자인 토큰 — 값의 원본: docs/design/README.md 「토큰」 · UI-12d
// 화면 코드에서는 hex를 쓰지 않고 이 이름만 쓴다.

public enum WePLiColor {
  // MARK: 배경 · 표면

  public static let background = Color(rgbHex: 0x000000)
  public static let surface1 = Color(rgbHex: 0x141417)
  public static let surface2 = Color(rgbHex: 0x1C1C22)
  public static let surface3 = Color(rgbHex: 0x212129)
  public static let surface4 = Color(rgbHex: 0x2A2A33)
  /// 아직 오지 않은 진행 단계 점 (11d)
  public static let stepPending = Color(rgbHex: 0x3A3A44)

  // MARK: 텍스트

  public static let textPrimary = Color(rgbHex: 0xF0F0F0)
  public static let textSecondary = Color(rgbHex: 0xB5B5C0)
  public static let textTertiary = Color(rgbHex: 0xA3A3A3)
  public static let textQuaternary = Color(rgbHex: 0x8E8E99)
  /// 꺼진 칩 · 배지 글자 (10a)
  public static let textMuted = Color(rgbHex: 0xD8D8DD)
  public static let textDisabled = Color(rgbHex: 0x6B6B7C)
  /// 아직 못 얻은 칭호 아이콘 (8d)
  public static let textLocked = Color(rgbHex: 0x4A4A55)
  /// CTA 그라디언트 위 글자
  public static let textOnCTA = Color(rgbHex: 0x171821)

  // MARK: 강조

  /// 라벤더 — 1–3위 · 활성 탭 · 링크
  public static let accent = Color(rgbHex: 0xC8CFFF)
  public static let accentStrong = Color(rgbHex: 0x9DABFF)
  public static let accentChip = Color(rgbHex: 0x849BEB)
  /// 시안 — 완료 · 상승 · 토스트 체크
  public static let positive = Color(rgbHex: 0xA4FFFF)
  /// 핑크 — 좋아요 · 하락 · 곧 마감
  public static let highlight = Color(rgbHex: 0xFE82DB)
  /// 위험 동작
  public static let destructive = Color(rgbHex: 0xFF453A)

  // MARK: 상태 · 오버레이

  public static let disabledFill = Color.white.opacity(0.08)
  /// 선택 칩 · HOST 배지 바탕 rgba(200,207,255,0.16) / 꺼진 칩 흰색 6% (디자인 시스템)
  public static let chipOn = Color(rgbHex: 0xC8CFFF, opacity: 0.16)
  public static let chipOff = Color.white.opacity(0.06)
  /// 이미지 자리 · 로딩 중 커버 · 아바타 (디자인 시스템 surface2)
  public static let imagePlaceholder = Self.surface2
  /// 입력 오류 — 위험 동작(#FF453A)과 구분한다 (모션 35)
  public static let inputError = Color(rgbHex: 0xFF6961)
  /// 오류 배너 글자 — 오프라인 · 이용 제한 (UI-7d)
  public static let errorText = Color(rgbHex: 0xFFB3AE)
  /// 고른 선택 카드 안쪽 (UI-6a 투표 방식)
  public static let selectionFill = Color(rgbHex: 0x1A1A22)
  /// 명함 카드 면 · 테두리 · 말풍선 (UI-2e)
  public static let cardFace = Color(rgbHex: 0x030303)
  public static let cardLine = Color(rgbHex: 0x2F2F38)
  /// 본문과 댓글 사이 8pt 띠 (UI-2c)
  public static let sectionBand = Color(rgbHex: 0x0E0E10)
  /// 하단 선택 트레이 바탕 rgba(30,30,36,0.9) (UI-2a)
  public static let trayBackground = Color(rgbHex: 0x1E1E24, opacity: 0.9)
  /// 보조 캡슐 버튼 바탕 (10f 빈 상태 버튼)
  public static let secondaryButtonFill = Color.white.opacity(0.1)
  /// 릴레이 타이머 숫자 (UI-3c)
  public static let timerText = Color(rgbHex: 0xC2C2C2)
  /// 타이머 캡슐 안쪽 빛 rgba(78,80,122) (UI-3c)
  public static let timerGlow = Color(rgbHex: 0x4E507A, opacity: 0.25)
  public static let dim = Color.black.opacity(0.55)

  // MARK: iOS 26 글래스 (UI-12d)

  public static let glassFill = Color(rgbHex: 0x2C2C34, opacity: 0.55)
  public static let glassStroke = Color.white.opacity(0.16)
  public static let tabInactiveGlass = Color(rgbHex: 0x9292A1)

  // MARK: iOS 16 반투명 소재 (UI-12d)

  public static let barMaterial = Color(rgbHex: 0x1C1C1F, opacity: 0.9)
  public static let barLine = Color.white.opacity(0.12)
  public static let sheetBackground = Color(rgbHex: 0x1C1C1E)
  public static let groupedBackground = Color(rgbHex: 0x2C2C2E)
  public static let separator = Color(rgbHex: 0x545458, opacity: 0.65)
  public static let searchFieldFill = Color(rgbHex: 0x767680, opacity: 0.24)
  public static let tabInactiveClassic = Color(rgbHex: 0x8E8E93)
}

public extension Color {
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
