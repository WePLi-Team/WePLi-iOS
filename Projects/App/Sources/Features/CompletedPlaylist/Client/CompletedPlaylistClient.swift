import ComposableArchitecture
import Foundation

// REQ-040 · DEC-004 — 백엔드가 정해지기 전까지 원본(UI-14b) 예시를 돌려주는 목업이다.

struct CompletedPlaylistClient {
  var fetch: @Sendable (_ relayID: String) async throws -> CompletedPlaylist
  var setLiked: @Sendable (_ relayID: String, _ isLiked: Bool) async throws -> Void
  var setSaved: @Sendable (_ relayID: String, _ isSaved: Bool) async throws -> Void
  /// 호스트의 다음 릴레이 알림
  var setNextRelayAlert: @Sendable (_ nextRelayID: String, _ isOn: Bool) async throws -> Void
}

extension CompletedPlaylistClient: DependencyKey {
  static let liveValue = CompletedPlaylistClient(
    fetch: { id in .mock(id: id) },
    setLiked: { _, _ in },
    setSaved: { _, _ in },
    setNextRelayAlert: { _, _ in }
  )

  static let previewValue = liveValue

  static let testValue = CompletedPlaylistClient(
    fetch: unimplemented("CompletedPlaylistClient.fetch", placeholder: .mock(id: "")),
    setLiked: unimplemented("CompletedPlaylistClient.setLiked"),
    setSaved: unimplemented("CompletedPlaylistClient.setSaved"),
    setNextRelayAlert: unimplemented("CompletedPlaylistClient.setNextRelayAlert")
  )
}

extension DependencyValues {
  var completedPlaylistClient: CompletedPlaylistClient {
    get { self[CompletedPlaylistClient.self] }
    set { self[CompletedPlaylistClient.self] = newValue }
  }
}

extension CompletedPlaylist {
  /// 원본(UI-14b) 예시
  static func mock(id: String) -> CompletedPlaylist {
    CompletedPlaylist(
      id: id,
      title: "졸릴 때 잠 깨는\n청량맛 노동요",
      recommenderCount: 248,
      voterCount: 1284,
      songCount: 12,
      completedOn: "10월 12일",
      host: "minnie._.",
      likeCount: 1204,
      isLiked: false,
      isSaved: false,
      commentCount: 86,
      ranking: self.mockRanking,
      predictionResult: "1위 예측 적중 · 예언자 +1",
      comments: [
        Comment(
          id: "c1",
          author: "chuuuuu__",
          timeText: "2시간 전",
          text: "마지막 40분 역전 미쳤다… Supernova 1위 지켜서 다행",
          likeCount: 24
        ),
        Comment(id: "c2", author: "dlwlrma", timeText: "5시간 전", text: "출근길에 Apple Music으로 담아서 듣는 중이에요", likeCount: 11),
      ],
      nextRelay: NextRelay(id: "commute", title: "퇴근길 지하철 플리", meta: "10월 20일 시작 · #퇴근길 #지하철"),
      isNextRelayAlertOn: false,
      similar: [
        SimilarPlaylist(id: "first-love", title: "첫 사랑이 생각나는 노래 모음"),
        SimilarPlaylist(id: "dawn-drive", title: "새벽 드라이브 필수곡"),
        SimilarPlaylist(id: "summer-hiphop", title: "청량함 가득 여름 국힙"),
        SimilarPlaylist(id: "p2", title: "노을처럼 번지는 아날로그 무드"),
      ],
      exportedTo: nil
    )
  }

  private static let mockRanking: [Song] = [
    Song(id: "supernova", title: "Supernova", artist: "aespa", recommender: "chuuuuu__", isMine: false),
    Song(id: "how-sweet", title: "How Sweet", artist: "NewJeans", recommender: "dlwlrma", isMine: false),
    Song(id: "hype", title: "Hype Boy", artist: "NewJeans", recommender: "roykim", isMine: false),
    Song(id: "easy", title: "EASY", artist: "LE SSERAFIM (르세라핌)", recommender: "김동", isMine: true),
    Song(id: "heya", title: "해야 (HEYA)", artist: "IVE (아이브)", recommender: "chuuuuu__", isMine: false),
    Song(id: "love119", title: "Love 119", artist: "RIIZE", recommender: "roykim", isMine: false),
  ]
}
