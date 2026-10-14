import SwiftUI

// UI-1d 게시글 카드 — 작성자 행 · 제목 18 SemiBold · 본문 15 Regular #B5B5C0 · 곡 칩 · 플리 카드 · 액션 줄(44)

struct CommunityPostCard: View {
  let post: Post
  let onLike: () -> Void
  let onSave: () -> Void
  let onAuthor: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      self.authorRow
      VStack(alignment: .leading, spacing: 8) {
        Text(self.post.title)
          .wepliFont(.headline)
          .foregroundStyle(Color.white)
        Text(self.post.body)
          .wepliFont(.body)
          .foregroundStyle(WePLiColor.textSecondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      self.attachment
      self.actions
    }
    .padding(.horizontal, 20)
    .padding(.top, 16)
    .padding(.bottom, 8)
    .overlay(alignment: .bottom) {
      Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5)
    }
  }

  private var authorRow: some View {
    HStack(spacing: 10) {
      Button(action: self.onAuthor) {
        HStack(spacing: 10) {
          AvatarPlaceholder(name: self.post.author)
            .frame(width: 32, height: 32)
          Text(self.post.author)
            .wepliFont(.subheadline, weight: .semibold)
            .foregroundStyle(Color.white)
        }
      }
      .buttonStyle(.plain)
      // 팔로우 동작은 프로필 · 팔로우 이슈(UI-5a · 10c)에서 연결
      Text("팔로우")
        .wepliFont(.footnote, weight: .semibold)
        .foregroundStyle(WePLiColor.accentStrong)
      Spacer(minLength: 0)
      Image(systemName: "ellipsis")
        .font(.system(size: 15, weight: .bold))
        .foregroundStyle(WePLiColor.tabInactiveGlass)
        .frame(width: 36, height: 36)
        .padding(.trailing, -8)
        .accessibilityLabel("더보기")
    }
  }

  @ViewBuilder private var attachment: some View {
    switch self.post.attachment {
    case .none:
      EmptyView()
    case let .song(track):
      HStack(spacing: 8) {
        Image(systemName: "play.fill")
          .font(.system(size: 9))
          .foregroundStyle(WePLiColor.textOnCTA)
          .frame(width: 24, height: 24)
          .background(WePLiColor.accent, in: Circle())
        Text("\(track.title) - \(track.artist)")
          .wepliFont(.footnote)
          .foregroundStyle(Color.white)
          .lineLimit(1)
      }
      .padding(.leading, 5)
      .padding(.trailing, 14)
      .frame(height: 34)
      .background(Capsule().fill(WePLiGradient.brand).opacity(0.2))
      .accessibilityElement(children: .combine)
    case let .playlist(tracks):
      VStack(spacing: 0) {
        ForEach(Array(tracks.enumerated()), id: \.offset) { _, track in
          HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
              .fill(WePLiColor.imagePlaceholder)
              .frame(width: 40, height: 40)
              .overlay {
                Image(systemName: "music.note")
                  .font(.system(size: 14))
                  .foregroundStyle(WePLiColor.textQuaternary)
              }
            VStack(alignment: .leading, spacing: 1) {
              Text(track.title)
                .wepliFont(.subheadline)
                .foregroundStyle(Color.white)
                .lineLimit(1)
              Text(track.artist)
                .wepliFont(.caption, weight: .light)
                .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "play")
              .font(.system(size: 13))
              .foregroundStyle(WePLiColor.textMuted)
              .frame(width: 40, height: 44)
          }
          .frame(height: 52)
          .accessibilityElement(children: .combine)
        }
      }
      .padding(.leading, 10)
      .padding(.trailing, 4)
      .padding(.vertical, 6)
      .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 16))
    }
  }

  private var actions: some View {
    HStack(spacing: 18) {
      Button(action: self.onLike) {
        HStack(spacing: 5) {
          Image(systemName: self.post.isLiked ? "heart.fill" : "heart")
            .font(.system(size: 20))
            .foregroundStyle(self.post.isLiked ? WePLiColor.highlight : WePLiColor.textMuted)
          Text(CountFormatter.string(self.post.likeCount))
            .wepliFont(.footnote)
            .foregroundStyle(WePLiColor.textMuted)
            .monospacedDigit()
        }
        .frame(height: 44)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("좋아요 \(CountFormatter.string(self.post.likeCount))")
      .accessibilityAddTraits(self.post.isLiked ? .isSelected : [])

      HStack(spacing: 5) {
        Image(systemName: "bubble.left")
          .font(.system(size: 20))
          .foregroundStyle(WePLiColor.textMuted)
        Text(CountFormatter.string(self.post.commentCount))
          .wepliFont(.footnote)
          .foregroundStyle(WePLiColor.textMuted)
          .monospacedDigit()
      }
      .frame(height: 44)
      .accessibilityElement(children: .combine)
      .accessibilityLabel("댓글 \(CountFormatter.string(self.post.commentCount))")

      Spacer(minLength: 0)

      Button(action: self.onSave) {
        Image(systemName: self.post.isSaved ? "bookmark.fill" : "bookmark")
          .font(.system(size: 20))
          .foregroundStyle(self.post.isSaved ? WePLiColor.textPrimary : WePLiColor.textMuted)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .padding(.trailing, -10)
      .accessibilityLabel("저장")
      .accessibilityAddTraits(self.post.isSaved ? .isSelected : [])
    }
  }
}
