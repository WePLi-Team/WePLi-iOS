import SwiftUI

// REQ-005 · UI-1e · UI-12d 「목록 묶음」
// iOS 26: 모서리 26 · 행 52 · 바탕 #141417 · 구분선 rgba(255,255,255,0.08)
// iOS 16: 모서리 10 · 행 44 · 바탕 #1C1C1E · 구분선 rgba(84,84,88,0.65)

public struct WePLiListGroup<Content: View>: View {
  public var title: String?
  @ViewBuilder public var content: () -> Content

  @Environment(\.wepliChrome)
  private var chrome

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if let title = self.title {
        Text(title)
          .wepliFont(.footnote)
          .foregroundStyle(WePLiColor.textQuaternary)
          .padding(.horizontal, 20)
          .accessibilityAddTraits(.isHeader)
      }
      VStack(spacing: 0) {
        self.content()
      }
      .background(
        self.chrome == .glass ? WePLiColor.surface1 : WePLiColor.sheetBackground,
        in: RoundedRectangle(cornerRadius: self.chrome.groupCornerRadius)
      )
      .clipShape(RoundedRectangle(cornerRadius: self.chrome.groupCornerRadius))
    }
    .padding(.horizontal, 16)
  }

  public init(title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
    self.title = title
    self.content = content
  }
}

/// 아이콘 타일(30pt) + 라벨 + 값 또는 화살표. `action`이 없으면 누를 수 없는 값 행이다.
public struct WePLiListRow: View {
  public let systemImage: String
  public let title: String
  public var value: String?
  public var showsSeparator = true
  public var action: (() -> Void)?

  @Environment(\.wepliChrome)
  private var chrome

  public enum Metric {
    public static let iconTile: CGFloat = 30
    public static let iconTileRadius: CGFloat = 8
    public static let iconSize: CGFloat = 16
    /// 구분선 시작점: 좌우 여백 16 + 타일 30 + 간격 12
    public static let separatorInset: CGFloat = 58
  }

  public var body: some View {
    if let action = self.action {
      Button(action: action) { self.row }
        .buttonStyle(.plain)
    } else {
      self.row
    }
  }

  private var row: some View {
    HStack(spacing: 12) {
      Image(systemName: self.systemImage)
        .font(.system(size: Metric.iconSize, weight: .medium))
        .foregroundStyle(WePLiColor.textMuted)
        .frame(width: Metric.iconTile, height: Metric.iconTile)
        .background(WePLiColor.surface4, in: RoundedRectangle(cornerRadius: Metric.iconTileRadius))
        .accessibilityHidden(true)
      Text(self.title)
        .wepliFont(self.chrome == .glass ? .callout : .button, weight: .regular)
        .foregroundStyle(WePLiColor.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
      if let value = self.value {
        Text(value)
          .wepliFont(.body)
          .foregroundStyle(WePLiColor.textQuaternary)
      }
      if self.action != nil {
        Image(systemName: "chevron.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(WePLiColor.textDisabled)
          .accessibilityHidden(true)
      }
    }
    .padding(.horizontal, 16)
    .frame(height: self.chrome.listRowHeight)
    .contentShape(Rectangle())
    .overlay(alignment: .bottom) {
      if self.showsSeparator {
        Rectangle()
          .fill(self.chrome == .glass ? Color.white.opacity(0.08) : WePLiColor.separator)
          .frame(height: 0.5)
          .padding(.leading, Metric.separatorInset)
      }
    }
    .accessibilityElement(children: .combine)
  }

  public init(
    systemImage: String,
    title: String,
    value: String? = nil,
    showsSeparator: Bool = true,
    action: (() -> Void)? = nil
  ) {
    self.systemImage = systemImage
    self.title = title
    self.value = value
    self.showsSeparator = showsSeparator
    self.action = action
  }
}

#Preview("iOS 26 · iOS 16") {
  VStack(spacing: 28) {
    WePLiListGroup(title: "설정") {
      WePLiListRow(systemImage: "bell", title: "알림 설정", action: {})
      WePLiListRow(systemImage: "info.circle", title: "앱 버전", value: "1.0.0", showsSeparator: false)
    }
    WePLiListGroup(title: "설정") {
      WePLiListRow(systemImage: "bell", title: "알림 설정", action: {})
      WePLiListRow(systemImage: "info.circle", title: "앱 버전", value: "1.0.0", showsSeparator: false)
    }
    .environment(\.wepliChrome, .material)
  }
  .frame(maxHeight: .infinity)
  .background(WePLiColor.background)
}
