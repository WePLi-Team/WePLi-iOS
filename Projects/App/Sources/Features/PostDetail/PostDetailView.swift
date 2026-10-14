import ComposableArchitecture
import SwiftUI

// REQ-063 · REQ-064 · UI-2c · UI-9c · UI-9d — 게시글 상세 · 댓글

struct PostDetailView: View {
  let store: StoreOf<PostDetailFeature>

  var body: some View {
    WithPerceptionTracking {
      ScrollView {
        if let post = self.store.post {
          LazyVStack(alignment: .leading, spacing: 0) {
            PostDetailBody(
              post: post,
              commentCount: self.store.commentCount,
              onAuthor: { self.store.send(.authorTapped(post.author)) },
              onPlay: { self.store.send(.playAttachmentTapped) },
              onLike: { self.store.send(.postLikeTapped) },
              onSave: { self.store.send(.postSaveTapped) }
            )
            // 본문과 댓글 사이 8pt 띠(#0E0E10)
            Rectangle().fill(WePLiColor.sectionBand).frame(height: 8)
            self.comments
          }
          .padding(.bottom, 24)
        } else if self.store.loadFailed {
          // 원본에 오류 화면이 없어 임시 문구 — 디자인 확인 필요
          VStack(spacing: 12) {
            Text("게시글을 불러오지 못했어요")
              .wepliFont(.callout, weight: .semibold)
              .foregroundStyle(WePLiColor.textPrimary)
            Button("다시 시도") { self.store.send(.retryButtonTapped) }
              .wepliFont(.body, weight: .semibold)
              .foregroundStyle(WePLiColor.accent)
          }
          .frame(maxWidth: .infinity, minHeight: 400)
        } else {
          ProgressView().tint(WePLiColor.textTertiary).frame(maxWidth: .infinity, minHeight: 400)
        }
      }
      .scrollDismissesKeyboard(.interactively)
      .safeAreaInset(edge: .top, spacing: 0) { self.navigationBar }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        if self.store.post != nil {
          CommentInputBar(store: self.store)
        }
      }
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .wepliToast(Binding(get: { self.store.toast }, set: {
        if $0 == nil {
          self.store.send(.toastDismissed)
        }
      }))
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private var navigationBar: some View {
    ZStack {
      Text("게시글")
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      HStack {
        WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") {
          self.store.send(.backButtonTapped)
        }
        Spacer()
        WePLiIconButton(systemName: "ellipsis", accessibilityLabel: "더보기") {
          self.store.send(.moreButtonTapped)
        }
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
    .background(WePLiColor.background)
  }

  private var comments: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text("댓글 \(CountFormatter.string(self.store.commentCount))")
          .wepliFont(.callout, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
        Spacer()
        if self.store.allowsSongReply {
          Text("노래로 답한 댓글 먼저")
            .wepliFont(.caption)
            .foregroundStyle(WePLiColor.textQuaternary)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 18)
      .padding(.bottom, 6)
      ForEach(self.store.comments) { comment in
        CommentThreadView(
          comment: comment,
          isExpanded: self.store.expandedCommentIDs.contains(comment.id),
          onLike: { self.store.send(.commentLikeTapped($0)) },
          onDelete: { self.store.send(.deleteCommentTapped(comment.id)) },
          onToggleReplies: { self.store.send(.repliesToggled(comment.id)) }
        )
      }
    }
  }
}

#Preview("한 곡") {
  NavigationStack {
    PostDetailView(store: Store(initialState: PostDetailFeature.State(postID: "p4")) { PostDetailFeature() })
  }
}

#Preview("일반") {
  NavigationStack {
    PostDetailView(store: Store(initialState: PostDetailFeature.State(postID: "p3")) { PostDetailFeature() })
  }
}
