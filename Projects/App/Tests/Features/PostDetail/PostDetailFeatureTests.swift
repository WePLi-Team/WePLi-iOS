import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-063 · REQ-064 · UI-2c · UI-9d · DEC-004

@MainActor
final class PostDetailFeatureTests: XCTestCase {
  private func loaded(_ id: Post.ID) -> PostDetailFeature.State {
    var state = PostDetailFeature.State(postID: id)
    let thread = PostThread.mock(postID: id)
    state.post = thread.post
    state.comments = IdentifiedArray(uniqueElements: thread.comments)
    return state
  }

  func testCommentInput_rules() {
    XCTAssertNil(CommentInput.text(draft: "   ", hasSong: false))
    XCTAssertEqual(CommentInput.text(draft: " 좋아요 ", hasSong: false), "좋아요")
    XCTAssertEqual(CommentInput.text(draft: "", hasSong: true), "이 노래 추천해요")
  }

  func testLikeText_hiddenWhenZero() {
    XCTAssertNil(PostComment(id: "a", author: "a", timeText: "방금", text: "t", likeCount: 0).likeText)
    XCTAssertEqual(PostComment(id: "a", author: "a", timeText: "방금", text: "t", likeCount: 1243).likeText, "1,243")
  }

  func testLoad_expandsFirstThreadWithReplies() async {
    let store = TestStore(initialState: PostDetailFeature.State(postID: "p4")) {
      PostDetailFeature()
    } withDependencies: {
      $0.postDetailClient.fetch = { .mock(postID: $0) }
    }
    store.exhaustivity = .off

    await store.send(.onAppear)
    await store.receive(\.loaded)
    XCTAssertEqual(store.state.expandedCommentIDs, ["c1"])
    XCTAssertEqual(store.state.commentCount, 1243)
  }

  func testSend_insertsOnTopAndResets() async {
    let mine = PostComment(id: "m1", author: "김동", timeText: "방금", text: "저도 좋아요", likeCount: 0, isMine: true)
    let store = TestStore(initialState: self.loaded("p4")) {
      PostDetailFeature()
    } withDependencies: {
      $0.postDetailClient.addComment = { _, _, _ in mine }
    }

    await store.send(.draftChanged(" 저도 좋아요 ")) { $0.draft = " 저도 좋아요 " }
    await store.send(.sendButtonTapped) { $0.isSending = true }
    await store.receive(.commentAdded(mine)) {
      $0.isSending = false
      $0.comments.insert(mine, at: 0)
      $0.draft = ""
      $0.commentDelta = 1
    }
    XCTAssertEqual(store.state.commentCount, 1244)
  }

  func testBlankDraft_cannotSend() async {
    let store = TestStore(initialState: self.loaded("p4")) {
      PostDetailFeature()
    }
    await store.send(.draftChanged("   ")) { $0.draft = "   " }
    XCTAssertFalse(store.state.canSend)
    await store.send(.sendButtonTapped)
  }

  func testSongReply_onlyOnTextPostsAndSendsDefaultText() async {
    XCTAssertFalse(self.loaded("p4").allowsSongReply)
    let song = Track(title: "밤양갱", artist: "비비(bibi)")
    let sent = LockIsolated<String?>(nil)
    let store = TestStore(initialState: self.loaded("p3")) {
      PostDetailFeature()
    } withDependencies: {
      $0.postDetailClient.addComment = { _, text, song in
        sent.setValue(text)
        return PostComment(id: "m2", author: "김동", timeText: "방금", text: text, song: song, likeCount: 0, isMine: true)
      }
    }
    store.exhaustivity = .off

    await store.send(.songReplyButtonTapped)
    await store.receive(.delegate(.pickReplySong))
    await store.send(.replySongPicked(song)) { $0.replySong = song }
    await store.send(.sendButtonTapped)
    await store.receive(\.commentAdded)
    XCTAssertEqual(sent.value, "이 노래 추천해요")
    XCTAssertNil(store.state.replySong)
    XCTAssertEqual(store.state.comments.first?.song, song)
  }

  func testDelete_onlyMine() async {
    var state = self.loaded("p4")
    state.comments.insert(
      PostComment(id: "m1", author: "김동", timeText: "방금", text: "t", likeCount: 0, isMine: true),
      at: 0
    )
    let store = TestStore(initialState: state) {
      PostDetailFeature()
    } withDependencies: {
      $0.postDetailClient.deleteComment = { _ in }
    }

    await store.send(.deleteCommentTapped("c1"))
    await store.send(.deleteCommentTapped("m1")) {
      _ = $0.comments.remove(id: "m1")
      $0.commentDelta = -1
    }
  }

  func testReplyLike_togglesNestedReply() async {
    let store = TestStore(initialState: self.loaded("p4")) {
      PostDetailFeature()
    } withDependencies: {
      $0.postDetailClient.setCommentLiked = { _, _ in }
    }

    await store.send(.commentLikeTapped("r2")) {
      $0.comments[id: "c1"]?.replies[1].isLiked = true
      $0.comments[id: "c1"]?.replies[1].likeCount = 5
    }
  }

  func testRepliesToggle() async {
    let store = TestStore(initialState: self.loaded("p4")) {
      PostDetailFeature()
    }
    await store.send(.repliesToggled("c1")) { $0.expandedCommentIDs = ["c1"] }
    await store.send(.repliesToggled("c1")) { $0.expandedCommentIDs = [] }
  }
}
