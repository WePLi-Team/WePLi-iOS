import ComposableArchitecture
import Foundation

// REQ-063 · DEC-004 — 백엔드가 정해지기 전까지 원본(UI-2c · 9c · 9d) 예시를 돌려주는 목업이다.

struct PostDetailClient {
  var fetch: @Sendable (_ postID: Post.ID) async throws -> PostThread
  /// 서버가 만든 댓글(id · 시간)을 돌려준다
  var addComment: @Sendable (_ postID: Post.ID, _ text: String, _ song: Track?) async throws -> PostComment
  var deleteComment: @Sendable (_ commentID: PostComment.ID) async throws -> Void
  var setCommentLiked: @Sendable (_ commentID: PostComment.ID, _ isLiked: Bool) async throws -> Void
}

extension PostDetailClient: DependencyKey {
  static let liveValue = PostDetailClient(
    fetch: { id in .mock(postID: id) },
    addComment: { _, text, song in
      @Dependency(\.uuid)
      var uuid
      return PostComment(
        id: uuid().uuidString,
        author: "김동",
        timeText: "방금",
        text: text,
        song: song,
        likeCount: 0,
        isMine: true
      )
    },
    deleteComment: { _ in },
    setCommentLiked: { _, _ in }
  )

  static let previewValue = liveValue

  static let testValue = PostDetailClient(
    fetch: unimplemented("PostDetailClient.fetch", placeholder: .mock(postID: "p4")),
    addComment: unimplemented(
      "PostDetailClient.addComment",
      placeholder: PostComment(id: "", author: "", timeText: "", text: "", likeCount: 0)
    ),
    deleteComment: unimplemented("PostDetailClient.deleteComment"),
    setCommentLiked: unimplemented("PostDetailClient.setCommentLiked")
  )
}

extension DependencyValues {
  var postDetailClient: PostDetailClient {
    get { self[PostDetailClient.self] }
    set { self[PostDetailClient.self] = newValue }
  }
}

extension PostThread {
  /// 원본 예시 — 게시글은 커뮤니티 피드 목업, 댓글은 타입별 원본 예시
  static func mock(postID: Post.ID) -> PostThread {
    let post = CommunityFeed.mock.posts.first { $0.id == postID } ?? CommunityFeed.mock.posts[3]
    switch post.attachment {
    case .song: return PostThread(post: post, comments: self.songComments)
    case .playlist: return PostThread(post: post, comments: self.playlistComments)
    case .none: return PostThread(post: post, comments: self.textComments)
    }
  }

  /// 한 곡 타입(UI-2c)
  private static let songComments: [PostComment] = [
    PostComment(
      id: "c1",
      author: "boyoung0212_official",
      timeText: "2시간",
      text: "오~ 이거 듣고 나니까 진짜 봄이 온 기분ㅋㅋ 기분 전환하기 딱 좋아요! 여러분도 꼭 들어보세요!",
      likeCount: 128,
      replies: [
        PostComment(
          id: "r1",
          author: "younha_holic",
          timeText: "1시간",
          text: "나도 이 노래 들었는데 진짜 봄 기운 물씬! 꽃길만 걷게 되는 느낌ㅋㅋ 다들 꽃구경 가면서 들으면 기분 최고일 듯!",
          likeCount: 12
        ),
        PostComment(id: "r2", author: "__yujin_an", timeText: "1시간", text: "ㅇㅈ 이 노래 진짜 좋음ㅠㅠ", likeCount: 4),
      ]
    ),
    PostComment(id: "c2", author: "dbeoddl__", timeText: "3시간", text: "봄노래 찾던 중에 이걸로 정착! 상큼터짐 최고ㅠㅠ", likeCount: 56),
  ]

  /// 플레이리스트 타입(UI-9c)
  private static let playlistComments: [PostComment] = [
    PostComment(
      id: "pc1",
      author: "minnie._.",
      timeText: "3시간",
      text: "처음 들어보는데 완전 봄 느낌 물씬 나네요! 기분 전환도 되고 화창한 봄날 거리를 걷는 기분이 들어요. 좋은 곡 공유해줘서 감사합니다!",
      likeCount: 0
    ),
    PostComment(
      id: "pc2",
      author: "woogi",
      timeText: "2시간",
      text: "봄맞이로 딱 좋네요! 이런 신나는 곡 들으니까 겨울잠에서 깬 느낌ㅎㅎ",
      likeCount: 0
    ),
  ]

  /// 일반 타입 — 노래로 답한 댓글이 먼저(UI-9d)
  private static let textComments: [PostComment] = [
    PostComment(
      id: "gc1",
      author: "woogi",
      timeText: "20시간",
      text: "심심할 땐 무조건 이거죠",
      song: Track(title: "Hype Boy", artist: "NewJeans"),
      likeCount: 0
    ),
    PostComment(
      id: "gc2",
      author: "younha_holic",
      timeText: "18시간",
      text: "새 스피커로 들으면 소름 돋을 걸요",
      song: Track(title: "비가 내리는 날에는", artist: "윤하"),
      likeCount: 0
    ),
    PostComment(id: "gc3", author: "roykim", timeText: "12시간", text: "저도 주말에 할 거 없어서 공감ㅋㅋ", likeCount: 0),
  ]
}
