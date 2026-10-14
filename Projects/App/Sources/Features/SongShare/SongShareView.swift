import ComposableArchitecture
import SwiftUI

// REQ-066 · UI-3g — 곡 공유 카드(전체 화면). 위: 미리보기 카드(×1.12, 위 82) · 아래: 떠 있는 공유 시트(여백 8, 모서리 40)

struct SongShareView: View {
  let store: StoreOf<SongShareFeature>

  var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .bottom) {
        self.backdrop
        SongShareCardView(card: self.store.card)
          .scaleEffect(1.12, anchor: .top)
          .shadow(color: .black.opacity(0.6), radius: 40, y: 30)
          .padding(.top, 82 - 54)
          .frame(maxHeight: .infinity, alignment: .top)
        self.sheet
          .padding(.horizontal, 8)
          .padding(.bottom, 8)
      }
      .ignoresSafeArea(edges: .bottom)
      .onAppear { self.store.send(.onAppear) }
      .wepliToast(Binding(get: { self.store.toast }, set: {
        if $0 == nil {
          self.store.send(.toastDismissed)
        }
      }))
      .sheet(item: Binding(
        get: { self.store.systemShare },
        set: {
          if $0 == nil {
            self.store.send(.systemShareDismissed)
          }
        }
      )) { item in
        ActivityView(item: item)
      }
    }
  }

  private var backdrop: some View {
    ZStack {
      Color.black
      WePLiColor.surface4
        .frame(width: 562, height: 700)
        .blur(radius: 60)
        .opacity(0.5)
      WePLiColor.dim
    }
    .ignoresSafeArea()
  }

  private var sheet: some View {
    VStack(spacing: 18) {
      Capsule().fill(Color.white.opacity(0.3)).frame(width: 36, height: 5)
      self.header
      self.targets
      self.actions
    }
    .padding(EdgeInsets(top: 8, leading: 18, bottom: 30, trailing: 18))
    .background(WePLiColor.surface3.opacity(0.95), in: RoundedRectangle(cornerRadius: 40, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).strokeBorder(
      Color.white.opacity(0.12),
      lineWidth: 0.5
    ))
    .shadow(color: .black.opacity(0.4), radius: 20, y: -10)
  }

  private var header: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text("노래 공유하기")
          .wepliFont(.headline)
          .foregroundStyle(WePLiColor.textPrimary)
          .accessibilityAddTraits(.isHeader)
        Text(self.store.card.subtitle)
          .wepliFont(.footnote)
          .foregroundStyle(WePLiColor.textQuaternary)
          .lineLimit(1)
      }
      Spacer(minLength: 12)
      Button {
        self.store.send(.closeButtonTapped)
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(WePLiColor.textMuted)
          .frame(width: 36, height: 36)
          .background(Color.white.opacity(0.08), in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("닫기")
    }
  }

  private var targets: some View {
    HStack(alignment: .top, spacing: 8) {
      ShareTargetTile(title: "스토리", isStory: true) {
        self.store.send(.storyTapped(image: self.cardImage()))
      }
      ShareTargetTile(title: "링크 복사", systemImage: "link") { self.store.send(.copyLinkTapped) }
      ShareTargetTile(title: "이미지 저장", systemImage: "arrow.down.to.line") {
        self.store.send(.saveImageTapped(image: self.cardImage()))
      }
      ShareTargetTile(title: "더보기", systemImage: "ellipsis") {
        self.store.send(.moreTapped(image: self.cardImage()))
      }
    }
  }

  private var actions: some View {
    VStack(spacing: 0) {
      ShareActionRow(title: "게시글로 공유하기", systemImage: "square.and.pencil") {
        self.store.send(.shareAsPostTapped)
      }
      Rectangle().fill(Color.white.opacity(0.1)).frame(height: 0.5).padding(.leading, 54)
      ShareActionRow(title: "내 플레이리스트에 추가하기", systemImage: "text.badge.plus") {
        self.store.send(.addToPlaylistTapped)
      }
    }
    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
  }

  @MainActor
  private func cardImage() -> Data? {
    SongShareCardView.png(self.store.card)
  }
}

private struct ShareTargetTile: View {
  let title: String
  var systemImage: String?
  var isStory = false
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      VStack(spacing: 8) {
        self.tile()
        Text(self.title)
          .wepliFont(.caption)
          .foregroundStyle(WePLiColor.textMuted)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func tile() -> some View {
    let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
    if self.isStory {
      Circle()
        .strokeBorder(.white, lineWidth: 3)
        .frame(width: 24, height: 24)
        .frame(width: 58, height: 58)
        .background(WePLiGradient.storyTile, in: shape)
    } else {
      Image(systemName: self.systemImage ?? "")
        .font(.system(size: 20, weight: .medium))
        .foregroundStyle(WePLiColor.textPrimary)
        .frame(width: 58, height: 58)
        .background(WePLiColor.surface4, in: shape)
    }
  }
}

private struct ShareActionRow: View {
  let title: String
  let systemImage: String
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      HStack(spacing: 14) {
        Image(systemName: self.systemImage)
          .font(.system(size: 18))
          .foregroundStyle(WePLiColor.textMuted)
          .frame(width: 22, height: 22)
        Text(self.title)
          .wepliFont(.callout)
          .foregroundStyle(WePLiColor.textPrimary)
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 18)
      .frame(height: 52)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

/// 「더보기」 — iOS 공유 시트
private struct ActivityView: UIViewControllerRepresentable {
  let item: SystemShareItem

  func makeUIViewController(context _: Context) -> UIActivityViewController {
    var items: [Any] = []
    if let image = UIImage(data: self.item.image) {
      items.append(image)
    }
    if let link = self.item.link {
      items.append(link)
    }
    return UIActivityViewController(activityItems: items, applicationActivities: nil)
  }

  func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}

#Preview {
  SongShareView(store: Store(initialState: SongShareFeature.State(card: SongShareCard(
    songID: "1",
    title: "소년, 길을 걷다",
    artist: "이승기",
    sharerName: "김동",
    sharerPersona: "멜로디 메모리즈",
    today: .now
  ))) {
    SongShareFeature()
  })
}
