import SwiftUI

// UI-5b 헤더 — 이미지 440 · 위 스크림 140(검정 45% → 0) · 아래 스크림 220(검정 → 0)
// 이름 34 Bold · 차트 라벨 13 SemiBold #C8CFFF · 좋아요 46(켜면 #FE82DB) · 전체 재생 56(#C8CFFF)

struct ArtistHero: View {
  static let height: CGFloat = 440

  let artist: ArtistDetail
  let onLike: () -> Void
  let onPlayAll: () -> Void

  var body: some View {
    ZStack(alignment: .bottom) {
      // 미결정 — 아티스트 이미지(원본 노트 03: Apple Music 아티스트 이미지)가 아직 없어 자리 표시
      WePLiColor.imagePlaceholder
        .overlay {
          Image(systemName: "person.fill")
            .font(.system(size: 96, weight: .light))
            .foregroundStyle(WePLiColor.textQuaternary)
        }
        .accessibilityHidden(true)
      VStack(spacing: 0) {
        LinearGradient(colors: [.black.opacity(0.45), .black.opacity(0)], startPoint: .top, endPoint: .bottom)
          .frame(height: 140)
        Spacer(minLength: 0)
        LinearGradient(colors: [.black.opacity(0), .black], startPoint: .top, endPoint: .bottom)
          .frame(height: 220)
      }
      self.info
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    .frame(height: Self.height)
    .clipped()
  }

  private var info: some View {
    HStack(alignment: .bottom, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text("위플리 차트 진입 \(self.artist.chartEntryCount)곡")
          .wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(WePLiColor.accent)
        Text(self.artist.name)
          .wepliFont(.largeTitle)
          .tracking(-0.3)
          .foregroundStyle(WePLiColor.textPrimary)
          .lineLimit(2)
          .accessibilityAddTraits(.isHeader)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Button(action: self.onLike) {
        Image(systemName: self.artist.isLiked ? "heart.fill" : "heart")
          .font(.system(size: 20, weight: .medium))
          .foregroundStyle(self.artist.isLiked ? WePLiColor.highlight : WePLiColor.textPrimary)
          .frame(width: 46, height: 46)
          .wepliGlass(in: Circle())
          .contentShape(Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(self.artist.isLiked ? "좋아요 취소" : "좋아요")

      Button(action: self.onPlayAll) {
        Image(systemName: "play.fill")
          .font(.system(size: 20))
          .foregroundStyle(WePLiColor.textOnCTA)
          .offset(x: 1.5)
          .frame(width: 56, height: 56)
          .background(WePLiColor.accent, in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("전체 재생")
    }
  }
}
