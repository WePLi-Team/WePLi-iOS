import SwiftUI

// UI-8b v2 대결 반쪽 — 앨범 아트 전체 배경(흐림 없음) + 반쪽마다 다른 어두운 그라디언트
// 글자: 「추천 {사람}」 12 Light #D8D8DD · 곡명 26 SemiBold · 「#가수」 14 #C8CFFF
// 고르면 고른 쪽 아트 1.04배, 다른 쪽 0.94배 · 투명도 0.35(동작 줄이기가 켜져 있으면 크기는 그대로)

struct WorldCupHalf: View {
  let song: WorldCupSong
  let side: WorldCupSide
  let picked: WorldCupSide?
  let onTap: () -> Void

  @Environment(\.accessibilityReduceMotion)
  private var reduceMotion

  var body: some View {
    Button(action: self.onTap) {
      ZStack(alignment: self.side == .top ? .bottomLeading : .topLeading) {
        WePLiColor.imagePlaceholder
          .overlay {
            Image(systemName: "music.note")
              .font(.system(size: 64, weight: .ultraLight))
              .foregroundStyle(WePLiColor.textQuaternary.opacity(0.5))
          }
          .scaleEffect(self.reduceMotion ? 1 : self.scale)
          .animation(.easeOut(duration: 0.3), value: self.picked)
        LinearGradient(stops: self.gradientStops, startPoint: .top, endPoint: .bottom)
        self.label
          .padding(.leading, 20)
          .padding(.trailing, 80)
          .padding(self.side == .top ? .bottom : .top, self.side == .top ? 34 : 40)
      }
      .clipped()
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .opacity(self.isDimmed ? 0.35 : 1)
    .animation(.easeOut(duration: 0.22), value: self.picked)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(self.song.title), \(self.song.artist), 추천 \(self.song.recommender)")
    .accessibilityHint("이 곡을 고릅니다")
  }

  private var label: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("추천 \(self.song.recommender)")
        .wepliFont(.caption, weight: .light)
        .foregroundStyle(WePLiColor.textMuted)
      Text(self.song.title)
        .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 26, relativeTo: .title))
        .foregroundStyle(WePLiColor.textPrimary)
        .lineLimit(2)
      Text("#\(self.song.artist)")
        .wepliFont(.subheadline)
        .foregroundStyle(WePLiColor.accent)
    }
  }

  private var scale: CGFloat {
    switch self.picked {
    case nil: 1
    case self.side: 1.04
    default: 0.94
    }
  }

  private var isDimmed: Bool {
    self.picked != nil && self.picked != self.side
  }

  private var gradientStops: [Gradient.Stop] {
    switch self.side {
    case .top:
      [
        .init(color: .black.opacity(0.78), location: 0),
        .init(color: .black.opacity(0.5), location: 0.3),
        .init(color: .black.opacity(0.12), location: 0.55),
        .init(color: .black.opacity(0.88), location: 1),
      ]
    case .bottom:
      [
        .init(color: .black.opacity(0.88), location: 0),
        .init(color: .black.opacity(0.1), location: 0.4),
        .init(color: .black.opacity(0.05), location: 0.62),
        .init(color: .black.opacity(0.85), location: 1),
      ]
    }
  }
}

/// 가운데 VS — 56 원, 무지개빛 테두리 · 검은 안쪽 · 「VS」 15 ExtraBold
struct WorldCupVersusBadge: View {
  var body: some View {
    Circle()
      .fill(WePLiGradient.vsRing)
      .frame(width: 56, height: 56)
      .overlay {
        Circle()
          .fill(WePLiColor.background)
          .frame(width: 52, height: 52)
          .overlay {
            Text("VS")
              .font(.custom(WePLiFont.Weight.bold.postScriptName, fixedSize: 15))
              .tracking(1)
              .foregroundStyle(WePLiColor.textPrimary)
          }
      }
      .allowsHitTesting(false)
      .accessibilityHidden(true)
  }
}
