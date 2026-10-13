import ComposableArchitecture
import Foundation

// REQ-030 — 백엔드가 정해지기 전까지 liveValue도 목업이다(AGENTS.md 「미결정」).

struct RelayClient {
  var fetchRelays: @Sendable () async throws -> [Relay]
}

extension RelayClient: DependencyKey {
  static let liveValue = RelayClient(
    fetchRelays: {
      @Dependency(\.date.now)
      var now
      return RelayMockData.relays(now: now)
    }
  )

  static let previewValue = RelayClient(
    fetchRelays: { RelayMockData.relays(now: Date()) }
  )

  static let testValue = RelayClient(
    fetchRelays: unimplemented("RelayClient.fetchRelays", placeholder: [])
  )
}

extension DependencyValues {
  var relayClient: RelayClient {
    get { self[RelayClient.self] }
    set { self[RelayClient.self] = newValue }
  }
}

/// 원본(UI-10a) 예시 데이터 6건. 마감은 지금 기준 2.3 · 36.2 · 9.5 · 61시간 뒤.
enum RelayMockData {
  static func relays(now: Date) -> [Relay] {
    let make = { (id: String, title: String, format: Relay.VoteFormat, people: Int, hoursLeft: Double?, isMine: Bool) in
      Relay(
        id: id,
        title: title,
        voteFormat: format,
        participantCount: people,
        status: hoursLeft.map { .live(endsAt: now.addingTimeInterval($0 * 3600)) } ?? .completed,
        isMine: isMine
      )
    }
    return [
      make("cafe-bgm", "손님들이 물어보는 카페 BGM", .card, 3012, 2.3, true),
      make("summer-idol", "시원한 여름을 책임질 아이돌 노래 모음", .worldCup, 2184, 36.2, false),
      make("rainy-night", "비 오는 밤 이어달리기", .baton, 8, 9.5, true),
      make("first-love", "첫 사랑이 생각나는 노래 모음", .card, 132, 61, false),
      make("wake-up", "졸릴 때 잠 깨는 청량맛 노동요", .worldCup, 1284, nil, true),
      make("childhood", "그때 그 시절, 어린 날의 노래", .card, 948, nil, false),
    ]
  }
}
