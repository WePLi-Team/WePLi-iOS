import SwiftUI

// UI-3b 카드(2026-10-15 갱신) — 카드 상자 없이 아트 300(모서리 16) + 그림자, 아래 곡명 · 가수
// 끌면 아트 전체를 덮는 표시: 어울려요 = 라벤더 그라디언트 + 「어울려요」 · 별로예요 = 검정 60% + 「별로예요」

struct VoteCard: View {
  let candidate: VoteCandidate
  let onPlay: (() -> Void)?
  var fitsOpacity: Double = 0
  var missOpacity: Double = 0

  enum Metric {
    static let art: CGFloat = 300
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      VoteArt(fitsOpacity: self.fitsOpacity, missOpacity: self.missOpacity)
        .overlay(alignment: .bottomTrailing) {
          if let onPlay = self.onPlay {
            Button(action: onPlay) {
              Image(systemName: "play.fill")
                .font(.system(size: 15))
                .foregroundStyle(WePLiColor.textPrimary)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .padding(10)
            .accessibilityLabel("\(self.candidate.title) 미리듣기")
          }
        }
      Text(self.candidate.title)
        .wepliFont(.headline)
        .foregroundStyle(WePLiColor.textPrimary)
        .lineLimit(1)
        .padding(.top, 14)
        .padding(.horizontal, 4)
      Text(self.candidate.artist)
        .wepliFont(.subheadline)
        .foregroundStyle(WePLiColor.textTertiary)
        .lineLimit(1)
        .padding(.horizontal, 4)
    }
    .frame(width: Metric.art)
  }
}

/// 앨범 아트 300 — 끄는 방향에 따라 아트 전체를 덮는다
struct VoteArt: View {
  var fitsOpacity: Double = 0
  var missOpacity: Double = 0

  var body: some View {
    RoundedRectangle(cornerRadius: 16)
      .fill(WePLiColor.imagePlaceholder)
      .frame(width: VoteCard.Metric.art, height: VoteCard.Metric.art)
      .overlay {
        Image(systemName: "music.note")
          .font(.system(size: 48, weight: .light))
          .foregroundStyle(WePLiColor.textQuaternary)
      }
      .overlay(alignment: .bottomLeading) {
        ZStack(alignment: .bottomLeading) {
          LinearGradient(
            stops: [
              .init(color: WePLiColor.accent.opacity(0), location: 0.3),
              .init(color: WePLiColor.accentStrong.opacity(0.55), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
          )
          Text("어울려요")
            .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 20, relativeTo: .title3))
            .foregroundStyle(WePLiColor.textPrimary)
            .padding(18)
        }
        .opacity(self.fitsOpacity)
      }
      .overlay(alignment: .bottomTrailing) {
        ZStack(alignment: .bottomTrailing) {
          Color.black.opacity(0.6)
          Text("별로예요")
            .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 20, relativeTo: .title3))
            .foregroundStyle(WePLiColor.textSecondary)
            .padding(18)
        }
        .opacity(self.missOpacity)
      }
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .shadow(color: .black.opacity(0.55), radius: 30, y: 24)
      .accessibilityHidden(true)
  }
}
