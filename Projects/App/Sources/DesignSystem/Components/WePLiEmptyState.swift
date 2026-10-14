import SwiftUI

// REQ-003 · UI-10f 「빈 상태」 — 왜 비었는지 + 다음에 할 일을 한 문장씩, 버튼 하나.

struct WePLiEmptyState: View {
  let systemImage: String
  let title: String
  let message: String
  var actionTitle: String?
  var action: (() -> Void)?

  enum Metric {
    static let iconCircle: CGFloat = 72
    static let iconSize: CGFloat = 30
    static let buttonHeight: CGFloat = 44
  }

  var body: some View {
    VStack(spacing: 10) {
      Image(systemName: self.systemImage)
        .font(.system(size: Metric.iconSize, weight: .light))
        .foregroundStyle(WePLiColor.textQuaternary)
        .frame(width: Metric.iconCircle, height: Metric.iconCircle)
        .background(WePLiColor.surface1, in: Circle())
        .padding(.bottom, 6)
        .accessibilityHidden(true)

      Text(self.title)
        .wepliFont(.title3)
        .foregroundStyle(WePLiColor.textPrimary)

      Text(self.message)
        .wepliFont(.subheadline)
        .foregroundStyle(WePLiColor.textTertiary)

      if let actionTitle = self.actionTitle, let action = self.action {
        Button(action: action) {
          Text(actionTitle)
            .wepliFont(.body, weight: .semibold)
            .foregroundStyle(WePLiColor.textPrimary)
            .padding(.horizontal, 20)
            .frame(height: Metric.buttonHeight)
            .background(WePLiColor.secondaryButtonFill, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.top, 14)
      }
    }
    .multilineTextAlignment(.center)
    .padding(.horizontal, 32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - 원본 문구 프리셋 (UI-10f)

extension WePLiEmptyState {
  static func feed(onWrite: @escaping () -> Void) -> Self {
    Self(
      systemImage: "square.and.pencil",
      title: "아직 게시글이 없어요",
      message: "좋아하는 노래 한 곡으로 첫 글을 써보세요.",
      actionTitle: "글쓰기",
      action: onWrite
    )
  }

  static func library(onBrowseHome: @escaping () -> Void) -> Self {
    Self(
      systemImage: "heart",
      title: "보관함이 비어 있어요",
      message: "마음에 드는 곡과 플리에 하트를 누르면 여기에 모여요.",
      actionTitle: "홈에서 둘러보기",
      action: onBrowseHome
    )
  }

  static func searchNoResult(query: String, onBrowse: @escaping () -> Void) -> Self {
    Self(
      systemImage: "magnifyingglass",
      title: "‘\(query)’ 검색 결과가 없어요",
      message: "띄어쓰기나 철자를 확인하거나, 가수 이름으로 찾아보세요.",
      actionTitle: "둘러보기로 가기",
      action: onBrowse
    )
  }

  static func notifications(onBrowseRelay: @escaping () -> Void) -> Self {
    Self(
      systemImage: "bell",
      title: "새 알림이 없어요",
      message: "릴레이에 참여하면 마감과 순위 소식을 알려드려요.",
      actionTitle: "릴레이 보러 가기",
      action: onBrowseRelay
    )
  }
}

#Preview {
  WePLiEmptyState.library {}
    .background(WePLiColor.background)
}
