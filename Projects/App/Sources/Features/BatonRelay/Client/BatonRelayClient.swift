import ComposableArchitecture
import Foundation

// REQ-035 · DEC-004 — 차례 · 시간 · 다음 사람은 서버가 정한다. 백엔드가 정해지기 전까지 원본(UI-8c · 11c) 예시 목업이다.
// 미결정 — 다음 사람을 정하는 방법 · 초대 링크를 보내는 방법 · 24시간이 지났을 때 · 8명이 다 이었을 때

struct BatonRelayClient {
  var fetch: @Sendable (_ relayID: String) async throws -> BatonRelay
  /// 바통 받기 — 24시간 타이머가 시작된다. 끝나는 시각을 돌려준다
  var accept: @Sendable (_ relayID: String) async throws -> Date
  /// 이번엔 다음 사람에게 넘기기
  var skip: @Sendable (_ relayID: String) async throws -> Void
  /// 곡과 다음 키워드를 골라 넘긴다
  var pass: @Sendable (_ relayID: String, _ pickID: BatonRelay.Pick.ID, _ keyword: String) async throws -> BatonRelay
}

extension BatonRelayClient: DependencyKey {
  static let liveValue = BatonRelayClient(
    fetch: { .mock(id: $0) },
    accept: { _ in
      @Dependency(\.date.now)
      var now
      return now.addingTimeInterval(BatonText.turnLength)
    },
    skip: { _ in },
    pass: { relayID, pickID, keyword in .mock(id: relayID).passed(pickID: pickID, keyword: keyword) }
  )

  static let previewValue = liveValue

  static let testValue = BatonRelayClient(
    fetch: unimplemented("BatonRelayClient.fetch", placeholder: .mock(id: "")),
    accept: unimplemented("BatonRelayClient.accept", placeholder: Date(timeIntervalSince1970: 0)),
    skip: unimplemented("BatonRelayClient.skip"),
    pass: unimplemented("BatonRelayClient.pass", placeholder: .mock(id: ""))
  )
}

extension DependencyValues {
  var batonRelayClient: BatonRelayClient {
    get { self[BatonRelayClient.self] }
    set { self[BatonRelayClient.self] = newValue }
  }
}

extension BatonRelay {
  /// 원본 예시 — 링크로 막 들어온 상태(11c)에서 시작한다. 7 · 8번째 사람은 원본에 이름이 없다
  static func mock(id: String) -> BatonRelay {
    BatonRelay(
      id: id,
      title: "비 오는 밤 이어달리기",
      runners: ["roykim", "minnie._.", "woogi", "chuuuuu__", "김동", "dlwlrma", "runner-7", "runner-8"].enumerated().map {
        Runner(id: $0.element, name: $0.element, state: $0.offset < 4 ? .done : $0.offset == 4 ? .now : .waiting)
      },
      chain: [
        Link(runner: "roykim", title: "비와 당신", artist: "이무진", keywordFrom: "시작", keyword: "#비"),
        Link(runner: "minnie._.", title: "비의 랩소디", artist: "임재현", keywordFrom: "#비 이어받음", keyword: "#새벽"),
        Link(
          runner: "woogi",
          title: "Perhaps Love (사랑인가요)",
          artist: "에릭남(Eric Nam)",
          keywordFrom: "#새벽 이어받음",
          keyword: "#고백"
        ),
        Link(runner: "chuuuuu__", title: "너의 바다", artist: "호피폴라", keywordFrom: "#고백 이어받음", keyword: "#바다"),
      ],
      keyword: "#바다",
      picks: [
        Pick(id: "supernova", title: "Supernova", artist: "aespa"),
        Pick(id: "how-sweet", title: "How Sweet", artist: "NewJeans"),
        Pick(id: "palette", title: "팔레트 (Feat. G-DRAGON)", artist: "아이유 (IU)"),
      ],
      nextKeywords: ["#여름", "#청량", "#여행"],
      nextRunner: "dlwlrma",
      turn: .invited(passer: "chuuuuu__")
    )
  }

  /// 넘긴 뒤 — 내 곡이 이어지고 다음 사람이 달린다
  func passed(pickID: Pick.ID, keyword: String) -> BatonRelay {
    var relay = self
    guard let pick = self.picks.first(where: { $0.id == pickID }) else { return relay }
    relay.chain.append(Link(
      runner: "김동",
      title: pick.title,
      artist: pick.artist,
      keywordFrom: "\(self.keyword) 이어받음",
      keyword: keyword
    ))
    relay.runners = relay.runners.enumerated().map { index, runner in
      var runner = runner
      runner.state = index < relay.chain.count ? .done : index == relay.chain.count ? .now : .waiting
      return runner
    }
    relay.turn = .passed(keyword: keyword)
    return relay
  }
}
