import SwiftUI

// UI-3g 「노래 공유 컴포넌트」 — 255×354, 모서리 10. 앨범 아트 전체 배경 · 날짜 · 프로필 · 곡 정보 · 진행 바
// 이미지로 저장할 때도 이 뷰를 그대로 그린다(ImageRenderer).

struct SongShareCardView: View {
  static let size = CGSize(width: 255, height: 354)

  let card: SongShareCard

  var body: some View {
    ZStack {
      self.artwork
      VStack(spacing: 0) {
        LinearGradient(colors: [.black.opacity(0.45), .black.opacity(0)], startPoint: .top, endPoint: .bottom)
          .frame(height: 130)
        Spacer(minLength: 0)
        LinearGradient(colors: [.black.opacity(0), .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
          .frame(height: 150)
      }
      VStack(spacing: 0) {
        HStack(alignment: .top) {
          self.dateBlock
          Spacer(minLength: 8)
          if let name = self.card.sharerName {
            self.profilePill(name).padding(.trailing, -6)
          }
        }
        .padding(.top, 26)
        Spacer(minLength: 0)
        self.songInfo.padding(.bottom, 20)
      }
      .padding(.horizontal, 20)
    }
    .frame(width: Self.size.width, height: Self.size.height)
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(self.card.title), \(self.card.artist) 공유 카드")
  }

  /// 미결정 — 앨범 아트 URL이 아직 없어 자리 표시 아트를 쓴다
  private var artwork: some View {
    WePLiColor.surface4
      .overlay {
        Image(systemName: "music.note")
          .font(.system(size: 64, weight: .light))
          .foregroundStyle(WePLiColor.textQuaternary)
      }
  }

  private var dateBlock: some View {
    VStack(spacing: 4) {
      // 원본은 Pretendard Thin(100)이지만 번들에 없어 가장 가는 Light를 쓴다
      Text(self.card.day)
        .font(.custom(WePLiFont.Weight.light.postScriptName, fixedSize: 48))
        .monospacedDigit()
        .frame(height: 48)
      Text(self.card.month)
        .font(.custom(WePLiFont.Weight.light.postScriptName, fixedSize: 20))
        .frame(height: 26)
    }
    .foregroundStyle(.white)
    .frame(width: 52)
  }

  private func profilePill(_ name: String) -> some View {
    HStack(spacing: 6) {
      Circle()
        .fill(WePLiColor.surface2)
        .frame(width: 24, height: 24)
        .overlay {
          Image(systemName: "person.fill")
            .font(.system(size: 11))
            .foregroundStyle(WePLiColor.textQuaternary)
        }
      VStack(alignment: .leading, spacing: 2) {
        Text(name)
          .font(.custom(WePLiFont.Weight.medium.postScriptName, fixedSize: 10))
          .foregroundStyle(WePLiColor.textPrimary)
        if let persona = self.card.sharerPersona {
          Text(persona)
            .font(.custom(WePLiFont.Weight.light.postScriptName, fixedSize: 8))
            .foregroundStyle(WePLiColor.textPrimary.opacity(0.75))
        }
      }
      .lineLimit(1)
    }
    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 12))
    .frame(height: 32)
    .background(Color.white.opacity(0.2), in: Capsule())
  }

  private var songInfo: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .bottom) {
        VStack(alignment: .leading, spacing: 2) {
          Text(self.card.title)
            .font(.custom(WePLiFont.Weight.semibold.postScriptName, fixedSize: 14))
            .foregroundStyle(.white)
          Text(self.card.artist)
            .font(.custom(WePLiFont.Weight.regular.postScriptName, fixedSize: 10))
            .foregroundStyle(WePLiColor.textMuted)
        }
        .lineLimit(1)
        Spacer(minLength: 8)
        HStack(spacing: 3) {
          ForEach(0 ..< 3, id: \.self) { _ in
            Circle().fill(WePLiColor.textMuted).frame(width: 3, height: 3)
          }
        }
        .padding(.bottom, 4)
      }
      ZStack(alignment: .leading) {
        Rectangle().fill(WePLiColor.textMuted.opacity(0.2)).frame(width: 150, height: 2)
        Rectangle().fill(WePLiColor.textMuted).frame(width: 28, height: 2)
      }
    }
  }
}

extension SongShareCardView {
  /// 저장 · 공유용 PNG — 3배율
  @MainActor
  static func png(_ card: SongShareCard) -> Data? {
    let renderer = ImageRenderer(content: SongShareCardView(card: card))
    renderer.scale = 3
    return renderer.uiImage?.pngData()
  }
}

#Preview {
  SongShareCardView(card: SongShareCard(
    songID: "1",
    title: "소년, 길을 걷다",
    artist: "이승기",
    sharerName: "김동",
    sharerPersona: "멜로디 메모리즈",
    today: .now
  ))
  .padding(40)
  .background(.black)
}
