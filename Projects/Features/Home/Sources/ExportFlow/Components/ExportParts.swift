import SwiftUI
import WePLiDesignSystem

// UI-14c–14o 공통 — 서비스 아이콘 · 시트 내비 · 스위치 행 · 체크 · 보조 버튼

/// 미결정 — 서비스 로고 에셋(svc-applemusic · svc-spotify · svc-youtubemusic · 국내 앱 4종)이 아직 없어 자리 표시
public struct ExportServiceIcon: View {
  public let service: ExportService
  public var size: CGFloat = 40

  public var body: some View {
    RoundedRectangle(cornerRadius: self.size * 0.25)
      .fill(WePLiColor.surface4)
      .frame(width: self.size, height: self.size)
      .overlay {
        Image(systemName: self.service == .otherApps ? "square.grid.2x2.fill" : "music.note")
          .font(.system(size: self.size * 0.45, weight: .semibold))
          .foregroundStyle(WePLiColor.textMuted)
      }
      .accessibilityHidden(true)
  }

  public init(service: ExportService, size: CGFloat = 40) {
    self.service = service
    self.size = size
  }
}

/// 시트 내비 — 왼쪽 링크(이전 · 닫기) · 가운데 제목, 높이 48
public struct ExportSheetNavBar: View {
  public let leading: String
  public let title: String
  public let action: () -> Void

  public var body: some View {
    ZStack {
      Text(self.title)
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      HStack {
        Button(self.leading, action: self.action)
          .wepliFont(.button, weight: .regular)
          .foregroundStyle(WePLiColor.accent)
        Spacer()
      }
    }
    .padding(.horizontal, 20)
    .frame(height: 48)
  }

  public init(leading: String, title: String, action: @escaping () -> Void) {
    self.leading = leading
    self.title = title
    self.action = action
  }
}

/// 제목 · 설명 · 스위치(14d · 14k) — 최소 높이 64, 아래 구분선
public struct ExportToggleRow: View {
  public let title: String
  public var detail: String?
  public let isOn: Bool
  public let onChange: (Bool) -> Void

  public var body: some View {
    Toggle(isOn: Binding(get: { self.isOn }, set: self.onChange)) {
      VStack(alignment: .leading, spacing: 2) {
        Text(self.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
        if let detail = self.detail {
          Text(detail).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textQuaternary)
        }
      }
    }
    .tint(WePLiColor.accent)
    .padding(.vertical, 10)
    .frame(minHeight: 64)
    .overlay(alignment: .bottom) { ExportDivider() }
  }

  public init(title: String, detail: String? = nil, isOn: Bool, onChange: @escaping (Bool) -> Void) {
    self.title = title
    self.detail = detail
    self.isOn = isOn
    self.onChange = onChange
  }
}

public struct ExportDivider: View {
  public var body: some View {
    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5)
  }

  public init() {}
}

public struct ExportCheck: View {
  public var size: CGFloat = 22

  public var body: some View {
    WePLiSelectionCheck(isOn: true, size: self.size)
  }

  public init(size: CGFloat = 22) {
    self.size = size
  }
}

/// 글자 버튼 — 높이 44, #A3A3A3 (나중에 · 확인할 곡은 빼고 담기)
public struct ExportTextButton: View {
  public let title: String
  public let action: () -> Void

  public var body: some View {
    Button(self.title, action: self.action)
      .wepliFont(.subheadline)
      .foregroundStyle(WePLiColor.textTertiary)
      .frame(maxWidth: .infinity)
      .frame(height: 44)
  }

  public init(title: String, action: @escaping () -> Void) {
    self.title = title
    self.action = action
  }
}

/// 곡 커버 자리 — 이미지가 아직 없다
public struct ExportArtwork: View {
  public var size: CGFloat = 44
  public var radius: CGFloat = 4

  public var body: some View {
    RoundedRectangle(cornerRadius: self.radius)
      .fill(WePLiColor.imagePlaceholder)
      .frame(width: self.size, height: self.size)
      .accessibilityHidden(true)
  }

  public init(size: CGFloat = 44, radius: CGFloat = 4) {
    self.size = size
    self.radius = radius
  }
}
