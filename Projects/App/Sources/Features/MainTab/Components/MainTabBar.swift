import SwiftUI

// REQ-001 · UI-12d 「탭 바」
// iOS 26: 떠 있는 글래스 캡슐 4탭(62pt) + 분리된 원형 검색 버튼(62pt), 좌우 20 · 아래 26
// iOS 16: 화면 폭 전체 49pt(+ 홈 인디케이터), 위쪽 0.5pt 선, 검색은 5번째 탭

struct MainTabBar: View {
  let selectedTab: MainTabFeature.Tab
  let onSelect: (MainTabFeature.Tab) -> Void

  @Environment(\.wepliChrome)
  private var chrome

  enum Metric {
    static let glassHeight: CGFloat = 62
    static let glassSideInset: CGFloat = 20
    static let glassBottomInset: CGFloat = 26
    static let glassSpacing: CGFloat = 12
    static let glassPillInset: CGFloat = 4
    static let classicHeight: CGFloat = 49
    static let iconSize: CGFloat = 22
    /// 탭 라벨은 시스템 탭 바와 같은 10pt (원본 캔버스 기준)
    static let labelSize: CGFloat = 10
  }

  var body: some View {
    switch self.chrome {
    case .glass: self.glassBar
    case .material: self.classicBar
    }
  }

  // MARK: iOS 26

  private var glassBar: some View {
    HStack(spacing: Metric.glassSpacing) {
      HStack(spacing: 0) {
        ForEach(MainTabFeature.Tab.capsuleTabs, id: \.self) { tab in
          self.tabButton(tab, showsPill: true)
        }
      }
      .padding(Metric.glassPillInset)
      .frame(height: Metric.glassHeight)
      .wepliGlass(in: Capsule())

      Button {
        self.onSelect(.search)
      } label: {
        Image(systemName: MainTabFeature.Tab.search.systemImage)
          .font(.system(size: Metric.iconSize, weight: .medium))
          .foregroundStyle(self.selectedTab == .search ? WePLiColor.accent : WePLiColor.textPrimary)
          .frame(width: Metric.glassHeight, height: Metric.glassHeight)
          .wepliGlass(in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(MainTabFeature.Tab.search.title)
      .accessibilityAddTraits(self.selectedTab == .search ? .isSelected : [])
    }
    .padding(.horizontal, Metric.glassSideInset)
    // 원본은 화면 아래 끝에서 26pt — 홈 인디케이터 안전 영역을 무시하고 잰다.
    .padding(.bottom, Metric.glassBottomInset)
    .ignoresSafeArea(edges: .bottom)
    .background(alignment: .bottom) {
      WePLiGradient.bottomFade
        .frame(height: Metric.glassHeight + Metric.glassBottomInset + 42)
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
    }
  }

  // MARK: iOS 16

  private var classicBar: some View {
    HStack(spacing: 0) {
      ForEach(MainTabFeature.Tab.allCases, id: \.self) { tab in
        self.tabButton(tab, showsPill: false)
      }
    }
    .frame(height: Metric.classicHeight)
    .frame(maxWidth: .infinity)
    .wepliBarMaterial(lineEdge: .top)
  }

  // MARK: 탭 하나

  private func tabButton(_ tab: MainTabFeature.Tab, showsPill: Bool) -> some View {
    let isSelected = self.selectedTab == tab
    let inactive = showsPill ? WePLiColor.tabInactiveGlass : WePLiColor.tabInactiveClassic
    return Button {
      self.onSelect(tab)
    } label: {
      VStack(spacing: 2) {
        Image(systemName: tab.systemImage)
          .font(.system(size: Metric.iconSize, weight: .medium))
        Text(tab.title)
          .font(.custom(WePLiFont.Weight.medium.postScriptName, size: Metric.labelSize))
      }
      .foregroundStyle(isSelected ? WePLiColor.accent : inactive)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background {
        if showsPill, isSelected {
          Capsule().fill(Color.white.opacity(0.12))
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(tab.title)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

#Preview("iOS 26 · iOS 16") {
  VStack(spacing: 40) {
    MainTabBar(selectedTab: .home) { _ in }
    MainTabBar(selectedTab: .relay) { _ in }
      .environment(\.wepliChrome, .material)
  }
  .frame(maxHeight: .infinity, alignment: .bottom)
  .background(WePLiColor.background)
}
