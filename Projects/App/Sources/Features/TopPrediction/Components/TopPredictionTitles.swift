import SwiftUI

// UI-8d 아래쪽 · DEC-021 — 내 칭호. 머리 → 대표 칭호 미리보기 → 3열 격자.
// 얻은 칭호를 누르면 대표가 된다(대표는 홀로그램 고리). 못 얻은 칭호는 아이콘 색으로만 구분한다

struct TopPredictionTitles: View {
  let board: TitleBoard
  let onTap: (UserTitle.ID) -> Void

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top), count: 3)

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 4) {
        Text("내 칭호")
          .wepliFont(.headline)
          .foregroundStyle(WePLiColor.textPrimary)
          .accessibilityAddTraits(.isHeader)
        Text("눌러서 대표 칭호로 설정하면 프로필과 명함에 붙어요")
          .wepliFont(.caption, weight: .light)
          .foregroundStyle(WePLiColor.textTertiary)
      }
      self.preview.padding(.top, 14)
      LazyVGrid(columns: self.columns, spacing: 14) {
        ForEach(self.board.titles) { title in
          TitleCell(title: title, isRepresentative: title.id == self.board.representativeID) {
            self.onTap(title.id)
          }
        }
      }
      .padding(.top, 14)
    }
    .padding(.horizontal, 20)
  }

  /// 대표 칭호가 붙은 모습 — 아바타 · 이름 · 칭호 칩
  private var preview: some View {
    HStack(spacing: 10) {
      Circle().fill(WePLiColor.imagePlaceholder).frame(width: 36, height: 36).accessibilityHidden(true)
      Text(self.board.nickname).wepliFont(.body, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
      if let title = self.board.representative {
        Text(title.name)
          .wepliFont(.caption, weight: .bold)
          .foregroundStyle(WePLiColor.accent)
          .padding(.horizontal, 10)
          .frame(height: 24)
          .background(WePLiColor.chipOn, in: Capsule())
      }
    }
    .accessibilityElement(children: .combine)
  }
}

private struct TitleCell: View {
  let title: UserTitle
  let isRepresentative: Bool
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      VStack(spacing: 6) {
        self.badge
        Text(self.title.name)
          .wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
          .lineLimit(1)
        Text(self.title.conditionLine)
          .font(.custom(WePLiFont.Weight.regular.postScriptName, size: 11, relativeTo: .caption2))
          .foregroundStyle(WePLiColor.textQuaternary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    // 못 얻은 칭호는 눌러도 아무 일도 없다(원본)
    .disabled(!self.title.isEarned)
    .accessibilityElement(children: .combine)
    .accessibilityValue(self.title.isEarned ? (self.isRepresentative ? "대표 칭호" : "얻음") : "아직 못 얻음")
    .accessibilityAddTraits(self.isRepresentative ? [.isButton, .isSelected] : .isButton)
  }

  private var badge: some View {
    Circle()
      .fill(WePLiColor.surface2)
      .overlay {
        Circle().strokeBorder(
          self.title.isEarned ? WePLiColor.accent.opacity(0.55) : Color.white.opacity(0.08),
          lineWidth: 1
        )
      }
      .overlay {
        Image(systemName: self.title.icon.systemName)
          .font(.system(size: self.title.isEarned ? 24 : 22, weight: .regular))
          .foregroundStyle(self.title.isEarned ? WePLiColor.accent : WePLiColor.textLocked)
      }
      .frame(width: 60, height: 60)
      .padding(2)
      .background {
        if self.isRepresentative {
          Circle().fill(WePLiGradient.vsRing)
        }
      }
      .frame(width: 64, height: 64)
      .accessibilityHidden(true)
  }
}
