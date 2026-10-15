import ComposableArchitecture
import SwiftUI

// UI-2c · 9c · 9d 본문 · 댓글 · 하단 입력 바

struct PostDetailBody: View {
  let post: Post
  let commentCount: Int
  let onAuthor: () -> Void
  let onPlay: () -> Void
  let onLike: () -> Void
  let onSave: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Button(action: self.onAuthor) {
        HStack(spacing: 10) {
          AvatarPlaceholder(name: self.post.author).frame(width: 36, height: 36)
          Text(self.post.author).wepliFont(.subheadline, weight: .semibold).foregroundStyle(Color.white)
        }
      }
      .buttonStyle(.plain)
      Text(self.post.title).wepliFont(.title3).foregroundStyle(Color.white)
      Text(self.post.body)
        .wepliFont(.body)
        .foregroundStyle(WePLiColor.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
      self.attachment
      HStack(spacing: 18) {
        Button(action: self.onLike) {
          Label(CountFormatter.string(self.post.likeCount), systemImage: self.post.isLiked ? "heart.fill" : "heart")
            .foregroundStyle(self.post.isLiked ? WePLiColor.highlight : WePLiColor.textMuted)
        }
        .accessibilityLabel("좋아요 \(CountFormatter.string(self.post.likeCount))")
        Label(CountFormatter.string(self.commentCount), systemImage: "bubble.left")
          .foregroundStyle(WePLiColor.textMuted)
        Spacer()
        Button(action: self.onSave) {
          Image(systemName: self.post.isSaved ? "bookmark.fill" : "bookmark")
            .foregroundStyle(self.post.isSaved ? WePLiColor.textPrimary : WePLiColor.textMuted)
            .frame(width: 44, height: 44)
        }
        .accessibilityLabel("저장")
      }
      .wepliFont(.footnote)
      .monospacedDigit()
      .buttonStyle(.plain)
      .frame(height: 44)
    }
    .padding(.horizontal, 20)
    .padding(.top, 12)
    .padding(.bottom, 8)
  }

  @ViewBuilder private var attachment: some View {
    switch self.post.attachment {
    case .none:
      EmptyView()
    case let .song(track):
      // 한 곡 타입 — 높이 68 재생 카드(UI-2c)
      Button(action: self.onPlay) {
        HStack(spacing: 12) {
          RoundedRectangle(cornerRadius: 8).fill(WePLiColor.imagePlaceholder).frame(width: 48, height: 48)
          VStack(alignment: .leading, spacing: 2) {
            Text(track.title).wepliFont(.body, weight: .semibold).foregroundStyle(Color.white).lineLimit(1)
            Text(track.artist).wepliFont(.footnote).foregroundStyle(WePLiColor.textSecondary).lineLimit(1)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          Image(systemName: "play.fill")
            .font(.system(size: 15))
            .foregroundStyle(WePLiColor.textOnCTA)
            .frame(width: 44, height: 44)
            .background(WePLiColor.accent, in: Circle())
        }
        .padding(.horizontal, 10)
        .frame(height: 68)
        .background(RoundedRectangle(cornerRadius: 16).fill(WePLiGradient.brand).opacity(0.2))
      }
      .buttonStyle(.plain)
      .accessibilityLabel("\(track.title) 재생")
    case let .playlist(tracks):
      // 플레이리스트 타입 — 플리 카드 묶음 + 전체 재생(UI-9c)
      VStack(spacing: 0) {
        ForEach(Array(tracks.enumerated()), id: \.offset) { index, track in
          HStack(spacing: 12) {
            Text("\(index + 1)").wepliFont(.footnote).foregroundStyle(WePLiColor.textQuaternary).frame(width: 16)
            RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 1) {
              Text(track.title).wepliFont(.subheadline).foregroundStyle(Color.white).lineLimit(1)
              Text(track.artist).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textTertiary)
            }
            Spacer()
          }
          .frame(height: 58)
        }
        Button(action: self.onPlay) {
          Label("전체 재생", systemImage: "play.fill")
            .wepliFont(.subheadline, weight: .semibold)
            .foregroundStyle(WePLiColor.textOnCTA)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            // 흰 바탕 버튼 대신 CTA 그라디언트(디자인 원칙 · DEC-009)
            .background(Capsule().fill(WePLiGradient.cta))
        }
        .buttonStyle(.plain)
        .padding(.vertical, 10)
      }
      .padding(.horizontal, 14)
      .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 18))
    }
  }
}

