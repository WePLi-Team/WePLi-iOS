import ComposableArchitecture
import Foundation

// REQ-033 · DEC-004 — 투표 결과는 서버가 원본이다. 백엔드가 정해지기 전까지 목업.

struct CardVoteClient {
  /// 상위 10곡(투표 대상)
  var fetchCandidates: @Sendable (_ relayID: String) async throws -> [VoteCandidate]
  var submit: @Sendable (_ relayID: String, _ songID: VoteCandidate.ID, _ choice: VoteChoice) async throws -> Void
}

extension CardVoteClient: DependencyKey {
  static let mockValue = CardVoteClient(
    fetchCandidates: { _ in VoteCandidate.mockTopTen },
    submit: { _, _, _ in }
  )

  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  static let liveValue = mockValue
  static let previewValue = mockValue

  static let testValue = CardVoteClient(
    fetchCandidates: unimplemented("CardVoteClient.fetchCandidates", placeholder: []),
    submit: unimplemented("CardVoteClient.submit")
  )
}

extension DependencyValues {
  var cardVoteClient: CardVoteClient {
    get { self[CardVoteClient.self] }
    set { self[CardVoteClient.self] = newValue }
  }
}

extension VoteCandidate {
  /// 원본(UI-3b) 예시 10곡
  static let mockTopTen: [VoteCandidate] = [
    VoteCandidate(id: "v1", title: "우리의 밤은 당신의 낮보다 아름답다", artist: "츄(CHUU)", voteCount: 16225),
    VoteCandidate(id: "v2", title: "Perhaps Love (사랑인가요) (Prod.By 박근태)", artist: "에릭남(Eric Nam)", voteCount: 14883),
    VoteCandidate(id: "v3", title: "너의 바다", artist: "호피폴라", voteCount: 12220),
    VoteCandidate(id: "v4", title: "밤양갱", artist: "비비(bibi)", voteCount: 11904),
    VoteCandidate(id: "v5", title: "첫 만남은 계획대로 되지 않아", artist: "TWS (투어스)", voteCount: 10582),
    VoteCandidate(id: "v6", title: "EASY", artist: "LE SSERAFIM (르세라핌)", voteCount: 9311),
    VoteCandidate(id: "v7", title: "Love 119", artist: "RIIZE", voteCount: 8760),
    VoteCandidate(id: "v8", title: "비의 랩소디", artist: "임재현", voteCount: 7415),
    VoteCandidate(id: "v9", title: "비와 당신", artist: "이무진", voteCount: 6203),
    VoteCandidate(id: "v10", title: "Hype Boy", artist: "NewJeans", voteCount: 5980),
  ]
}
