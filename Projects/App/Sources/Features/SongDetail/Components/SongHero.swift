import SwiftUI

// UI-2d v2 히어로 — 가운데 아트 300(모서리 14)이 스크롤 104pt 동안 화면 폭까지 넓어지며 모서리 · 그림자가 사라지고
// 아래 58%가 검정에 녹는다. 제목은 가운데 정렬에서 커버 위 왼쪽 정렬로 바뀐다(원본 노트 01).

struct SongHero: View {
  let song: SongDetail
  /// 0(처음) – 1(스크롤 104pt)
  let progress: CGFloat

  enum Metric {
    static let height: CGFloat = 520
    static let artTop: CGFloat = 104
    static let artSize: CGFloat = 300
    /// 이만큼 스크롤하면 아트가 화면 폭이 된다
    static let collapse: CGFloat = 104
  }

  var body: some View {
    GeometryReader { proxy in
      let size = Metric.artSize + (proxy.size.width - Metric.artSize) * self.progress
      ZStack(alignment: .top) {
        self.blurredBackground
          .frame(width: proxy.size.width)
          .clipped()
          .opacity(1 - self.progress)
        self.art(size: size)
          .padding(.top, Metric.artTop)
        self.centeredTitle
          .padding(.top, 424)
          .opacity(max(0, 1 - self.progress / 0.5))
          .offset(y: -12 * self.progress)
        self.leadingTitle
          .padding(.top, 398)
          .opacity(min(1, max(0, (self.progress - 0.45) / 0.55)))
          .frame(width: proxy.size.width)
      }
      .frame(width: proxy.size.width)
    }
    .frame(height: Metric.height)
    .clipped()
  }

  private func art(size: CGFloat) -> some View {
    let radius = 14 * (1 - self.progress)
    return RoundedRectangle(cornerRadius: radius)
      .fill(WePLiColor.imagePlaceholder)
      .overlay {
        Image(systemName: "music.note")
          .font(.system(size: 54, weight: .light))
          .foregroundStyle(WePLiColor.textQuaternary)
      }
      // 아래 58%를 검정으로 녹인다 — 넓어질수록 짙어진다
      .overlay(alignment: .bottom) {
        LinearGradient(
          stops: [
            .init(color: .black.opacity(0.01), location: 0),
            .init(color: .black.opacity(0.1), location: 0.2163),
            .init(color: .black.opacity(0.2), location: 0.4471),
            .init(color: .black.opacity(0.5932), location: 0.66),
            .init(color: .black, location: 0.92),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: size * 0.58)
        .opacity(self.progress)
      }
      .clipShape(RoundedRectangle(cornerRadius: radius))
      .frame(width: size, height: size)
      .shadow(color: .black.opacity(0.55 * (1 - self.progress)), radius: 30, y: 24)
      .accessibilityHidden(true)
  }

  /// 처음 — 가운데 정렬
  private var centeredTitle: some View {
    VStack(spacing: 4) {
      Text(self.song.title)
        .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 26, relativeTo: .title))
        .foregroundStyle(WePLiColor.textPrimary)
      Text(self.song.artistTag)
        .wepliFont(.body)
        .foregroundStyle(WePLiColor.accent)
      Text(self.song.meta)
        .wepliFont(.footnote, weight: .light)
        .foregroundStyle(WePLiColor.textQuaternary)
    }
    .multilineTextAlignment(.center)
    .padding(.horizontal, 20)
    .accessibilityElement(children: .combine)
  }

  /// 넓어진 커버 위 — 왼쪽 정렬
  private var leadingTitle: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(self.song.artistTag)
        .wepliFont(.subheadline)
        .foregroundStyle(WePLiColor.accent)
      Text(self.song.title)
        .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 30, relativeTo: .title))
        .foregroundStyle(WePLiColor.textPrimary)
      Text(self.song.meta)
        .wepliFont(.subheadline, weight: .light)
        .foregroundStyle(WePLiColor.textSecondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 20)
    .accessibilityHidden(true)
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
    .frame(height: Metric.height)
    .accessibilityHidden(true)
  }
}

