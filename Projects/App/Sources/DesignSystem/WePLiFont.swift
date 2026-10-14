import SwiftUI

// REQ-004 · 글꼴 토큰 — Pretendard (SIL OFL 1.1, Resources/Fonts)
// 크기 · 굵기는 Claude Design 캔버스에서 쓰인 단계만 둔다. 최소 12pt(목차 공통 규칙).

enum WePLiFont {
  enum Weight {
    case light
    case regular
    case medium
    case semibold
    case bold

    var postScriptName: String {
      switch self {
      case .light: "Pretendard-Light"
      case .regular: "Pretendard-Regular"
      case .medium: "Pretendard-Medium"
      case .semibold: "Pretendard-SemiBold"
      case .bold: "Pretendard-Bold"
      }
    }
  }

  /// 디자인에 쓰이는 글자 단계. `size`는 기본 크기이고, 다이내믹 타입에 맞춰 함께 커진다.
  enum Style: CaseIterable {
    /// 34 Bold — 큰 제목(커뮤니티 · 알림 · 검색)
    case largeTitle
    /// 32 Bold — 탭 첫 화면 제목(릴레이, UI-10a)
    case screenTitle
    /// 28 SemiBold — 화면 머리말
    case title1
    /// 22 Bold — 홈 섹션 제목
    case title2
    /// 20 SemiBold — 카드 제목
    case title3
    /// 18 SemiBold — 하위 섹션 제목
    case headline
    /// 17 SemiBold — 내비게이션 제목 · 버튼
    case button
    /// 16 Regular — 목록 행
    case callout
    /// 15 Regular — 본문
    case body
    /// 14 Regular — 보조 설명
    case subheadline
    /// 13 Regular — 메타 정보
    case footnote
    /// 12 Regular — 해시태그 · 배지(최소 크기)
    case caption

    var size: CGFloat {
      switch self {
      case .largeTitle: 34
      case .screenTitle: 32
      case .title1: 28
      case .title2: 22
      case .title3: 20
      case .headline: 18
      case .button: 17
      case .callout: 16
      case .body: 15
      case .subheadline: 14
      case .footnote: 13
      case .caption: 12
      }
    }

    var weight: Weight {
      switch self {
      case .largeTitle, .screenTitle, .title2: .bold
      case .title1, .title3, .headline, .button: .semibold
      case .callout, .body, .subheadline, .footnote, .caption: .regular
      }
    }

    var relativeTo: Font.TextStyle {
      switch self {
      case .largeTitle, .screenTitle: .largeTitle
      case .title1: .title
      case .title2: .title2
      case .title3: .title3
      case .headline, .button: .headline
      case .callout: .callout
      case .body: .body
      case .subheadline: .subheadline
      case .footnote: .footnote
      case .caption: .caption
      }
    }
  }

  static func font(_ style: Style, weight: Weight? = nil) -> Font {
    .custom((weight ?? style.weight).postScriptName, size: style.size, relativeTo: style.relativeTo)
  }

  /// 앱 시작 때 한 번 호출한다(App.swift).
  static func register() {
    WePLiFontFamily.registerAllCustomFonts()
  }
}

extension View {
  /// `.wepliFont(.body)` — 디자인 글자 단계를 적용한다.
  func wepliFont(_ style: WePLiFont.Style, weight: WePLiFont.Weight? = nil) -> some View {
    self.font(WePLiFont.font(style, weight: weight))
  }
}
