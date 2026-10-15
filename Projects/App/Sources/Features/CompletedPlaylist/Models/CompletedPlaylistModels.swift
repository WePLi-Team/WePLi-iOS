import Foundation

// REQ-040 · UI-14b — 완성 플리 · 기준 화면. 순위 · 추천자 · 수는 서버 값(DEC-004)

struct CompletedPlaylist: Equatable, Identifiable, Sendable {
  struct Song: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let artist: String
    /// 곡을 추천한 사람(크레딧은 아바타로만 보인다)
    let recommender: String
    let isMine: Bool
  }

  struct Comment: Equatable, Identifiable, Sendable {
    let id: String
    let author: String
    /// 「2시간 전」
    let timeText: String
    let text: String
    let likeCount: Int
  }

  struct NextRelay: Equatable, Sendable {
    let id: String
    let title: String
    /// 「10월 20일 시작 · #퇴근길 #지하철」
    let meta: String
  }

  /// 릴레이 id
  let id: String
  /// 「졸릴 때 잠 깨는\n청량맛 노동요」
  let title: String
  let recommenderCount: Int
  let voterCount: Int
  let songCount: Int
  /// 「10월 12일」
  let completedOn: String
  let host: String
  var likeCount: Int
  var isLiked: Bool
  var isSaved: Bool
  let commentCount: Int
  /// 최종 순위 — 위에서부터
  let ranking: [Song]
  /// 1위 예측을 맞혔으면 「1위 예측 적중 · 예언자 +1」
  let predictionResult: String?
  let comments: [Comment]
  var nextRelay: NextRelay?
  var isNextRelayAlertOn: Bool
  let similar: [SimilarPlaylist]
  /// 이미 내 음악 앱에 담았으면 그 서비스 이름(「Apple Music」)
  let exportedTo: String?

  /// 「248명이 추천한 12곡 · 10월 12일 완성」
  var stats: String {
    "\(HomeText.count(self.recommenderCount))명이 추천한 \(self.songCount)곡 · \(self.completedOn) 완성"
  }

  /// 「추천 248명 · 투표 1,284명」
  var rankingMeta: String {
    "추천 \(HomeText.count(self.recommenderCount))명 · 투표 \(HomeText.count(self.voterCount))명"
  }

  /// 내 추천곡 중 가장 높은 곡과 순위
  var myBest: (song: Song, rank: Int)? {
    guard let index = self.ranking.firstIndex(where: \.isMine) else { return nil }
    return (self.ranking[index], index + 1)
  }

  /// 「내 음악 앱으로 내보내기」 · 이미 담았으면 「Apple Music에서 열기」
  var exportTitle: String {
    self.exportedTo.map { "\($0)에서 열기" } ?? "내 음악 앱으로 내보내기"
  }
}

struct SimilarPlaylist: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
}
