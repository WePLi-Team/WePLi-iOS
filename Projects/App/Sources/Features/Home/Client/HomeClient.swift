import ComposableArchitecture
import Foundation

// REQ-020 · DEC-004 — 홈 내용은 서버가 정한다. 백엔드가 정해지기 전까지 원본(UI-12a) 예시를 돌려주는 목업이다.

struct HomeClient {
  var fetch: @Sendable () async throws -> HomeFeed
}

extension HomeClient: DependencyKey {
  static let liveValue = HomeClient(
    fetch: {
      @Dependency(\.date.now)
      var now
      return .mock(now: now)
    }
  )

  static let previewValue = liveValue

  static let testValue = HomeClient(
    fetch: unimplemented("HomeClient.fetch", placeholder: .mock(now: Date(timeIntervalSince1970: 0)))
  )
}

extension DependencyValues {
  var homeClient: HomeClient {
    get { self[HomeClient.self] }
    set { self[HomeClient.self] = newValue }
  }
}

extension HomeFeed {
  /// 원본 예시 — 히어로 마감은 지금부터 187,953초 · 33,410초 뒤
  static func mock(now: Date) -> HomeFeed {
    HomeFeed(
      heroes: [
        HomeHero(
          id: "cafe-bgm",
          title: "손님들이 물어보는\n카페 BGM",
          people: "3,012명 참여",
          rankLabel: "지금 1위",
          song: "Radical Optimism",
          songMeta: "Dua Lipa · Album",
          status: .live(endsAt: now.addingTimeInterval(187953))
        ),
        HomeHero(
          id: "rainy-night",
          title: "비 오는 밤\n이어달리기",
          people: "바통 릴레이 · 8명 중 4번째",
          rankLabel: "방금 이어진 곡",
          song: "비의 랩소디",
          songMeta: "임재현",
          status: .live(endsAt: now.addingTimeInterval(33410))
        ),
        HomeHero(
          id: "wake-up",
          title: "졸릴 때 잠 깨는\n청량맛 노동요",
          people: "248명이 추천한 12곡",
          rankLabel: "최종 1위",
          song: "Supernova",
          songMeta: "aespa",
          status: .completed
        ),
      ],
      chartUpdatedText: "6월 23일 오전 7시 업데이트",
      chart: [
        HomeChartSong(id: "supernova", title: "Supernova", artist: "aespa"),
        HomeChartSong(id: "how-sweet", title: "How Sweet", artist: "NewJeans"),
        HomeChartSong(id: "heya", title: "해야 (HEYA)", artist: "IVE (아이브)"),
        HomeChartSong(id: "bam", title: "밤양갱", artist: "비비 (BIBI)"),
        HomeChartSong(id: "first", title: "첫 만남은 계획대로 되지 않아", artist: "TWS (투어스)"),
      ],
      banners: [
        HomeBanner(id: "chart", eyebrow: "오직 위플리에서만", title: "실시간 통합 순위를 한 눈에!"),
        HomeBanner(id: "instagram", eyebrow: "위플리 인스타그램 OPEN!", title: "감성 가득한 일상 보러가기"),
      ],
      unreadNotifications: 4
    )
  }
}
