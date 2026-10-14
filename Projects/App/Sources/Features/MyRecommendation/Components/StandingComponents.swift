import SwiftUI

// UI-8a(v2) 구성 요소 — 순위 행 · 역전 알림 배너

/// 순위 행 — 높이 64, 순위(내 곡이면 #C8CFFF) · ▲#A4FFFF ▼– #6B6B7C · 아트 48 · 곡명 · 「추천 ○○」 · 「내 곡」
struct StandingRow: View {
  let rank: Int
  let song: StandingSong

  var body: some View {
    HStack(spacing: 12) {
      VStack(spacing: 0) {
        Text("\(self.rank)")
          .wepliFont(.body, weight: .semibold)
          .monospacedDigit()
          .foregroundStyle(self.tint)
          .contentTransition(.numericText())
        Text(self.change.text)
          .font(.custom(
            self.change == .same ? WePLiFont.Weight.regular.postScriptName : WePLiFont.Weight.bold.postScriptName,
            fixedSize: 10
          ))
          .foregroundStyle(self.changeColor)
      }
      .frame(width: 26)
      RoundedRectangle(cornerRadius: 4)
        .fill(WePLiColor.surface2)
        .frame(width: 48, height: 48)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 3) {
        Text(self.song.title)
          .wepliFont(.body)
          .foregroundStyle(self.tint)
          .lineLimit(1)
        HStack(spacing: 5) {
          Circle().fill(WePLiColor.surface2).frame(width: 16, height: 16)
          Text("추천 \(self.song.recommender)")
            .wepliFont(.caption, weight: .light)
            .foregroundStyle(WePLiColor.textTertiary)
            .lineLimit(1)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      if self.song.isMine {
        Text("내 곡")
          .wepliFont(.caption, weight: .semibold)
          .foregroundStyle(WePLiColor.accent)
      }
    }
    .padding(.leading, 20)
    .padding(.trailing, 16)
    .frame(height: 64)
    .accessibilityElement(children: .combine)
  }

  private var change: RankChange {
    RankChange(startRank: self.song.startRank, rank: self.rank)
  }

  private var tint: Color {
    self.song.isMine ? WePLiColor.accent : WePLiColor.textPrimary
  }

  private var changeColor: Color {
    if case .up = self.change {
      return WePLiColor.positive
    }
    return WePLiColor.textDisabled
  }
}

/// 위에서 내려오는 역전 알림 — 모서리 22, 글래스, 로고 타일 38 · 제목 14 Bold · 본문 13 · 「지금」
struct ReversalBannerView: View {
  let banner: ReversalBanner

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      RoundedRectangle(cornerRadius: 9)
        .fill(WePLiColor.background)
        .frame(width: 38, height: 38)
        .overlay {
          // 미결정 — 로고 이미지가 번들에 없어 음표로 대신한다
          Image(systemName: "music.note")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(WePLiColor.accent)
        }
        .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5))
      VStack(alignment: .leading, spacing: 2) {
        Text(self.banner.title)
          .wepliFont(.subheadline, weight: .bold)
          .foregroundStyle(WePLiColor.textPrimary)
        Text(self.banner.body)
          .wepliFont(.footnote)
          .foregroundStyle(WePLiColor.textMuted)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Text("지금")
        .wepliFont(.caption)
        .foregroundStyle(WePLiColor.textQuaternary)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .wepliGlass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    .shadow(color: .black.opacity(0.45), radius: 15, y: 12)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.updatesFrequently)
  }
}
