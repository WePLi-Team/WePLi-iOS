import ComposableArchitecture
import SwiftUI

// REQ-022 · UI-4a 노트 02 — 탭 바 위 「지금 재생 중」 미니 플레이어. 누르면 4b가 열린다.
// iOS 26: 56pt 캡슐 글래스, 양옆 20 · 탭 바 위 10, 원형 아트, 재생/일시정지 · 다음
// iOS 16(4a classic): 모서리 16 카드, 양옆 8, 네모 아트, 다음 버튼 없음

struct MiniPlayerView: View {
  let store: StoreOf<PlayerFeature>

  @Environment(\.wepliChrome)
  private var chrome

  static let height: CGFloat = 56

  var body: some View {
    WithPerceptionTracking {
      if let track = self.store.current {
        let isGlass = self.chrome == .glass
        HStack(spacing: 10) {
          Group {
            if isGlass {
              Circle().fill(WePLiColor.imagePlaceholder)
            } else {
              RoundedRectangle(cornerRadius: 6).fill(WePLiColor.imagePlaceholder)
            }
          }
          .frame(width: 40, height: 40)
          VStack(alignment: .leading, spacing: 0) {
            Text(track.title).wepliFont(.subheadline, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
            Text("\(track.artist) · 미리듣기").wepliFont(.caption).foregroundStyle(WePLiColor.textTertiary)
          }
          .lineLimit(1)
          .frame(maxWidth: .infinity, alignment: .leading)
          self.controls(showsNext: isGlass)
        }
        .padding(.leading, 8)
        .padding(.trailing, 6)
        .frame(height: Self.height)
        .overlay(alignment: .bottomLeading) {
          // GeometryReader 내용은 body 밖에서 그려지므로 진행률은 미리 읽어 둔다
          let progress = PlayerText.progress(self.store.position)
          GeometryReader { proxy in
            Rectangle()
              .fill(WePLiColor.accent)
              .frame(width: proxy.size.width * progress, height: 2)
              .frame(maxHeight: .infinity, alignment: .bottom)
              .animation(.linear(duration: 1), value: self.store.position)
          }
        }
        .modifier(MiniPlayerBackground(isGlass: isGlass))
        .contentShape(Rectangle())
        .onTapGesture { self.store.send(.miniPlayerTapped) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("지금 재생 중, \(track.title), \(track.artist)")
        .accessibilityAction(named: "지금 재생 중 열기") { self.store.send(.miniPlayerTapped) }
        .padding(.horizontal, isGlass ? 20 : 8)
        .padding(.bottom, isGlass ? 10 : 8)
      }
    }
  }

  private func controls(showsNext: Bool) -> some View {
    HStack(spacing: 0) {
      Button {
        self.store.send(.playPauseTapped)
      } label: {
        Image(systemName: self.store.isPlaying ? "pause.fill" : "play.fill")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(WePLiColor.textPrimary)
          .frame(width: 40, height: 40)
      }
      .accessibilityLabel(self.store.isPlaying ? "일시정지" : "재생")
      if showsNext {
        Button {
          self.store.send(.nextTapped)
        } label: {
          Image(systemName: "forward.fill")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(WePLiColor.textPrimary)
            .frame(width: 40, height: 40)
        }
        .accessibilityLabel("다음 곡")
      }
    }
    .buttonStyle(.plain)
  }
}

private struct MiniPlayerBackground: ViewModifier {
  let isGlass: Bool

  func body(content: Content) -> some View {
    if self.isGlass {
      content
        .clipShape(Capsule())
        .wepliGlass(in: Capsule())
        .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
    } else {
      content
        .background(WePLiColor.barMaterial, in: RoundedRectangle(cornerRadius: 16))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
    }
  }
}
