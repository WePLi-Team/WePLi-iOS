import ComposableArchitecture
import Foundation
import OSLog

// REQ-063 · REQ-064 · UI-2c · UI-9c · UI-9d · DEC-004 — 게시글 상세 · 댓글

@Reducer
struct PostDetailFeature {
  @ObservableState
  struct State: Equatable {
    let postID: Post.ID
    var post: Post?
    var comments: IdentifiedArrayOf<PostComment> = []
    var loadFailed = false
    var draft = ""
    /// 노래로 답하기(일반 타입) — 붙인 곡
    var replySong: Track?
    /// 답글을 펼친 댓글
    var expandedCommentIDs: Set<PostComment.ID> = []
    var isSending = false
    var toast: String?
    /// 이 화면에서 달거나 지운 댓글 수(서버 수에 더해 보여 준다)
    var commentDelta = 0

    init(postID: Post.ID) {
      self.postID = postID
    }

    /// 일반 타입 게시글에서만 음표(노래로 답하기)를 쓴다(UI-9d)
    var allowsSongReply: Bool {
      self.post?.attachment == Post.Attachment.none
    }

    var commentCount: Int {
      (self.post?.commentCount ?? 0) + self.commentDelta
    }

    var canSend: Bool {
      !self.isSending && CommentInput.text(draft: self.draft, hasSong: self.replySong != nil) != nil
    }
  }

  enum Action: Equatable {
    case onAppear
    case loaded(PostThread)
    case loadFailed
    case retryButtonTapped
    case draftChanged(String)
    case sendButtonTapped
    case commentAdded(PostComment)
    case commentFailed
    case repliesToggled(PostComment.ID)
    case deleteCommentTapped(PostComment.ID)
    case commentLikeTapped(PostComment.ID)
    case songReplyButtonTapped
    /// 노래 고르기에서 곡을 받았다
    case replySongPicked(Track)
    case replySongRemoved
    case postLikeTapped
    case postSaveTapped
    case postLikeFailed(restore: Bool)
    case postSaveFailed(restore: Bool)
    case toastDismissed
    case backButtonTapped
    case moreButtonTapped
    case playAttachmentTapped
    case authorTapped(String)
    case delegate(Delegate)
  }

  enum Delegate: Equatable {
    case dismiss
    case more(postID: Post.ID)
    case play(postID: Post.ID)
    case showProfile(String)
    /// 댓글에 붙일 곡 고르기(UI-2a)
    case pickReplySong
  }

  @Dependency(\.postDetailClient)
  var client

  @Dependency(\.communityClient)
  var communityClient

  private static let logger = Logger(subsystem: "com.wepli", category: "PostDetail")

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.post == nil else { return .none }
        return self.load(&state)

      case let .loaded(thread):
        state.post = thread.post
        state.comments = IdentifiedArray(uniqueElements: thread.comments)
        // 처음에는 첫 댓글의 답글을 펼쳐 둔다(원본 c1)
        if let first = thread.comments.first(where: { !$0.replies.isEmpty }) {
          state.expandedCommentIDs = [first.id]
        }
        return .none

      case .loadFailed:
        state.loadFailed = true
        return .none

      case .retryButtonTapped:
        return self.load(&state)

      case let .draftChanged(text):
        state.draft = text
        return .none

      case .sendButtonTapped:
        guard let text = CommentInput.text(draft: state.draft, hasSong: state.replySong != nil) else { return .none }
        state.isSending = true
        let song = state.replySong
        let postID = state.postID
        return .run { send in
          do {
            try await send(.commentAdded(self.client.addComment(postID, text, song)))
          } catch {
            await send(.commentFailed)
          }
        }

      case let .commentAdded(comment):
        state.isSending = false
        state.comments.insert(comment, at: 0)
        state.draft = ""
        state.replySong = nil
        state.commentDelta += 1
        return .none

