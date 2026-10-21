import SwiftUI

// UI-8f 큐레이터 탭 — 시즌 머리 · 보상 → 내 순위 캡슐 → 점수 얻는 법 → 시상대(2 · 1 · 3) → 4위부터 목록.
// 원본 맨 아래 옛 점수식 줄은 새 점수 기준과 달라 넣지 않는다(사용자 결정)

struct SeasonCuratorContent: View {
  let ranking: SeasonRanking
  let now: Date

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      self.header.padding(.horizontal, 20).padding(.top, 22)
      SeasonStandingCapsule(standing: self.ranking.me).padding(.horizontal, 20).padding(.top, 16)
      Text(SeasonText.howToScore)
        .wepliFont(.caption, weight: .light)
        .foregroundStyle(WePLiColor.textQuaternary)
        .padding(.horizontal, 24)
        .padding(.top, 10)
      SeasonPodium(entries: self.ranking.podium).padding(.horizontal, 20).padding(.top, 28)
      VStack(spacing: 0) {
        ForEach(self.ranking.list) { entry in
          SeasonRankRow(entry: entry)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .firstTextBaseline) {
        Text(self.ranking.seasonName).wepliFont(.headline).foregroundStyle(WePLiColor.textPrimary)
        Spacer(minLength: 8)
        Text(SeasonText.deadline(self.ranking.endsAt, now: self.now))
          .wepliFont(.footnote, weight: .light)
          .monospacedDigit()
          .foregroundStyle(WePLiColor.textTertiary)
      }
      Text(SeasonText.rewards).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textTertiary)
    }
  }
}

/// 내 순위 — 글래스 캡슐 62(8d 예측 카드와 같은 질감)
private struct SeasonStandingCapsule: View {
  let standing: SeasonRanking.Standing

  var body: some View {
    HStack(spacing: 12) {
      Circle().fill(WePLiColor.imagePlaceholder).frame(width: 44, height: 44).accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 1) {
        HStack(spacing: 4) {
          Text("\(self.standing.rank)위").wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
          if let change = SeasonText.change(self.standing.change) {
            Text(change).wepliFont(.caption).foregroundStyle(WePLiColor.positive)
          }
        }
        if let points = self.standing.pointsToTop100 {
          Text("TOP 100까지 \(SeasonText.score(points))점")
            .wepliFont(.caption, weight: .light)
            .foregroundStyle(WePLiColor.textTertiary)
        }
      }
      Spacer(minLength: 8)
      Text("\(SeasonText.score(self.standing.score))점")
        .wepliFont(.subheadline, weight: .semibold)
        .monospacedDigit()
        .foregroundStyle(WePLiColor.textPrimary)
    }
    .padding(.leading, 9)
    .padding(.trailing, 20)
    .frame(height: 62)
    .wepliGlass(in: Capsule())
    .accessibilityElement(children: .combine)
    .accessibilityLabel("내 순위")
  }
}

/// 상위 3명 — 2 · 1 · 3 순서, 1위만 홀로그램 고리 80. 칭호 · 「점」은 붙이지 않는다(원본)
private struct SeasonPodium: View {
  let entries: [SeasonRanking.Entry]

  var body: some View {
    HStack(alignment: .bottom, spacing: 10) {
      ForEach(self.ordered) { entry in
        self.cell(entry).frame(maxWidth: .infinity)
      }
    }
  }

  private var ordered: [SeasonRanking.Entry] {
    guard self.entries.count == 3 else { return self.entries }
    return [self.entries[1], self.entries[0], self.entries[2]]
  }

  private func cell(_ entry: SeasonRanking.Entry) -> some View {
    let isFirst = entry.rank == 1
    let size: CGFloat = entry.rank == 1 ? 74 : entry.rank == 2 ? 60 : 56
    return VStack(spacing: 6) {
      Text("\(entry.rank)")
        .font(.custom(WePLiFont.Weight.bold.postScriptName, size: isFirst ? 15 : 14, relativeTo: .subheadline))
        .foregroundStyle(isFirst ? WePLiColor.accent : WePLiColor.textTertiary)
      Circle()
        .fill(WePLiColor.imagePlaceholder)
        .frame(width: size, height: size)
        .padding(isFirst ? 3 : 0)
        .background {
          if isFirst {
            Circle().fill(WePLiGradient.vsRing)
          }
        }
        .accessibilityHidden(true)
      Text(entry.name).wepliFont(.footnote, weight: .semibold).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
      Text(SeasonText.score(entry.score))
        .wepliFont(.caption, weight: .light)
        .monospacedDigit()
        .foregroundStyle(isFirst ? WePLiColor.textMuted : WePLiColor.textTertiary)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(entry.rank)위 \(entry.name), \(entry.score)점")
  }
}

/// 4위부터 — 순위 · 아바타 36 · 이름 · 대표 칭호 · 점수, 높이 58
private struct SeasonRankRow: View {
  let entry: SeasonRanking.Entry

  var body: some View {
    HStack(spacing: 12) {
      Text("\(self.entry.rank)")
        .wepliFont(.body, weight: .bold)
        .monospacedDigit()
        .foregroundStyle(WePLiColor.textTertiary)
        .frame(width: 24)
      Circle().fill(WePLiColor.imagePlaceholder).frame(width: 36, height: 36).accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 1) {
        Text(self.entry.name).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
        if let title = self.entry.title {
          Text(title).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
        }
      }
      Spacer(minLength: 8)
      Text(SeasonText.score(self.entry.score))
        .wepliFont(.subheadline)
        .monospacedDigit()
        .foregroundStyle(WePLiColor.textMuted)
    }
    .frame(height: 58)
    .accessibilityElement(children: .combine)
  }
}
