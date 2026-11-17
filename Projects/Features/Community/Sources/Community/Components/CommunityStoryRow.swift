import SwiftUI
import WePLiDesignSystem

// UI-1d 스토리 줄 — 링 58(모서리 22) · 간격 54(모서리 20) · 사진 50(모서리 18), 새 스토리 #C8CFFF · 본 스토리 #2A2A33

public struct CommunityStoryRow: View {
  public let stories: [Story]
  public let onTap: (Story.ID) -> Void

  public enum Metric {
    public static let ring: CGFloat = 58
    public static let gap: CGFloat = 54
    public static let photo: CGFloat = 50
    public static let itemWidth: CGFloat = 60
  }

  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(alignment: .top, spacing: 14) {
        self.myStory
        ForEach(self.stories) { story in
          Button {
            self.onTap(story.id)
          } label: {
            self.item(name: story.user) {
              StoryRing(story: story)
            }
          }
          .buttonStyle(.plain)
          .accessibilityLabel("\(story.user) 스토리\(story.isFresh ? ", 새 스토리" : "")")
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 4)
      .padding(.bottom, 18)
    }
    .overlay(alignment: .bottom) {
      Rectangle().fill(WePLiColor.textTertiary.opacity(0.3)).frame(height: 0.5)
    }
  }

  private var myStory: some View {
    self.item(name: "나") {
      RoundedRectangle(cornerRadius: 20)
        .fill(WePLiColor.surface3)
        .frame(width: Metric.gap, height: Metric.gap)
        .overlay {
          Image(systemName: "person")
            .font(.system(size: 22, weight: .regular))
            .foregroundStyle(WePLiColor.textDisabled)
        }
        .frame(width: Metric.ring, height: Metric.ring)
        .overlay(alignment: .bottomTrailing) {
          Image(systemName: "plus")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(WePLiColor.textOnCTA)
            .frame(width: 22, height: 22)
            .background(WePLiColor.accent, in: Circle())
            .overlay(Circle().stroke(WePLiColor.background, lineWidth: 2))
            .offset(x: 3, y: 3)
        }
    }
    .accessibilityLabel("내 스토리 추가")
  }

  private func item(name: String, @ViewBuilder thumbnail: () -> some View) -> some View {
    VStack(spacing: 6) {
      thumbnail()
      Text(name)
        .wepliFont(.caption)
        .foregroundStyle(WePLiColor.textPrimary)
        .lineLimit(1)
        .truncationMode(.tail)
        .frame(width: Metric.itemWidth)
    }
  }

  public init(stories: [Story], onTap: @escaping (Story.ID) -> Void) {
    self.stories = stories
    self.onTap = onTap
  }
}

private struct StoryRing: View {
  let story: Story

  var body: some View {
    RoundedRectangle(cornerRadius: 22)
      .fill(self.story.isFresh ? WePLiColor.accent : WePLiColor.imagePlaceholder)
      .frame(width: CommunityStoryRow.Metric.ring, height: CommunityStoryRow.Metric.ring)
      .overlay {
        RoundedRectangle(cornerRadius: 20)
          .fill(WePLiColor.background)
          .frame(width: CommunityStoryRow.Metric.gap, height: CommunityStoryRow.Metric.gap)
      }
      .overlay {
        WePLiAvatar(name: self.story.user, cornerRadius: 18)
          .frame(width: CommunityStoryRow.Metric.photo, height: CommunityStoryRow.Metric.photo)
      }
  }
}
