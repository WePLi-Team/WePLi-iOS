import ComposableArchitecture
import Foundation

// REQ-060 — 백엔드가 정해지기 전까지 목업이다. 좋아요 · 저장은 서버 값이 원본(DEC-004).

struct CommunityClient {
  var fetchFeed: @Sendable () async throws -> CommunityFeed
  var setLiked: @Sendable (_ postID: Post.ID, _ isLiked: Bool) async throws -> Void
  var setSaved: @Sendable (_ postID: Post.ID, _ isSaved: Bool) async throws -> Void
}

extension CommunityClient: DependencyKey {
  static let liveValue = CommunityClient(
    fetchFeed: { .mock },
    setLiked: { _, _ in },
    setSaved: { _, _ in }
  )

  static let previewValue = liveValue

  static let testValue = CommunityClient(
    fetchFeed: unimplemented("CommunityClient.fetchFeed", placeholder: .mock),
    setLiked: unimplemented("CommunityClient.setLiked"),
    setSaved: unimplemented("CommunityClient.setSaved")
  )
}

extension DependencyValues {
  var communityClient: CommunityClient {
    get { self[CommunityClient.self] }
    set { self[CommunityClient.self] = newValue }
  }
}

/// 원본(UI-1d) 예시 데이터
extension CommunityFeed {
  static let mock = CommunityFeed(
    stories: [
      Story(user: "chuuuuu__", isFresh: true),
      Story(user: "roykim", isFresh: true),
      Story(user: "minnie._.", isFresh: true),
      Story(user: "woogi", isFresh: false),
      Story(user: "dlwlrma", isFresh: false),
    ],
    posts: [
      Post(
        id: "p1",
        author: "dlwlrma",
        title: "밤새면서 들을 수 있는 플리",
        body: "여러분은 코딩할 때 어떤 곡을 듣나요?! 댓글로 알려주세요!\n제가 주로 듣는 곡들을 플레이리스트로 만들어봤어요~\n\n같이 들으면 좋을만한 노래 추천해주세요!",
        attachment: .playlist([
          Track(title: "Love poem", artist: "아이유(IU)"),
          Track(title: "우리의 밤은 당신보다...", artist: "츄(CHUU)"),
          Track(title: "Diamond", artist: "로시(Rothy)"),
        ]),
        likeCount: 10123,
        commentCount: 923,
        isLiked: false,
        isSaved: false
      ),
      Post(
        id: "p2",
        author: "chuuuuu__",
        title: "요즘 최애노래",
        body: "케이윌이랑 매드클라운 조합 너무 좋아요ㅠㅠ\n가볍게 듣기에도 좋고 은근 밝은 느낌이라서 더 좋아요\n\n다들 한 번씩 들어보세요~~~",
        attachment: .song(Track(title: "그게 뭐라고", artist: "케이윌 및 매드클라운")),
        likeCount: 11901,
        commentCount: 1243,
        isLiked: false,
        isSaved: false
      ),
      Post(
        id: "p3",
        author: "minnie._.",
        title: "너무 심심해요ㅠㅠ",
        body: "주말에 하루종일 아무것도 할 게 없어서 심심하네요\n스피커도 새로 샀는데 들을 노래도 없고..\n\n혼자서 심심할 때 듣기 좋은 노래 추천 부탁드려요 :)",
        attachment: .none,
        likeCount: 8923,
        commentCount: 671,
        isLiked: false,
        isSaved: false
      ),
      Post(
        id: "p4",
        author: "chuuuuu__",
        title: "이것도 들어봐ㅏㅏㅏ",
        body: "이것도 들어봐바\n봄이면 꼭 들어야 돼 나만 들을 순 없어\n\n빨리 다들 한 번씩 듣고 댓글로 감상평 남겨ㅡㅡ",
        attachment: .song(Track(title: "나는 아픈 건 딱 질색이니까", artist: "(여자)아이들")),
        likeCount: 11901,
        commentCount: 1243,
        isLiked: true,
        isSaved: true
      ),
    ]
  )
}
