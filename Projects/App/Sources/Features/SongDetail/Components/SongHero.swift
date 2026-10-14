import SwiftUI

// UI-2d 히어로 — 블러 배경 · 아트 264(모서리 14) · 곡명 26 Bold · 아티스트 17 Medium #C8CFFF · 버튼 2개(50) · 진행 바(4)

struct SongHero: View {
  let song: SongDetail
  let isPlaying: Bool
  let position: Int
  let onPreview: () -> Void
  let onOpenInMusic: () -> Void
  let onArtist: () -> Void

  var body: some View {
    VStack(spacing: 22) {
      RoundedRectangle(cornerRadius: 14)
        .fill(WePLiColor.imagePlaceholder)
        .frame(width: 264, height: 264)
        .overlay {
          Image(systemName: "music.note")
            .font(.system(size: 54, weight: .light))
            .foregroundStyle(WePLiColor.textQuaternary)
        }
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.55), radius: 30, y: 24)
        .accessibilityHidden(true)

      VStack(spacing: 6) {
        Text(self.song.title)
          .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 26, relativeTo: .title))
          .foregroundStyle(WePLiColor.textPrimary)
          .multilineTextAlignment(.center)
        Button(action: self.onArtist) {
          Text(self.song.artist)
            .wepliFont(.button, weight: .medium)
            .foregroundStyle(WePLiColor.accent)
        }
        .buttonStyle(.plain)
        Text(self.song.meta)
          .wepliFont(.footnote)
          .foregroundStyle(WePLiColor.textQuaternary)
      }

      VStack(spacing: 10) {
        HStack(spacing: 10) {
          Button(action: self.onPreview) {
            Label(self.isPlaying ? "일시정지" : "미리듣기", systemImage: self.isPlaying ? "pause.fill" : "play.fill")
              .wepliFont(.body, weight: .semibold)
              .foregroundStyle(WePLiColor.textOnCTA)
              .frame(maxWidth: .infinity)
              .frame(height: 50)
              .background(Capsule().fill(WePLiGradient.cta))
          }
          .buttonStyle(.plain)
          Button(action: self.onOpenInMusic) {
            Label("Music에서 듣기", systemImage: "music.note")
              .wepliFont(.body, weight: .semibold)
              .foregroundStyle(WePLiColor.textPrimary)
              .frame(maxWidth: .infinity)
              .frame(height: 50)
              .background(WePLiColor.secondaryButtonFill, in: Capsule())
          }
          .buttonStyle(.plain)
        }
        self.progress
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 112)
    .background(alignment: .top) { self.blurredBackground }
  }

  private var progress: some View {
    VStack(spacing: 6) {
      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.14))
          RoundedRectangle(cornerRadius: 2)
            .fill(WePLiColor.accent)
            .frame(width: proxy.size.width * SongPreview.progress(self.position))
            .animation(.linear(duration: 1), value: self.position)
        }
      }
      .frame(height: 4)
      HStack {
        Text(SongPreview.elapsedText(self.position))
        Spacer()
        Text("미리듣기 30초")
        Spacer()
        Text(SongPreview.remainingText(self.position))
      }
      .wepliFont(.caption)
      .foregroundStyle(WePLiColor.textQuaternary)
      .monospacedDigit()
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("미리듣기 \(self.position)초 / 30초")
  }

  /// 앨범 아트 블러(60) — 사진이 붙기 전까지 라벤더 빛으로 대신한다
  private var blurredBackground: some View {
    ZStack {
      Circle()
        .fill(WePLiColor.accentChip.opacity(0.6))
        .frame(width: 520, height: 520)
        .blur(radius: 60)
        .offset(x: -40, y: -60)
      LinearGradient(
        stops: [
          .init(color: .black.opacity(0.15), location: 0),
          .init(color: .black.opacity(0.55), location: 0.55),
          .init(color: .black, location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    }
    .frame(height: 620)
    .clipped()
    .accessibilityHidden(true)
  }
}
