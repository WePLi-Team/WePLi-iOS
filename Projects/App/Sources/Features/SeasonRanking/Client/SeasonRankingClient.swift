import ComposableArchitecture
import Foundation

// UI-8f · DEC-022 · DEC-004 — 시즌 · 점수 · 순위는 서버가 계산한다. 백엔드가 정해지기 전까지 원본 예시를 돌려주는 목업이다.

struct SeasonRankingClient {
  var fetch: @Sendable () async throws -> SeasonRanking
  var setFollowing: @Sendable (_ hostID: String, _ isOn: Bool) async throws -> Void
}

extension SeasonRankingClient: DependencyKey {
  static let liveValue = SeasonRankingClient(
    fetch: {
      @Dependency(\.date.now)
      var now
      return .mock(now: now)
    },
    setFollowing: { _, _ in }
  )

  static let previewValue = liveValue

  static let testValue = SeasonRankingClient(
    fetch: unimplemented("SeasonRankingClient.fetch", placeholder: .mock(now: Date(timeIntervalSince1970: 0))),
    setFollowing: unimplemented("SeasonRankingClient.setFollowing")
  )
}

extension DependencyValues {
  var seasonRankingClient: SeasonRankingClient {
    get { self[SeasonRankingClient.self] }
    set { self[SeasonRankingClient.self] = newValue }
  }
}

extension SeasonRanking {
  /// 원본(UI-8f) 예시 — 종료일은 지금부터 23일 뒤로 둔다
  static func mock(now: Date) -> SeasonRanking {
    SeasonRanking(
      seasonName: "시즌 3 · 가을",
      endsAt: now.addingTimeInterval(23 * 86400),
      me: Standing(rank: 128, change: 12, pointsToTop100: 68, score: 2340),
      entries: [
        Entry(rank: 1, name: "dlwlrma", title: nil, score: 9820),
        Entry(rank: 2, name: "chuuuuu__", title: nil, score: 9410),
        Entry(rank: 3, name: "roykim", title: nil, score: 8950),
        Entry(rank: 4, name: "minnie._.", title: "플레이리스트 MD", score: 7330),
        Entry(rank: 5, name: "younha_holic", title: "예언자", score: 6980),
        Entry(rank: 6, name: "woogi", title: "역전의 명수", score: 6420),
        Entry(rank: 7, name: "boyoung0212_official", title: "호스트", score: 5990),
        Entry(rank: 8, name: "jisu.wav", title: "플레이리스트 MD", score: 5410),
        Entry(rank: 9, name: "haneul.fm", title: "예언자", score: 5120),
        Entry(rank: 10, name: "sonder_", title: "호스트", score: 4880),
      ],
      nearby: [
        Entry(rank: 127, name: "cafe.bgm", title: "예언자", score: 2356),
        Entry(rank: 128, name: "김동", title: "플레이리스트 MD", score: 2340),
        Entry(rank: 129, name: "night.drive", title: "호스트", score: 2331),
      ],
      hosts: [
        SeasonHost(
          id: "chuuuuu__",
          name: "chuuuuu__",
          stats: "릴레이 12개 · 참여 3.2만 명",
          recentRelay: "졸릴 때 잠 깨는 청량맛 노동요",
          isFollowing: true
        ),
        SeasonHost(
          id: "dlwlrma",
          name: "dlwlrma",
          stats: "릴레이 8개 · 참여 2.1만 명",
          recentRelay: "밤새면서 들을 수 있는 플리",
          isFollowing: false
        ),
        SeasonHost(
          id: "roykim",
          name: "roykim",
          stats: "릴레이 5개 · 참여 9,840명",
          recentRelay: "새벽 드라이브 같이 들어요",
          isFollowing: false
        ),
      ]
    )
  }
}
