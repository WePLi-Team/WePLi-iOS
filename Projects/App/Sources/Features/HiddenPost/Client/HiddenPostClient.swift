import ComposableArchitecture
import Foundation

// UI-17c — 가려진 내 글 삭제는 서버가 한다. 백엔드가 정해지기 전까지 목업이다.

struct HiddenPostClient {
  var delete: @Sendable (_ postID: HiddenPost.ID) async throws -> Void
}

extension HiddenPostClient: DependencyKey {
  static let liveValue = HiddenPostClient(delete: { _ in })
  static let previewValue = liveValue
  static let testValue = HiddenPostClient(delete: unimplemented("HiddenPostClient.delete"))
}

extension DependencyValues {
  var hiddenPostClient: HiddenPostClient {
    get { self[HiddenPostClient.self] }
    set { self[HiddenPostClient.self] = newValue }
  }
}

extension HiddenPost {
  /// 원본(UI-17c) 예시 — 2026-10-19 14:02 KST에 가려짐
  static let mock = HiddenPost(
    id: "hidden-1",
    author: "김동",
    title: "비 오는 날 듣는 플리",
    body: "창문에 빗소리 들리면 무조건 이거 틀어요. 진짜 이 감성 모르는 사람들 불쌍함ㅋㅋ 추천 곡 댓글로 달아줘요",
    song: Track(title: "비의 랩소디", artist: "임재현"),
    postedAt: Date(timeIntervalSince1970: 1792378800),
    hiddenAt: Date(timeIntervalSince1970: 1792386120),
    reason: "욕설 · 비하 표현 신고 누적"
  )
}
