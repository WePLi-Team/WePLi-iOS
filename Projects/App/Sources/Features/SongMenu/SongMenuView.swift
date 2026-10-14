import ComposableArchitecture
import SwiftUI

// UI-1b 곡 메뉴 시트 — 헤더(커버 52 · 곡명 17 SemiBold · 가수 14 #B5B5C0 · 좋아요 · 닫기 44)
// 묶음: 모서리 22 · 흰색 6% · 행 50 · 아이콘 22 #D8D8DD · 구분선 왼쪽 54

struct SongMenuView: View {
  static let height: CGFloat = 560

  let store: StoreOf<SongMenuFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 14) {
        self.header
        ForEach(Array(SongMenuItem.groups.enumerated()), id: \.offset) { _, items in
          self.group(items)
        }
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 14)
      .padding(.top, 24)
      .wepliToast(Binding(get: { self.store.toast }, set: {
        if $0 == nil {
          self.store.send(.toastDismissed)
        }
      }))
    }
  }

  private var header: some View {
    HStack(spacing: 12) {
      RoundedRectangle(cornerRadius: 6)
        .fill(WePLiColor.imagePlaceholder)
        .frame(width: 52, height: 52)
        .overlay {
          Image(systemName: "music.note")
            .font(.system(size: 18, weight: .light))
            .foregroundStyle(WePLiColor.textQuaternary)
        }
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        Text(self.store.title)
          .wepliFont(.button)
          .foregroundStyle(WePLiColor.textPrimary)
          .lineLimit(1)
        Text(self.store.artist)
          .wepliFont(.subheadline)
          .foregroundStyle(WePLiColor.textSecondary)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      self.circleButton(
        systemName: self.store.isLiked ? "heart.fill" : "heart",
        color: self.store.isLiked ? WePLiColor.highlight : WePLiColor.textMuted,
        size: 20,
        label: self.store.isLiked ? "좋아요 취소" : "좋아요"
      ) { self.store.send(.likeButtonTapped) }
      self.circleButton(systemName: "xmark", color: WePLiColor.textMuted, size: 14, label: "닫기") {
        self.store.send(.closeButtonTapped)
      }
    }
    .padding(EdgeInsets(top: 4, leading: 6, bottom: 0, trailing: 4))
  }

  private func circleButton(
    systemName: String,
    color: Color,
    size: CGFloat,
    label: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.system(size: size, weight: .semibold))
        .foregroundStyle(color)
        .frame(width: 44, height: 44)
        .background(Color.white.opacity(0.08), in: Circle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }

  private func group(_ items: [SongMenuItem]) -> some View {
    VStack(spacing: 0) {
      ForEach(Array(items.enumerated()), id: \.element) { index, item in
        Button {
          self.store.send(.itemTapped(item))
        } label: {
          HStack(spacing: 14) {
            SongMenuIcon(item: item)
              .frame(width: 22, height: 22)
              .foregroundStyle(WePLiColor.textMuted)
            Text(item.title)
              .wepliFont(.callout)
              .foregroundStyle(WePLiColor.textPrimary)
            Spacer(minLength: 0)
          }
          .padding(.horizontal, 18)
          .frame(height: 50)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
          if index < items.count - 1 {
            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 0.5).padding(.leading, 54)
          }
        }
      }
    }
    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
  }
}

/// 행 아이콘 — 인스타그램은 맞는 SF Symbol이 없어 원본 모양(둥근 사각형 · 원 · 점)을 직접 그린다
private struct SongMenuIcon: View {
  let item: SongMenuItem

  var body: some View {
    if self.item == .instagram {
      ZStack {
        RoundedRectangle(cornerRadius: 5).strokeBorder(lineWidth: 1.7).frame(width: 18, height: 18)
        Circle().strokeBorder(lineWidth: 1.7).frame(width: 8, height: 8)
        Circle().frame(width: 2, height: 2).offset(x: 5, y: -5)
      }
    } else {
      Image(systemName: self.systemName).font(.system(size: 18))
    }
  }

  private var systemName: String {
    switch self.item {
    case .artist: "person"
    case .lyrics: "text.alignleft"
    case .addToPlaylist: "text.badge.plus"
    case .shareAsPost: "square.and.pencil"
    case .instagram: "camera"
    case .link: "link"
    case .screenshot: "viewfinder"
    case .info: "info.circle"
    }
  }
}

#Preview {
  Color.black.sheet(isPresented: .constant(true)) {
    SongMenuView(store: Store(initialState: SongMenuFeature.State(
      songID: "1",
      title: "Small girl (feat. 도경수 (D.O))",
      artist: "이영지",
      isLiked: false
    )) {
      SongMenuFeature()
    })
    .wepliSheetStyle(detents: [.height(SongMenuView.height)])
  }
}
