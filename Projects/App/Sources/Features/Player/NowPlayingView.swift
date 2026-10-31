import ComposableArchitecture
import SwiftUI

// REQ-022 · UI-4b — 지금 재생 중. 미니 플레이어를 누르면 올라오는 iOS 음악 앱 방식의 전체 화면 플레이어.
// 위쪽 손잡이를 끌어내리면 닫힌다. 일시정지하면 앨범 아트가 0.86으로 작아진다(4b 노트 03).

struct NowPlayingView: View {
  let store: StoreOf<PlayerFeature>

  @State private var dragOffset: CGFloat = 0

  var body: some View {
    WithPerceptionTracking {
      if let track = self.store.current {
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            Capsule()
              .fill(Color.white.opacity(0.35))
              .frame(width: 36, height: 5)
              .frame(maxWidth: .infinity)
              .padding(.top, 6)
              .padding(.bottom, 22)
              .accessibilityHidden(true)
            self.artwork
            self.titleRow(track).padding(.top, 28)
            self.progress.padding(.top, 22)
            self.transport.padding(.top, 18)
            self.openInMusic.padding(.top, 18)
            if !self.store.upcoming.isEmpty {
              self.queue.padding(.top, 30)
            }
          }
          .padding(.horizontal, 28)
          .padding(.bottom, 48)
        }
        .scrollIndicators(.hidden)
        .background { self.background }
        .offset(y: self.dragOffset)
        .gesture(self.dismissDrag)
        .accessibilityAction(.escape) { self.store.send(.collapseTapped) }
      }
    }
  }

  /// 아래로 끌어 닫기
  private var dismissDrag: some Gesture {
    DragGesture()
      .onChanged { value in
        self.dragOffset = max(0, value.translation.height)
      }
      .onEnded { value in
        if value.translation.height > 140 {
          self.store.send(.collapseTapped)
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { self.dragOffset = 0 }
      }
  }

  /// 미결정 — 원본은 앨범 아트를 70px 흐려 깐다. 아트가 아직 없어 어두운 바탕만 둔다
  private var background: some View {
    ZStack {
      WePLiColor.surface2
      LinearGradient(
        stops: [
          .init(color: .black.opacity(0.15), location: 0),
          .init(color: .black.opacity(0.45), location: 0.6),
          .init(color: .black.opacity(0.85), location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    }
    .ignoresSafeArea()
  }

  private var artwork: some View {
    RoundedRectangle(cornerRadius: 14)
      .fill(WePLiColor.imagePlaceholder)
      .aspectRatio(1, contentMode: .fit)
      .shadow(color: .black.opacity(0.55), radius: 35, y: 30)
      .scaleEffect(self.store.isPlaying ? 1 : 0.86)
      .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.45), value: self.store.isPlaying)
      .frame(maxWidth: 346)
      .frame(maxWidth: .infinity)
      .accessibilityHidden(true)
  }

  private func titleRow(_ track: PlayerTrack) -> some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 0) {
        Text(track.title).wepliFont(.title2).foregroundStyle(WePLiColor.textPrimary)
        Text(track.artist).wepliFont(.headline, weight: .regular).foregroundStyle(WePLiColor.textPrimary.opacity(0.65))
      }
      .lineLimit(1)
      .frame(maxWidth: .infinity, alignment: .leading)
      Button {
        self.store.send(.likeTapped)
      } label: {
        Image(systemName: self.store.isLiked ? "heart.fill" : "heart")
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(self.store.isLiked ? WePLiColor.highlight : WePLiColor.textPrimary)
          .frame(width: 40, height: 40)
          .background(Color.white.opacity(0.12), in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(self.store.isLiked ? "좋아요 취소" : "좋아요")
    }
  }

  private var progress: some View {
    // GeometryReader 내용은 body 밖에서 그려지므로 진행률은 미리 읽어 둔다
    let progress = PlayerText.progress(self.store.position)
    return VStack(spacing: 8) {
      GeometryReader { proxy in
        Capsule().fill(Color.white.opacity(0.2))
          .overlay(alignment: .leading) {
            Capsule()
              .fill(Color.white.opacity(0.9))
              .frame(width: proxy.size.width * progress)
              .animation(.linear(duration: 1), value: self.store.position)
          }
      }
      .frame(height: 6)
      HStack {
        Text(PlayerText.elapsed(self.store.position))
        Spacer()
        Text("미리듣기 30초")
        Spacer()
        Text(PlayerText.remaining(self.store.position))
      }
      .wepliFont(.caption, weight: .medium)
      .monospacedDigit()
      .foregroundStyle(WePLiColor.textPrimary.opacity(0.6))
    }
    .accessibilityElement()
    .accessibilityLabel("미리듣기 30초 중 \(self.store.position)초")
  }

  private var transport: some View {
    HStack {
      self.transportButton("backward.fill", size: 30, label: "이전 곡") { self.store.send(.previousTapped) }
      Spacer()
      self.transportButton(
        self.store.isPlaying ? "pause.fill" : "play.fill",
        size: 40,
        label: self.store.isPlaying ? "일시정지" : "재생"
      ) { self.store.send(.playPauseTapped) }
      Spacer()
      self.transportButton("forward.fill", size: 30, label: "다음 곡") { self.store.send(.nextTapped) }
    }
    .padding(.horizontal, 30)
  }

  private func transportButton(
    _ systemName: String,
    size: CGFloat,
    label: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.system(size: size))
        .foregroundStyle(WePLiColor.textPrimary)
        .frame(width: size + 32, height: size + 32)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }

  private var openInMusic: some View {
    Button {
      self.store.send(.openInMusicTapped)
    } label: {
      HStack(spacing: 6) {
        Image(systemName: "apple.logo").font(.system(size: 16)).offset(y: -1)
        Text("Music에서 전체 곡 듣기").wepliFont(.callout, weight: .semibold)
      }
      .foregroundStyle(WePLiColor.textPrimary)
      .frame(maxWidth: .infinity)
      .frame(height: 50)
      .background(Color.white.opacity(0.12), in: Capsule())
      .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5))
    }
    .buttonStyle(.plain)
  }

  private var queue: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .firstTextBaseline) {
        Text("다음 곡").wepliFont(.button).foregroundStyle(WePLiColor.textPrimary).accessibilityAddTraits(.isHeader)
        Spacer()
        if let source = self.store.source {
          Text("\(source)에서")
            .wepliFont(.footnote)
            .foregroundStyle(WePLiColor.textPrimary.opacity(0.6))
            .lineLimit(1)
        }
      }
      ForEach(self.store.upcoming) { track in
        Button {
          self.store.send(.upcomingTapped(track.id))
        } label: {
          HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6).fill(WePLiColor.imagePlaceholder).frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 0) {
              Text(track.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
              Text(track.artist).wepliFont(.footnote).foregroundStyle(WePLiColor.textPrimary.opacity(0.6))
            }
            .lineLimit(1)
            Spacer()
          }
          .frame(height: 58)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
  }
}
