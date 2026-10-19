import ComposableArchitecture
import Foundation

// REQ-102 · DEC-004 · DEC-023 — 백엔드가 정해지기 전까지 원본(UI-6d) 예시를 돌려주는 목업이다.

struct TasteMatchClient {
  var fetch: @Sendable (_ userID: String) async throws -> TasteMatch
  /// 추천 보내기 — 미결정: 받는 사람에게 어떻게 보이는지(알림 · 위치)
  var recommend: @Sendable (_ userID: String, _ songID: TasteMatchSong.ID) async throws -> Void
}

extension TasteMatchClient: DependencyKey {
  static let liveValue = TasteMatchClient(
    fetch: { userID in .mock(userID: userID) },
    recommend: { _, _ in }
  )

  static let previewValue = liveValue

  static let testValue = TasteMatchClient(
    fetch: unimplemented("TasteMatchClient.fetch", placeholder: .mock(userID: "")),
    recommend: unimplemented("TasteMatchClient.recommend")
  )
}

extension DependencyValues {
  var tasteMatchClient: TasteMatchClient {
    get { self[TasteMatchClient.self] }
    set { self[TasteMatchClient.self] = newValue }
  }
}

extension TasteMatch {
  /// 원본(UI-6d) 예시
  static func mock(userID: String) -> TasteMatch {
    TasteMatch(
      userID: userID,
      score: 82,
      sharedPersona: "센티멘탈 심포니",
      artists: ["아이유", "윤하", "츄(CHUU)"],
      recommendations: [
        TasteMatchSong(title: "밤편지", artist: "아이유 (IU)"),
        TasteMatchSong(title: "너의 바다", artist: "호피폴라"),
      ]
    )
  }
}
