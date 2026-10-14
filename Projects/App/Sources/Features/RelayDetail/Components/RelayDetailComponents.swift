import SwiftUI

// UI-3c 구성 요소 — 커버 헤더 · 순위 행 · 곡 없음 카드 · 글래스 캡슐 버튼

struct RelayDetailHeader: View {
  let detail: RelayDetail
  let display: RelayDisplayState
  let now: Date

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      // 커버 사진은 백엔드가 정해지면 붙인다
      LinearGradient(
        colors: [WePLiColor.accentChip.opacity(0.45), WePLiColor.surface1],
        startPoint: .topTrailing,
        endPoint: .bottomLeading
      )
      LinearGradient(
        stops: [.init(color: .black, location: 0), .init(color: .black.opacity(0), location: 0.74)],
        startPoint: .bottom,
        endPoint: .top
      )
      VStack {
        LinearGradient(colors: [.black.opacity(0.45), .clear], startPoint: .top, endPoint: .bottom)
          .frame(height: 140)
        Spacer()
      }
      VStack(alignment: .leading, spacing: 8) {
        // 2026-10-15: 상태별 라벨 — 곡 없음도 「진행 중」
        Text(self.display == .completed ? "RelayList · 완성" : "RelayList · 진행 중")
          .wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(self.display == .completed ? WePLiColor.textTertiary : WePLiColor.accent)
        Text(self.detail.title)
          .wepliFont(.title1)
          .foregroundStyle(Color.white)
          .fixedSize(horizontal: false, vertical: true)
        self.meta
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 6)
    }
    .frame(height: RelayDetailView.Metric.coverHeight)
    .clipped()
  }

  /// 진행 중 · 곡 없음: 「● {남은 시간} 남음 · 총 N곡 · 2024.05.03 시작」, 완성: 「총 N곡 · 2024.05.03 시작」
  private var meta: some View {
    let count = self.display == .empty ? 0 : self.detail.totalSongCount
    let rest = Text("총 \(count)곡 · \(self.detail.openedOn) 시작")
      .font(.custom(WePLiFont.Weight.light.postScriptName, size: 14, relativeTo: .subheadline))
      .foregroundColor(WePLiColor.textSecondary)
    return HStack(spacing: 6) {
      if let endsAt = self.detail.endsAt, self.display != .completed {
        Circle().fill(WePLiGradient.vsRing).frame(width: 7, height: 7)
        (Text("\(CountdownFormatter.string(from: self.now, to: endsAt)) 남음")
          .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 14, relativeTo: .subheadline))
          .foregroundColor(WePLiColor.accent)
          + Text(" · ").foregroundColor(WePLiColor.textDisabled)
          + rest)
          .monospacedDigit()
      } else {
        rest
      }
    }
    .accessibilityElement(children: .combine)
  }
}

struct RankedSongRow: View {
  let song: RankedSong
  let onPlay: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      RoundedRectangle(cornerRadius: 4)
        .fill(WePLiColor.imagePlaceholder)
        .frame(width: 52, height: 52)
        .overlay {
          Image(systemName: "music.note")
            .font(.system(size: 16))
            .foregroundStyle(WePLiColor.textQuaternary)
        }
      Text("\(self.song.rank)")
        .wepliFont(.body, weight: self.song.isTop ? .bold : .medium)
        .foregroundStyle(self.song.isTop ? WePLiColor.accent : WePLiColor.textPrimary.opacity(0.8))
        .monospacedDigit()
        .frame(width: 18)
      VStack(alignment: .leading, spacing: 2) {
        Text(self.song.title)
          .wepliFont(.body)
          .foregroundStyle(Color.white)
          .lineLimit(1)
        Text(self.song.artist)
          .wepliFont(.footnote, weight: .light)
          .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Button(action: self.onPlay) {
        Image(systemName: "play")
          .font(.system(size: 13))
          .foregroundStyle(WePLiColor.textMuted)
          .frame(width: 36, height: 44)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("\(self.song.title) 미리듣기")
    }
    .frame(height: RelayDetailView.Metric.rowHeight)
    .accessibilityElement(children: .contain)
  }
}

/// 곡 없음 — 글자만(2026-10-15 갱신)
struct RelayEmptySongsCard: View {
  var body: some View {
    VStack(spacing: 6) {
      Text("아직 추천된 곡이 없어요")
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.textPrimary)
      Text("첫 곡을 추천하면 순위가 여기서 시작돼요")
        .wepliFont(.subheadline, weight: .light)
        .foregroundStyle(WePLiColor.textTertiary)
    }
    .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity)
    .padding(.top, 32)
    .padding(.bottom, 12)
  }
}

/// 글래스 캡슐 보조 버튼(높이 54) — 「노래 추천」 · 「내 플리에 담기」
struct RelayGlassButton: View {
  let title: String
  let systemImage: String
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      HStack(spacing: 6) {
        Image(systemName: self.systemImage)
          .font(.system(size: 14, weight: .semibold))
        Text(self.title)
          .wepliFont(.callout, weight: .semibold)
      }
      .foregroundStyle(WePLiColor.textPrimary)
      .frame(maxWidth: .infinity)
      .frame(height: RelayDetailView.Metric.buttonHeight)
      .wepliGlass(in: Capsule())
    }
    .buttonStyle(.plain)
  }
}
