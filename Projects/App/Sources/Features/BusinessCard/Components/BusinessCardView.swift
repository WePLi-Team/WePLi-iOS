import SwiftUI

// UI-2e 명함 카드 — 247×354, 모서리 13, 면 rgb(3,3,3) · 테두리 #2F2F38
// 날짜(오른쪽 위) · 닉네임 22 · 성향 12 #C8CFFF · 한 줄 소개 13 Light · 디스크 180(오른쪽으로 잘림) · Best Pick · Instagram

struct BusinessCardView: View {
  static let size = CGSize(width: 247, height: 354)

  let card: BusinessCard
  var isBlurred = false

  var body: some View {
    ZStack(alignment: .topLeading) {
      WePLiColor.cardFace
      self.header
        .padding(.leading, 20)
        .padding(.trailing, 18)
        .padding(.top, 20)
      self.texts
        .frame(width: 208, alignment: .leading)
        .offset(x: 20, y: 62)
      BusinessCardDisc(size: 180, ring: 2.6, hole: 13, centerRing: 28.7)
        .offset(x: 117, y: 142)
      if let song = self.card.song {
        BestPickBubble(song: song)
          .offset(x: 17, y: 209)
      }
      if let instagram = self.card.instagram {
        HStack(spacing: 5) {
          InstagramMark(size: 14)
          Text(instagram)
            .font(.custom(WePLiFont.Weight.light.postScriptName, fixedSize: 12))
            .foregroundStyle(WePLiColor.textMuted)
            .lineLimit(1)
        }
        .offset(x: 20, y: 322)
      }
      if self.isBlurred {
        Rectangle().fill(.ultraThinMaterial).overlay(WePLiColor.cardFace.opacity(0.45))
      }
    }
    .frame(width: Self.size.width, height: Self.size.height)
    .clipShape(RoundedRectangle(cornerRadius: 13))
    .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(WePLiColor.cardLine, lineWidth: 1))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(self.accessibilityText)
  }

  private var header: some View {
    HStack(alignment: .top) {
      // 미결정 — 로고 이미지가 번들에 없어 글자로 대신한다
      Text("WePLi")
        .font(.custom(WePLiFont.Weight.bold.postScriptName, fixedSize: 10))
        .foregroundStyle(WePLiColor.textPrimary)
        .padding(.top, 3)
      Spacer()
      VStack(alignment: .trailing, spacing: 0) {
        Text(self.card.day)
          .font(.custom(WePLiFont.Weight.bold.postScriptName, fixedSize: 20))
          .monospacedDigit()
          .foregroundStyle(WePLiColor.textPrimary)
        Text(self.card.month)
          .font(.custom(WePLiFont.Weight.semibold.postScriptName, fixedSize: 9))
          .tracking(1)
          .foregroundStyle(WePLiColor.textQuaternary)
      }
    }
  }

  private var texts: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(self.card.nickname)
        .font(.custom(WePLiFont.Weight.semibold.postScriptName, fixedSize: 22))
        .foregroundStyle(WePLiColor.textPrimary)
        .lineLimit(1)
      if let persona = self.card.persona {
        Text(persona)
          .font(.custom(WePLiFont.Weight.semibold.postScriptName, fixedSize: 12))
          .foregroundStyle(WePLiColor.accent)
      }
      Text(self.card.oneLiner)
        .font(.custom(WePLiFont.Weight.light.postScriptName, fixedSize: 13))
        .foregroundStyle(WePLiColor.textTertiary)
        .padding(.top, 8)
    }
  }

  private var accessibilityText: String {
    var parts = ["\(self.card.nickname)의 명함", self.card.oneLiner]
    if let song = self.card.song {
      parts.append("Best Pick \(song.title), \(song.artist)")
    }
    if let instagram = self.card.instagram {
      parts.append("Instagram \(instagram)")
    }
    return parts.joined(separator: ", ")
  }
}

extension BusinessCardView {
  /// 저장 · 공유용 PNG — 3배율
  @MainActor
  static func png(_ card: BusinessCard) -> Data? {
    let renderer = ImageRenderer(content: BusinessCardView(card: card))
    renderer.scale = 3
    return renderer.uiImage?.pngData()
  }
}

/// 레코드 디스크 — 바깥 링 #2F2F38 · 가운데 구멍 · 강조 링. 앨범 아트가 생기면 안쪽에 입힌다.
struct BusinessCardDisc: View {
  let size: CGFloat
  let ring: CGFloat
  let hole: CGFloat
  let centerRing: CGFloat

  var body: some View {
    ZStack {
      Circle().fill(WePLiColor.cardLine)
      Circle()
        .fill(
          AngularGradient(
            colors: [
              WePLiColor.surface4,
              WePLiColor.surface2,
              WePLiColor.surface4,
              WePLiColor.surface2,
              WePLiColor.surface4,
            ],
            center: .center
          )
        )
        .padding(self.ring)
      Circle().fill(WePLiColor.cardFace).frame(width: self.hole * 2, height: self.hole * 2)
      Circle()
        .strokeBorder(WePLiColor.accent.opacity(0.8), lineWidth: 1.5)
        .frame(width: self.centerRing, height: self.centerRing)
    }
    .frame(width: self.size, height: self.size)
    .accessibilityHidden(true)
  }
}

/// 「Best Pick」 말풍선 — 디스크 쪽을 가리키는 꼬리
private struct BestPickBubble: View {
  let song: ComposeTrack

  var body: some View {
    HStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 2) {
        Text("Best Pick")
          .font(.custom(WePLiFont.Weight.semibold.postScriptName, fixedSize: 7))
          .tracking(0.4)
          .foregroundStyle(WePLiColor.accent)
        Text(self.song.title)
          .font(.custom(WePLiFont.Weight.medium.postScriptName, fixedSize: 11))
          .foregroundStyle(WePLiColor.textPrimary)
          .lineLimit(1)
        Text(self.song.artist)
          .font(.custom(WePLiFont.Weight.light.postScriptName, fixedSize: 8))
          .foregroundStyle(WePLiColor.textTertiary)
          .lineLimit(1)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(WePLiColor.cardLine, in: RoundedRectangle(cornerRadius: 6))
      BubbleTail()
        .fill(WePLiColor.cardLine)
        .frame(width: 7, height: 12)
    }
  }
}

private struct BubbleTail: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}

/// Instagram 표시 — 그라디언트 둥근 사각형 안에 흰 원
struct InstagramMark: View {
  let size: CGFloat

  var body: some View {
    RoundedRectangle(cornerRadius: self.size * 0.26)
      .fill(WePLiGradient.storyTile)
      .frame(width: self.size, height: self.size)
      .overlay {
        Circle()
          .strokeBorder(.white, lineWidth: self.size * 0.093)
          .frame(width: self.size * 0.53, height: self.size * 0.53)
      }
      .accessibilityHidden(true)
  }
}

#Preview {
  BusinessCardView(card: BusinessCard(
    nickname: "김동",
    persona: "멜로디 메모리즈",
    oneLiner: BusinessCard.defaultOneLiner,
    song: ComposeTrack(id: "1", title: "소년, 길을 걷다", artist: "이승기"),
    instagram: "dongx._.2",
    day: "15",
    month: "OCT"
  ))
  .padding(40)
  .background(.black)
}
