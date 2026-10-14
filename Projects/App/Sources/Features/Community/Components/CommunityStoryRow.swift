import SwiftUI

// UI-1d 스토리 줄 — 링 58(모서리 22) · 간격 54(모서리 20) · 사진 50(모서리 18), 새 스토리 #C8CFFF · 본 스토리 #2A2A33

struct CommunityStoryRow: View {
  let stories: [Story]
  let onTap: (Story.ID) -> Void

  enum Metric {
    static let ring: CGFloat = 58
    static let gap: CGFloat = 54
    static let photo: CGFloat = 50
    static let itemWidth: CGFloat = 60
  }

  var body: some View {
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
        AvatarPlaceholder(name: self.story.user, cornerRadius: 18)
          .frame(width: CommunityStoryRow.Metric.photo, height: CommunityStoryRow.Metric.photo)
      }
  }
}

/// 사진이 붙기 전까지 이름 첫 글자로 그리는 자리 표시(백엔드 미정)
struct AvatarPlaceholder: View {
  let name: String
  var cornerRadius: CGFloat?

  var body: some View {
    let hue = Double(self.name.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 360) / 360
    let fill = Color(hue: hue, saturation: 0.3, brightness: 0.4)
    Group {
      if let cornerRadius = self.cornerRadius {
        RoundedRectangle(cornerRadius: cornerRadius).fill(fill)
      } else {
        Circle().fill(fill)
      }
    }
    .overlay {
      Text(self.name.prefix(1).uppercased())
        .wepliFont(.subheadline, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary.opacity(0.85))
    }
    .accessibilityHidden(true)
  }
}
