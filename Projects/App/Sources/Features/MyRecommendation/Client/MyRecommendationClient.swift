import ComposableArchitecture
import Foundation

// REQ-038 · DEC-004 — 실시간 순위는 서버가 정한다. 백엔드가 정해지기 전까지 원본(UI-8a) 타임라인을 따라 점수가 오르는 목업이다.

struct MyRecommendationClient {
  var fetchStanding: @Sendable (_ relayID: String) async throws -> RelayStanding
}

extension MyRecommendationClient: DependencyKey {
  /// 원본: 3.2초마다 EASY가 45점씩 올라 2,470점에서 멈춘다(9단계)
  private static let step = LockIsolated(0)

  static let liveValue = MyRecommendationClient(
    fetchStanding: { relayID in
      @Dependency(\.date.now)
      var now
      let current = step.withValue { value in
        defer { value = min(value + 1, 9) }
        return value
      }
      return RelayStanding.mock(relayID: relayID, step: current, now: now)
    }
  )

  static let previewValue = liveValue

  static let testValue = MyRecommendationClient(
    fetchStanding: unimplemented(
      "MyRecommendationClient.fetchStanding",
      placeholder: RelayStanding(relayID: "", title: "", endsAt: .distantFuture, songs: [])
    )
  )
}

extension DependencyValues {
  var myRecommendationClient: MyRecommendationClient {
    get { self[MyRecommendationClient.self] }
    set { self[MyRecommendationClient.self] = newValue }
  }
}

extension RelayStanding {
  /// 원본 예시 8곡(시작 순위 순) — EASY는 2,120점에서 시작한다
  static let mockSongs: [StandingSong] = [
    StandingSong(
      id: "bam",
      title: "밤양갱",
      artist: "비비(bibi)",
      recommender: "roykim",
      score: 2410,
      startRank: 1,
      isMine: false
    ),
    StandingSong(
      id: "first",
      title: "첫 만남은 계획대로 되지 않아",
      artist: "TWS (투어스)",
      recommender: "minnie._.",
      score: 2206,
      startRank: 2,
      isMine: false
    ),
    StandingSong(
      id: "easy",
      title: "EASY",
      artist: "LE SSERAFIM (르세라핌)",
      recommender: "김동 (나)",
      score: 2120,
      startRank: 3,
      isMine: true
    ),
    StandingSong(
      id: "love119",
      title: "Love 119",
      artist: "RIIZE",
      recommender: "woogi",
      score: 1980,
      startRank: 4,
      isMine: false
    ),
    StandingSong(
      id: "rhapsody",
      title: "비의 랩소디",
      artist: "임재현",
      recommender: "chuuuuu__",
      score: 1754,
      startRank: 5,
      isMine: false
    ),
    StandingSong(
      id: "rain",
      title: "비와 당신",
      artist: "이무진",
      recommender: "dlwlrma",
      score: 1610,
      startRank: 6,
      isMine: false
    ),
    StandingSong(
      id: "hype",
      title: "Hype Boy",
      artist: "NewJeans",
      recommender: "younha_holic",
      score: 1402,
      startRank: 7,
      isMine: false
    ),
    StandingSong(
      id: "rainy-day",
      title: "비가 내리는 날에는",
      artist: "",
      recommender: "김동 (나)",
      score: 1020,
      startRank: 8,
      isMine: true
    ),
  ]

  /// 원본 예시 — `step`만큼 EASY가 45점씩 오른 순위(최대 2,470점)
  static func mock(relayID: String, step: Int, now: Date) -> RelayStanding {
    let songs = self.mockSongs.map { song in
      var song = song
      if song.id == "easy" {
        song.score = min(2470, 2120 + step * 45)
      }
      return song
    }
    return RelayStanding(
      relayID: relayID,
      title: "첫 사랑이 생각나는 노래 모음",
      endsAt: now.addingTimeInterval(36 * 3600 + 10 * 60),
      songs: songs.sorted { $0.score > $1.score }
    )
  }
}
