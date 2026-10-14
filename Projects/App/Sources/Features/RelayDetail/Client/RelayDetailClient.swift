import ComposableArchitecture
import Foundation

// REQ-031 — 백엔드가 정해지기 전까지 원본(UI-3c) 예시 데이터를 돌려주는 목업이다.

struct RelayDetailClient {
  var fetch: @Sendable (_ id: String) async throws -> RelayDetail
}

extension RelayDetailClient: DependencyKey {
  static let liveValue = RelayDetailClient(
    fetch: { id in
      @Dependency(\.date.now)
      var now
      return .mock(id: id, now: now)
    }
  )

  static let previewValue = RelayDetailClient(
    fetch: { id in .mock(id: id, now: Date()) }
  )

  static let testValue = RelayDetailClient(
    fetch: unimplemented("RelayDetailClient.fetch", placeholder: .mock(id: "", now: Date()))
  )
}

extension DependencyValues {
  var relayDetailClient: RelayDetailClient {
    get { self[RelayDetailClient.self] }
    set { self[RelayDetailClient.self] = newValue }
  }
}

extension RelayDetail {
  /// 원본 예시 — 132명 참여 · 총 18곡 · 순위 7곡 · 36시간 10분 15초 남음
  static func mock(id: String, now: Date) -> RelayDetail {
    let songs: [(String, String)] = [
      ("밤양갱", "비비(bibi)"),
      ("첫 만남은 계획대로 되지 않아", "TWS (투어스)"),
      ("EASY", "LE SSERAFIM (르세라핌)"),
      ("Love 119", "RIIZE"),
      ("비의 랩소디", "임재현"),
      ("비와 당신", "이무진"),
      ("Hype Boy", "NewJeans"),
    ]
    return RelayDetail(
      id: id,
      title: "첫 사랑이 생각나는\n노래 모음",
      openedOn: "2024.05.03",
      status: .live(endsAt: now.addingTimeInterval(36 * 3600 + 10 * 60 + 15)),
      participantCount: 132,
      totalSongCount: 18,
      ranking: songs.enumerated().map { RankedSong(rank: $0.offset + 1, title: $0.element.0, artist: $0.element.1) },
      // 릴레이 탭 목업(UI-10a)의 월드컵 릴레이와 맞춘다
      voteFormat: ["summer-idol", "wake-up"].contains(id) ? .worldCup : .card
    )
  }
}
