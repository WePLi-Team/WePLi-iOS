import SwiftUI

// UI-3c 구성 요소 — 커버 헤더 · 순위 행 · 곡 없음 카드 · 글래스 캡슐 버튼

struct RelayDetailHeader: View {
  let detail: RelayDetail
  let display: RelayDisplayState

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
        Text("RelayList")
          .wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(WePLiColor.accent)
        Text(self.detail.title)
          .wepliFont(.title1)
          .foregroundStyle(Color.white)
          .fixedSize(horizontal: false, vertical: true)
        Text("\(self.detail.openedOn) • 총 \(self.display == .empty ? 0 : self.detail.totalSongCount)곡")
          .wepliFont(.subheadline, weight: .light)
          .foregroundStyle(WePLiColor.textSecondary)
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 6)
    }
    .frame(height: RelayDetailView.Metric.coverHeight)
    .clipped()
  }
}

struct RankedSongRow: View {
  let song: RankedSong
  let onPlay: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      RoundedRectangle(cornerRadius: 4)
        .fill(WePLiColor.surface4)
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
          .foregroundStyle(WePLiColor.textPrimary)
          .frame(width: 36, height: 44)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("\(self.song.title) 미리듣기")
    }
    .frame(height: RelayDetailView.Metric.rowHeight)
    .accessibilityElement(children: .contain)
  }
}

struct RelayEmptySongsCard: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "music.note.list")
        .font(.system(size: 22))
        .foregroundStyle(WePLiColor.accent)
        .frame(width: 56, height: 56)
        .background(WePLiColor.accentStrong.opacity(0.14), in: Circle())
        .padding(.bottom, 6)
      Text("아직 등록된 곡이 없어요.")
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.textPrimary)
      Text("주제에 맞는 명곡을 다른 사람들에게 추천해주세요!")
        .wepliFont(.subheadline)
        .foregroundStyle(WePLiColor.textTertiary)
    }
    .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 20)
    .padding(.top, 36)
    .padding(.bottom, 28)
    .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 22))
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