      case .commentFailed:
        state.isSending = false
        // 원본에 없는 문구 — 디자인 확인 필요
        state.toast = "댓글을 보내지 못했어요. 잠시 후 다시 시도해 주세요"
        return .none

      case let .repliesToggled(id):
        if state.expandedCommentIDs.remove(id) == nil {
          state.expandedCommentIDs.insert(id)
        }
        return .none

      case let .deleteCommentTapped(id):
        guard state.comments[id: id]?.isMine == true else { return .none }
        state.comments.remove(id: id)
        state.commentDelta -= 1
        return .run { _ in
          do {
            try await self.client.deleteComment(id)
          } catch {
            // 다음 불러오기 때 서버 값으로 맞춰진다
            Self.logger.error("댓글 삭제 실패")
          }
        }

      case let .commentLikeTapped(id):
        let liked = self.toggleCommentLike(id, in: &state)
        guard let liked else { return .none }
        return .run { _ in
          do {
            try await self.client.setCommentLiked(id, liked)
          } catch {
            Self.logger.error("댓글 좋아요 반영 실패")
          }
        }

      case .songReplyButtonTapped:
        guard state.allowsSongReply else { return .none }
        return state.replySong == nil ? .send(.delegate(.pickReplySong)) : .send(.replySongRemoved)

      case let .replySongPicked(track):
        state.replySong = track
        return .none

      case .replySongRemoved:
        state.replySong = nil
        return .none

      case .postLikeTapped:
        guard let previous = state.post?.isLiked else { return .none }
        self.setPostLiked(!previous, in: &state)
        let id = state.postID
        return .run { send in
          do {
            try await self.communityClient.setLiked(id, !previous)
          } catch {
            await send(.postLikeFailed(restore: previous))
          }
        }

      case let .postLikeFailed(restore):
        self.setPostLiked(restore, in: &state)
        return .none

      case .postSaveTapped:
        guard let previous = state.post?.isSaved else { return .none }
        state.post?.isSaved = !previous
        let id = state.postID
        return .run { send in
          do {
            try await self.communityClient.setSaved(id, !previous)
          } catch {
            await send(.postSaveFailed(restore: previous))
          }
        }

      case let .postSaveFailed(restore):
        state.post?.isSaved = restore
        return .none

      case .toastDismissed:
        state.toast = nil
        return .none

      case .backButtonTapped:
        return .send(.delegate(.dismiss))

      case .moreButtonTapped:
        return .send(.delegate(.more(postID: state.postID)))

      case .playAttachmentTapped:
        return .send(.delegate(.play(postID: state.postID)))

      case let .authorTapped(user):
        return .send(.delegate(.showProfile(user)))

      case .delegate:
        return .none
      }
    }
  }

  /// 댓글 · 답글 좋아요를 뒤집고 새 값을 돌려준다
  private func toggleCommentLike(_ id: PostComment.ID, in state: inout State) -> Bool? {
    if var comment = state.comments[id: id] {
      comment.isLiked.toggle()
      comment.likeCount += comment.isLiked ? 1 : -1
      state.comments[id: id] = comment
      return comment.isLiked
    }
    for parent in state.comments {
      guard let index = parent.replies.firstIndex(where: { $0.id == id }) else { continue }
      var reply = parent.replies[index]
      reply.isLiked.toggle()
      reply.likeCount += reply.isLiked ? 1 : -1
      state.comments[id: parent.id]?.replies[index] = reply
      return reply.isLiked
    }
    return nil
  }

  private func setPostLiked(_ isLiked: Bool, in state: inout State) {
    guard var post = state.post, post.isLiked != isLiked else { return }
    post.isLiked = isLiked
    post.likeCount += isLiked ? 1 : -1
    state.post = post
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.loadFailed = false
    let id = state.postID
    return .run { send in
      do {
        try await send(.loaded(self.client.fetch(id)))
      } catch {
        await send(.loadFailed)
      }
    }
  }
}
