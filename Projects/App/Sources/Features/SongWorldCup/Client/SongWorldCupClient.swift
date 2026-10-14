import ComposableArchitecture
import Foundation

// REQ-034 · DEC-004 — 대진 곡(상위 8곡)과 집계는 서버 기준. 백엔드가 정해지기 전까지 원본(UI-8b) 예시를 돌려주는 목업이다.

struct SongWorldCupClient {
  /// 지금 순위 상위 8곡(순위 순)
  var fetchSongs: @Sendable (_ relayID: String) async throws -> [WorldCupSong]
  /// 내 우승곡을 보내고 다른 사람들의 결과를 받는다
  var submit: @Sendable (_ relayID: String, _ championID: String) async throws -> WorldCupCrowd
}

extension SongWorldCupClient: DependencyKey {
  static let liveValue = SongWorldCupClient(
    fetchSongs: { _ in WorldCupSong.mock },
    submit: { _, championID in
      WorldCupCrowd(
        topSongID: "bam",
        topSongTitle: "밤양갱",
        topPercent: 32,
        myChampionRank: championID == "easy" ? 3 : nil
      )
    }
  )

  static let previewValue = liveValue

  static let testValue = SongWorldCupClient(
    fetchSongs: unimplemented("SongWorldCupClient.fetchSongs", placeholder: []),
    submit: unimplemented(
      "SongWorldCupClient.submit",
      placeholder: WorldCupCrowd(topSongID: "", topSongTitle: "", topPercent: 0, myChampionRank: nil)
    )
  )
}

extension DependencyValues {
  var songWorldCupClient: SongWorldCupClient {
    get { self[SongWorldCupClient.self] }
    set { self[SongWorldCupClient.self] = newValue }
  }
}

extension WorldCupSong {
  /// 원본(UI-8b) 예시 8곡 — 순위 순
  static let mock: [WorldCupSong] = [
    WorldCupSong(id: "bam", title: "밤양갱", artist: "비비(bibi)", recommender: "roykim"),
    WorldCupSong(id: "night", title: "우리의 밤은 당신의 낮보다 아름답다", artist: "츄(CHUU)", recommender: "boyoung"),
    WorldCupSong(id: "easy", title: "EASY", artist: "LE SSERAFIM", recommender: "김동"),
    WorldCupSong(id: "love119", title: "Love 119", artist: "RIIZE", recommender: "woogi"),
    WorldCupSong(id: "rhapsody", title: "비의 랩소디", artist: "임재현", recommender: "chuuuuu__"),
    WorldCupSong(id: "rain", title: "비와 당신", artist: "이무진", recommender: "dlwlrma"),
    WorldCupSong(id: "hype", title: "Hype Boy", artist: "NewJeans", recommender: "younha_holic"),
    WorldCupSong(id: "first", title: "첫 만남은 계획대로 되지 않아", artist: "TWS (투어스)", recommender: "minnie._."),
  ]
}