/// 미리듣기 · Music에서 듣기 · 진행 바(2) · 좋아요 · 릴레이에 추천 · 플리에 담기 · 들은 친구
struct SongControls: View {
  let song: SongDetail
  let isPlaying: Bool
  let position: Int
  let onPreview: () -> Void
  let onOpenInMusic: () -> Void
  let onLike: () -> Void
  let onRecommend: () -> Void
  let onAddToPlaylist: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 10) {
        Button(action: self.onPreview) {
          Label(self.isPlaying ? "일시정지" : "30초 미리듣기", systemImage: self.isPlaying ? "pause.fill" : "play.fill")
            .wepliFont(.callout, weight: .semibold)
            .foregroundStyle(WePLiColor.textOnCTA)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Capsule().fill(WePLiGradient.cta))
        }
        .buttonStyle(.plain)
        Button(action: self.onOpenInMusic) {
          Label("Music에서 듣기", systemImage: "apple.logo")
            .wepliFont(.callout, weight: .semibold)
            .foregroundStyle(WePLiColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(WePLiColor.secondaryButtonFill, in: Capsule())
        }
        .buttonStyle(.plain)
      }
      self.progress
      HStack(spacing: 8) {
        self.pill(
          systemImage: self.song.isLiked ? "heart.fill" : "heart",
          title: SongCount.string(self.song.likeCount),
          tint: self.song.isLiked ? WePLiColor.highlight : WePLiColor.textPrimary,
          action: self.onLike
        )
        .accessibilityLabel("좋아요 \(SongCount.string(self.song.likeCount))")
        .accessibilityAddTraits(self.song.isLiked ? .isSelected : [])
        self.pill(systemImage: "star", title: "릴레이에 추천", tint: WePLiColor.textPrimary, action: self.onRecommend)
        self.pill(systemImage: "text.badge.plus", title: "플리에 담기", tint: WePLiColor.textPrimary, action: self.onAddToPlaylist)
      }
      if !self.song.friendListeners.isEmpty {
        self.friends
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 4)
  }

  private var progress: some View {
    VStack(spacing: 6) {
      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 1).fill(Color.white.opacity(0.1))
          RoundedRectangle(cornerRadius: 1)
            .fill(WePLiColor.accent)
            .frame(width: proxy.size.width * SongPreview.progress(self.position))
            .animation(.linear(duration: 1), value: self.position)
        }
      }
      .frame(height: 2)
      HStack {
        Text(SongPreview.elapsedText(self.position))
        Spacer()
        Text(SongPreview.remainingText(self.position))
      }
      .wepliFont(.caption, weight: .light)
      .foregroundStyle(WePLiColor.textQuaternary)
      .monospacedDigit()
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("미리듣기 \(self.position)초 / 30초")
  }

  private func pill(systemImage: String, title: String, tint: Color, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack(spacing: 6) {
        Image(systemName: systemImage)
          .font(.system(size: 15))
          .foregroundStyle(tint)
        Text(title)
          .wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
          .monospacedDigit()
          .lineLimit(1)
      }
      .padding(.leading, 12)
      .padding(.trailing, 14)
      .frame(height: 36)
      .background(WePLiColor.secondaryButtonFill, in: Capsule())
    }
    .buttonStyle(.plain)
  }

  /// 「지수 님 외 친구 4명이 이번 주에 들었어요」
  private var friends: some View {
    HStack(spacing: 10) {
      HStack(spacing: -6) {
        ForEach(Array(self.song.friendListeners.prefix(3).enumerated()), id: \.offset) { _, _ in
          Circle()
            .fill(WePLiColor.imagePlaceholder)
            .frame(width: 24, height: 24)
            .overlay(Circle().strokeBorder(WePLiColor.background, lineWidth: 2))
        }
      }
      .accessibilityHidden(true)
      self.friendsText
        .wepliFont(.footnote, weight: .light)
        .foregroundStyle(WePLiColor.textSecondary)
        .lineLimit(1)
    }
  }

  private var friendsText: Text {
    let first = self.song.friendListeners[0]
    let others = self.song.friendListeners.count - 1
    let name = Text(first).font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 13)).foregroundColor(
      WePLiColor.textPrimary
    )
    if others > 0 {
      return name + Text(" 님 외 친구 \(others)명이 이번 주에 들었어요")
    }
    return name + Text(" 님이 이번 주에 들었어요")
  }
}
