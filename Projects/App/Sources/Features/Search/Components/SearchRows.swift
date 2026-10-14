import SwiftUI

// UI-4c 결과 행 · 칩 · 둘러보기 타일

struct SearchChip: View {
  let title: String
  var isSelected = false
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      Text(self.title)
        .wepliFont(.subheadline, weight: self.isSelected ? .semibold : .regular)
        .foregroundStyle(self.isSelected ? Color.black : WePLiColor.textMuted)
        .padding(.horizontal, 14)
        .frame(height: 34)
        .background(self.isSelected ? WePLiColor.textPrimary : WePLiColor.surface2, in: Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(self.isSelected ? .isSelected : [])
  }
}

/// 둘러보기 타일 — 2열 · 높이 104 · 모서리 18, 「#태그」. 사진은 백엔드가 정해지면 붙인다.
struct SearchTagTile: View {
  let tag: String
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      ZStack(alignment: .bottomLeading) {
        let hue = Double(self.tag.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 360) / 360
        RoundedRectangle(cornerRadius: 18)
          .fill(
            LinearGradient(
              colors: [Color(hue: hue, saturation: 0.4, brightness: 0.55), WePLiColor.surface2],
              startPoint: .topTrailing,
              endPoint: .bottomLeading
            )
          )
        LinearGradient(
          stops: [.init(color: .clear, location: 0.2), .init(color: .black.opacity(0.75), location: 1)],
          startPoint: .topTrailing,
          endPoint: .bottomLeading
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        Text("#\(self.tag)")
          .wepliFont(.callout, weight: .semibold)
          .foregroundStyle(Color.white)
          .padding(.leading, 14)
          .padding(.bottom, 12)
      }
      .frame(height: 104)
    }
    .buttonStyle(.plain)
  }
}

struct SearchSectionHeader: View {
  let title: String

  var body: some View {
    Text(self.title)
      .wepliFont(.callout, weight: .semibold)
      .foregroundStyle(WePLiColor.textPrimary)
      .padding(.horizontal, 20)
      .padding(.top, 16)
      .padding(.bottom, 2)
      .accessibilityAddTraits(.isHeader)
  }
}

/// 곡 행(60, 커버 46 · 모서리 4) · 플리/릴레이 행(64, 커버 50 · 모서리 8, 화살표) 공통
struct SearchResultRow: View {
  enum Kind {
    case song
    case list
  }

  let kind: Kind
  let title: String
  let subtitle: String
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: self.kind == .song ? 4 : 8)
          .fill(WePLiColor.imagePlaceholder)
          .frame(width: self.coverSize, height: self.coverSize)
          .overlay {
            Image(systemName: self.kind == .song ? "music.note" : "music.note.list")
              .font(.system(size: 16))
              .foregroundStyle(WePLiColor.textQuaternary)
          }
        VStack(alignment: .leading, spacing: 1) {
          Text(self.title)
            .wepliFont(.body)
            .foregroundStyle(WePLiColor.textPrimary)
            .lineLimit(1)
          Text(self.subtitle)
            .wepliFont(.footnote, weight: .light)
            .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        if self.kind == .list {
          Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(WePLiColor.textDisabled)
        }
      }
      .padding(.horizontal, 20)
      .frame(height: self.kind == .song ? 60 : 64)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
  }

  private var coverSize: CGFloat {
    self.kind == .song ? 46 : 50
  }
}

/// 사용자 행(62, 아바타 44) + 팔로우 캡슐
struct SearchUserRow: View {
  let user: SearchUser
  let action: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Button(action: self.action) {
        HStack(spacing: 12) {
          AvatarPlaceholder(name: self.user.name)
            .frame(width: 44, height: 44)
          VStack(alignment: .leading, spacing: 1) {
            Text(self.user.name)
              .wepliFont(.body, weight: .medium)
              .foregroundStyle(WePLiColor.textPrimary)
            Text(self.user.subtitle)
              .wepliFont(.footnote, weight: .light)
              .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
              .lineLimit(1)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      // 팔로우 동작은 팔로우 이슈(UI-10c)에서 연결
      Text("팔로우")
        .wepliFont(.footnote, weight: .semibold)
        .foregroundStyle(WePLiColor.accent)
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(WePLiColor.accentStrong.opacity(0.16), in: Capsule())
    }
    .padding(.horizontal, 20)
    .frame(height: 62)
  }
}
