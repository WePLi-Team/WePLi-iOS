import ComposableArchitecture
import Foundation

// REQ-079 · DEC-004 — 지금 위플리 집계. 백엔드가 정해지기 전까지 원본(UI-13f) 예시를 돌려주는 목업이다.
// 10명이 안 되는 곡은 서버가 빼고 보낸다(원본 안내).

struct LiveTrendClient {
  var fetch: @Sendable () async throws -> LiveTrend
  /// 지금 듣는 사람 수 — 2초마다 다시 받는다(원본)
  var listeners: @Sendable () async throws -> Int
}

extension LiveTrendClient: DependencyKey {
  static let liveValue = LiveTrendClient(
    fetch: { .mock },
    // 원본 목업은 127에서 시작해 112–148 사이를 오르내린다
    listeners: { Int.random(in: 112 ... 148) }
  )

  static let previewValue = liveValue

  static let testValue = LiveTrendClient(
    fetch: unimplemented("LiveTrendClient.fetch", placeholder: .mock),
    listeners: unimplemented("LiveTrendClient.listeners", placeholder: 0)
  )
}

extension DependencyValues {
  var liveTrendClient: LiveTrendClient {
    get { self[LiveTrendClient.self] }
    set { self[LiveTrendClient.self] = newValue }
  }
}

extension LiveTrend {
  private static func song(_ title: String, _ artist: String, _ listeners: Int, rising: Bool = false) -> LiveTrendSong {
    LiveTrendSong(id: "\(title)|\(artist)", title: title, artist: artist, listeners: listeners, isRising: rising)
  }

  /// 원본(UI-13f) 예시
  static let mock = LiveTrend(
    listeners: 127,
    hero: song("밤양갱", "비비 (BIBI)", 57),
    rankings: [
      .now: [
        song("Supernova", "aespa", 84),
        song("How Sweet", "NewJeans", 61, rising: true),
        song("첫 만남은 계획대로 되지 않아", "TWS (투어스)", 47),
        song("해야 (HEYA)", "IVE (아이브)", 39),
        song("소나기", "이클립스 (ECLIPSE)", 31, rising: true),
      ],
      .dawn: [
        song("밤편지", "아이유", 42),
        song("그대만 있다면", "너드커넥션", 35),
        song("어른", "Sondia", 28, rising: true),
        song("비의 랩소디", "임재현", 22),
      ],
      .commute: [
        song("Supernova", "aespa", 96),
        song("해야 (HEYA)", "IVE (아이브)", 71),
        song("Love 119", "RIIZE", 54, rising: true),
        song("EASY", "LE SSERAFIM", 40),
      ],
      .lunch: [
        song("How Sweet", "NewJeans", 88),
        song("Hype Boy", "NewJeans", 63),
        song("밤양갱", "비비 (BIBI)", 57),
        song("Small girl (feat. 도경수)", "이영지", 44, rising: true),
      ],
      .night: [
        song("그대만 있다면", "너드커넥션", 73),
        song("밤편지", "아이유", 69),
        song("소나기", "이클립스 (ECLIPSE)", 51),
        song("어른", "Sondia", 38),
      ],
    ]
  )
}
