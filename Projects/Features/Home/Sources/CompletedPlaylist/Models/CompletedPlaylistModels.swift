import Foundation

// REQ-040 · UI-14b — 완성 플리 · 기준 화면. 순위 · 추천자 · 수는 서버 값(DEC-004)

public struct CompletedPlaylist: Equatable, Identifiable, Sendable {
  public struct Song: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let artist: String
    /// 곡을 추천한 사람(크레딧은 아바타로만 보인다)
    public let recommender: String
    public let isMine: Bool

    public init(id: String, title: String, artist: String, recommender: String, isMine: Bool) {
      self.id = id
      self.title = title
      self.artist = artist
      self.recommender = recommender
      self.isMine = isMine
    }
  }

  public struct Comment: Equatable, Identifiable, Sendable {
    public let id: String
    public let author: String
    /// 「2시간 전」
    public let timeText: String
    public let text: String
    public let likeCount: Int

    public init(id: String, author: String, timeText: String, text: String, likeCount: Int) {
      self.id = id
      self.author = author
      self.timeText = timeText
      self.text = text
      self.likeCount = likeCount
    }
  }

  public struct NextRelay: Equatable, Sendable {
    public let id: String
    public let title: String
    /// 「10월 20일 시작 · #퇴근길 #지하철」
    public let meta: String

    public init(id: String, title: String, meta: String) {
      self.id = id
      self.title = title
      self.meta = meta
    }
  }

  /// 릴레이 id
  public let id: String
  /// 「졸릴 때 잠 깨는\n청량맛 노동요」
  public let title: String
  public let recommenderCount: Int
  public let voterCount: Int
  public let songCount: Int
  /// 「10월 12일」
  public let completedOn: String
  public let host: String
  public var likeCount: Int
  public var isLiked: Bool
  public var isSaved: Bool
  public let commentCount: Int
  /// 최종 순위 — 위에서부터
  public let ranking: [Song]
  /// 1위 예측을 맞혔으면 「1위 예측 적중 · 예언자 +1」
  public let predictionResult: String?
  public let comments: [Comment]
  public var nextRelay: NextRelay?
  public var isNextRelayAlertOn: Bool
  public let similar: [SimilarPlaylist]
  /// 이미 내 음악 앱에 담았으면 그 서비스 이름(「Apple Music」)
  public let exportedTo: String?

  /// 「248명이 추천한 12곡 · 10월 12일 완성」
  public var stats: String {
    "\(HomeText.count(self.recommenderCount))명이 추천한 \(self.songCount)곡 · \(self.completedOn) 완성"
  }

  /// 「추천 248명 · 투표 1,284명」
  public var rankingMeta: String {
    "추천 \(HomeText.count(self.recommenderCount))명 · 투표 \(HomeText.count(self.voterCount))명"
  }

  /// 내 추천곡 중 가장 높은 곡과 순위
  public var myBest: (song: Song, rank: Int)? {
    guard let index = self.ranking.firstIndex(where: \.isMine) else { return nil }
    return (self.ranking[index], index + 1)
  }

  /// 「내 음악 앱으로 내보내기」 · 이미 담았으면 「Apple Music에서 열기」
  public var exportTitle: String {
    self.exportedTo.map { "\($0)에서 열기" } ?? "내 음악 앱으로 내보내기"
  }

  public init(
    id: String,
    title: String,
    recommenderCount: Int,
    voterCount: Int,
    songCount: Int,
    completedOn: String,
    host: String,
    likeCount: Int,
    isLiked: Bool,
    isSaved: Bool,
    commentCount: Int,
    ranking: [Song],
    predictionResult: String?,
    comments: [Comment],
    nextRelay: NextRelay? = nil,
    isNextRelayAlertOn: Bool,
    similar: [SimilarPlaylist],
    exportedTo: String?
  ) {
    self.id = id
    self.title = title
    self.recommenderCount = recommenderCount
    self.voterCount = voterCount
    self.songCount = songCount
    self.completedOn = completedOn
    self.host = host
    self.likeCount = likeCount
    self.isLiked = isLiked
    self.isSaved = isSaved
    self.commentCount = commentCount
    self.ranking = ranking
    self.predictionResult = predictionResult
    self.comments = comments
    self.nextRelay = nextRelay
    self.isNextRelayAlertOn = isNextRelayAlertOn
    self.similar = similar
    self.exportedTo = exportedTo
  }
}

public struct SimilarPlaylist: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String

  public init(id: String, title: String) {
    self.id = id
    self.title = title
  }
}
