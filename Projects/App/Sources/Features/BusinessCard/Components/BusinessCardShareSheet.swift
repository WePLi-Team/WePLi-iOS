import SwiftUI

// UI-2e 「명함 공유하기」 시트 — 묶음 1(인스타 스토리 · 링크 · 이미지 저장) · 묶음 2(다른 앱으로 공유…)
// 묶음 모서리 22 · 흰색 6% · 행 54 · 구분선 왼쪽 54

struct BusinessCardShareSheet: View {
  static let height: CGFloat = 330

  let onItem: (BusinessCardShareItem) -> Void
  let onClose: () -> Void

  var body: some View {
    VStack(spacing: 14) {
      HStack {
        Text("명함 공유하기")
          .wepliFont(.headline)
          .foregroundStyle(WePLiColor.textPrimary)
          .accessibilityAddTraits(.isHeader)
        Spacer()
        Button(action: self.onClose) {
          Image(systemName: "xmark")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(WePLiColor.textMuted)
            .frame(width: 36, height: 36)
            .background(Color.white.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("닫기")
      }
      .padding(.horizontal, 6)
      self.group([.instagramStory, .link, .saveImage])
      self.group([.otherApps])
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 14)
    .padding(.top, 24)
  }

  private func group(_ items: [BusinessCardShareItem]) -> some View {
    VStack(spacing: 0) {
      ForEach(Array(items.enumerated()), id: \.element) { index, item in
        Button {
          self.onItem(item)
        } label: {
          HStack(spacing: 14) {
            self.icon(item).frame(width: 22, height: 22)
            Text(item.title)
              .wepliFont(.callout)
              .foregroundStyle(WePLiColor.textPrimary)
            Spacer(minLength: 0)
            if item == .otherApps {
              Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(WePLiColor.textDisabled)
            }
          }
          .padding(.horizontal, 18)
          .frame(height: 54)
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

  @ViewBuilder
  private func icon(_ item: BusinessCardShareItem) -> some View {
    switch item {
    case .instagramStory:
      InstagramMark(size: 22)
    case .link:
      Image(systemName: "link").font(.system(size: 17)).foregroundStyle(WePLiColor.textMuted)
    case .saveImage:
      Image(systemName: "viewfinder").font(.system(size: 17)).foregroundStyle(WePLiColor.textMuted)
    case .otherApps:
      Image(systemName: "square.and.arrow.up").font(.system(size: 17)).foregroundStyle(WePLiColor.textMuted)
    }
  }
}
