import SwiftUI

// UI-3b 카드 — 폭 300 · 모서리 26 · 아트 276(모서리 16) · 재생 44 · 도장(어울려요 #A4FFFF -12° / 별로예요 #FE82DB +12°)

struct VoteCard: View {
  let candidate: VoteCandidate
  let onPlay: (() -> Void)?

  enum Metric {
    static let width: CGFloat = 300
    static let art: CGFloat = 276
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      RoundedRectangle(cornerRadius: 16)
        .fill(WePLiColor.surface4)
        .frame(width: Metric.art, height: Metric.art)
        .overlay {
          Image(systemName: "music.note")
            .font(.system(size: 48, weight: .light))
            .foregroundStyle(WePLiColor.textQuaternary)
        }
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
    .padding(.horizontal, 12)
    .padding(.top, 12)
    .padding(.bottom, 18)
    .frame(width: Metric.width)
    .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 26))
    .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
    .shadow(color: .black.opacity(0.5), radius: 30, y: 24)
  }
}

struct VoteStamp: View {
  let choice: VoteChoice
  let opacity: Double

  var body: some View {
    let isFits = self.choice == .fits
    let color = isFits ? WePLiColor.positive : WePLiColor.highlight
    Text(isFits ? "어울려요" : "별로예요")
      .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 18))
      .foregroundStyle(color)
      .padding(.horizontal, 10)
      .padding(.vertical, 4)
      .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(color, lineWidth: 2.5))
      .rotationEffect(.degrees(isFits ? -12 : 12))
      .padding(.top, 16)
      .padding(.horizontal, 14)
      .opacity(self.opacity)
      .accessibilityHidden(true)
  }
}
