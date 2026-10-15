import SwiftUI

// UI-14c–14o 공통 — 서비스 아이콘 · 시트 내비 · 스위치 행 · 체크 · 보조 버튼

/// 미결정 — 서비스 로고 에셋(svc-applemusic · svc-spotify · svc-youtubemusic · 국내 앱 4종)이 아직 없어 자리 표시
struct ExportServiceIcon: View {
  let service: ExportService
  var size: CGFloat = 40

  var body: some View {
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
}

/// 시트 내비 — 왼쪽 링크(이전 · 닫기) · 가운데 제목, 높이 48
struct ExportSheetNavBar: View {
  let leading: String
  let title: String
  let action: () -> Void

  var body: some View {
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
}

/// 제목 · 설명 · 스위치(14d · 14k) — 최소 높이 64, 아래 구분선
struct ExportToggleRow: View {
  let title: String
  let detail: String
  let isOn: Bool
  let onChange: (Bool) -> Void

  var body: some View {
    Toggle(isOn: Binding(get: { self.isOn }, set: self.onChange)) {
      VStack(alignment: .leading, spacing: 2) {
        Text(self.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
        Text(self.detail).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textQuaternary)
      }
    }
    .tint(WePLiColor.accent)
    .padding(.vertical, 10)
    .frame(minHeight: 64)
    .overlay(alignment: .bottom) { ExportDivider() }
  }
}

struct ExportDivider: View {
  var body: some View {
    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5)
  }
}

struct ExportCheck: View {
  var size: CGFloat = 22

  var body: some View {
    Image(systemName: "checkmark")
      .font(.system(size: self.size * 0.7, weight: .bold))
      .foregroundStyle(WePLiColor.accent)
      .frame(width: self.size, height: self.size)
      .accessibilityHidden(true)
  }
}

/// 보조 캡슐 버튼 — 흰색 10%, 높이 50
struct ExportSecondaryButton: View {
  let title: String
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      Text(self.title)
        .wepliFont(.body, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(WePLiColor.secondaryButtonFill, in: Capsule())
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
  }
}

/// 글자 버튼 — 높이 44, #A3A3A3 (나중에 · 확인할 곡은 빼고 담기)
struct ExportTextButton: View {
  let title: String
  let action: () -> Void

  var body: some View {
    Button(self.title, action: self.action)
      .wepliFont(.subheadline)
      .foregroundStyle(WePLiColor.textTertiary)
      .frame(maxWidth: .infinity)
      .frame(height: 44)
  }
}

/// 곡 커버 자리 — 이미지가 아직 없다
struct ExportArtwork: View {
  var size: CGFloat = 44
  var radius: CGFloat = 4

  var body: some View {
    RoundedRectangle(cornerRadius: self.radius)
      .fill(WePLiColor.imagePlaceholder)
      .frame(width: self.size, height: self.size)
      .accessibilityHidden(true)
  }
}