struct CommentThreadView: View {
  let comment: PostComment
  let isExpanded: Bool
  let onLike: (PostComment.ID) -> Void
  let onDelete: () -> Void
  let onToggleReplies: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      CommentRow(comment: self.comment, onLike: { self.onLike(self.comment.id) }, onDelete: self.onDelete)
      if !self.comment.replies.isEmpty {
        if self.isExpanded {
          ForEach(self.comment.replies) { reply in
            CommentRow(comment: reply, onLike: { self.onLike(reply.id) }, onDelete: nil)
              .padding(.leading, 46)
          }
        }
        Button(self.isExpanded ? "답글 숨기기" : "답글 \(self.comment.replies.count)개 더보기", action: self.onToggleReplies)
          .wepliFont(.caption, weight: .semibold)
          .foregroundStyle(WePLiColor.textQuaternary)
          .padding(.leading, 66)
          .frame(minHeight: 32)
      }
    }
  }
}

struct CommentRow: View {
  let comment: PostComment
  let onLike: () -> Void
  /// 내 댓글에만 보인다
  let onDelete: (() -> Void)?

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      AvatarPlaceholder(name: self.comment.author).frame(width: 36, height: 36)
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 4) {
          Text(self.comment.author).wepliFont(.footnote, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
          Text("· \(self.comment.timeText)").wepliFont(.footnote).foregroundStyle(WePLiColor.textQuaternary)
          Spacer(minLength: 0)
          if self.comment.isMine, let onDelete = self.onDelete {
            Button("삭제", action: onDelete)
              .wepliFont(.caption)
              .foregroundStyle(WePLiColor.textQuaternary)
          }
        }
        if let song = self.comment.song {
          HStack(spacing: 8) {
            Circle().fill(WePLiColor.imagePlaceholder).frame(width: 32, height: 32)
              .overlay { Image(systemName: "music.note").font(.system(size: 12)).foregroundStyle(WePLiColor.accent) }
            Text("\(song.title) · \(song.artist)").wepliFont(.footnote).foregroundStyle(WePLiColor.textPrimary)
              .lineLimit(1)
          }
          .padding(.horizontal, 4)
          .padding(.trailing, 8)
          .frame(height: 40)
          .background(WePLiColor.surface1, in: Capsule())
        }
        Text(self.comment.text)
          .wepliFont(.subheadline)
          .foregroundStyle(WePLiColor.textMuted)
          .fixedSize(horizontal: false, vertical: true)
      }
      Button(action: self.onLike) {
        VStack(spacing: 2) {
          Image(systemName: self.comment.isLiked ? "heart.fill" : "heart")
            .font(.system(size: 13))
            .foregroundStyle(self.comment.isLiked ? WePLiColor.highlight : WePLiColor.textQuaternary)
          if let likeText = self.comment.likeText {
            Text(likeText).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary).monospacedDigit()
          }
        }
        .frame(width: 36, height: 44)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("좋아요 \(self.comment.likeText ?? "")")
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
  }
}

struct CommentInputBar: View {
  let store: StoreOf<PostDetailFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 8) {
        if let song = self.store.replySong {
          HStack(spacing: 6) {
            Image(systemName: "music.note")
            Text("\(song.title) · \(song.artist)").lineLimit(1)
            Button {
              self.store.send(.replySongRemoved)
            } label: {
              Image(systemName: "xmark")
            }
            .accessibilityLabel("곡 빼기")
          }
          .wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(WePLiColor.accent)
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        HStack(spacing: 8) {
          if self.store.allowsSongReply {
            Button {
              self.store.send(.songReplyButtonTapped)
            } label: {
              let isOn = self.store.replySong != nil
              Image(systemName: "music.note")
                .foregroundStyle(isOn ? WePLiColor.textOnCTA : WePLiColor.textMuted)
                .frame(width: 42, height: 42)
                .background(isOn ? WePLiColor.accent : WePLiColor.surface3, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("노래로 답하기")
          }
          TextField(
            // 일반 타입은 「노래로 답해보세요」(UI-9d)
            self.store.allowsSongReply ? "노래로 답해보세요" : "댓글을 남겨주세요",
            text: Binding(get: { self.store.draft }, set: { self.store.send(.draftChanged($0)) })
          )
          .wepliFont(.subheadline)
          .foregroundStyle(WePLiColor.textPrimary)
          .submitLabel(.send)
          .onSubmit { self.store.send(.sendButtonTapped) }
          .padding(.horizontal, 16)
          .frame(height: 42)
          .background(WePLiColor.surface3, in: Capsule())
          Button {
            self.store.send(.sendButtonTapped)
          } label: {
            Image(systemName: "arrow.up")
              .font(.system(size: 14, weight: .bold))
              .foregroundStyle(self.store.canSend ? WePLiColor.textOnCTA : WePLiColor.textDisabled)
              .frame(width: 32, height: 32)
              .background(self.store.canSend ? WePLiColor.accent : WePLiColor.surface4, in: Circle())
          }
          .buttonStyle(.plain)
          .disabled(!self.store.canSend)
          .accessibilityLabel("보내기")
        }
      }
      .padding(.horizontal, 12)
      .padding(.top, 10)
      .padding(.bottom, 8)
      .background(.ultraThinMaterial)
      .background(WePLiColor.barMaterial)
    }
  }
}
