import SwiftUI

// REQ-005 · UI-12d — 「한 코드로 두 모양」
// 레이아웃 · 간격 · 글자는 공유하고, 시스템 크롬(탭 바 · 상단 버튼 · 시트 · 목록 묶음 · 검색 · 미니 플레이어)만 나눈다.

enum WePLiChrome: Equatable {
  /// iOS 26 이상 — 떠 있는 글래스
  case glass
  /// iOS 16–25 — 화면 끝에 붙는 반투명 소재
  case material

  static var current: WePLiChrome {
    if #available(iOS 26, *) {
      return .glass
    }
    return .material
  }
}

extension EnvironmentValues {
  // 미리보기 · 테스트에서 `.environment(\.wepliChrome, .material)`로 바꿔 볼 수 있다.
  @Entry var wepliChrome: WePLiChrome = .current
}

// MARK: - 크롬 수치 (UI-12d)

extension WePLiChrome {
  /// 시트 모서리 — iOS 26 34 · iOS 16 10
  var sheetCornerRadius: CGFloat {
    switch self {
    case .glass: 34
    case .material: 10
    }
  }

  /// 목록 묶음 모서리 — iOS 26 26 · iOS 16 10
  var groupCornerRadius: CGFloat {
    switch self {
    case .glass: 26
    case .material: 10
    }
  }

  /// 목록 행 높이 — iOS 26 52 · iOS 16 44
  var listRowHeight: CGFloat {
    switch self {
    case .glass: 52
    case .material: 44
    }
  }

  /// 미니 플레이어 높이 — iOS 26 56 캡슐 · iOS 16 64 바
  var miniPlayerHeight: CGFloat {
    switch self {
    case .glass: 56
    case .material: 64
    }
  }
}

// MARK: - 글래스 배경

extension View {
  /// iOS 26 글래스 표면: rgba(44,44,52,0.55) + blur + 0.5pt 테두리 (UI-12d 토큰)
  func wepliGlass(in shape: some InsettableShape) -> some View {
    self
      .background(.ultraThinMaterial, in: shape)
      .background(WePLiColor.glassFill, in: shape)
      .overlay(shape.strokeBorder(WePLiColor.glassStroke, lineWidth: 0.5))
  }

  /// iOS 16 바 소재: rgba(28,28,31,0.9) + blur, 위 또는 아래 0.5pt 선
  func wepliBarMaterial(lineEdge: VerticalEdge) -> some View {
    self
      .background(.ultraThinMaterial)
      .background(WePLiColor.barMaterial)
      .overlay(alignment: lineEdge == .top ? .top : .bottom) {
        Rectangle().fill(WePLiColor.barLine).frame(height: 0.5)
      }
  }
}
