import ComposableArchitecture
import Foundation

// REQ-075 · DEC-004 — 명함 저장 · 공유 링크. 백엔드가 정해지기 전까지 목업이다.

struct BusinessCardClient {
  /// 저장하고 명함 id를 돌려준다
  var create: @Sendable (_ card: BusinessCard) async throws -> String
  var link: @Sendable (_ cardID: String) async throws -> URL
}

extension BusinessCardClient: DependencyKey {
  /// 미결정 — 공유 링크 웹 미리보기(11차 남은 후보). 정해지기 전까지 예약 도메인을 쓴다.
  static let linkBase = URL(string: "https://wepli.example/cards")

  static let liveValue = BusinessCardClient(
    create: { _ in "me" },
    link: { cardID in
      guard let url = linkBase?.appendingPathComponent(cardID) else { throw URLError(.badURL) }
      return url
    }
  )

  static let previewValue = liveValue

  static let testValue = BusinessCardClient(
    create: unimplemented("BusinessCardClient.create", placeholder: ""),
    link: unimplemented("BusinessCardClient.link", placeholder: URL(fileURLWithPath: "/"))
  )
}

extension DependencyValues {
  var businessCardClient: BusinessCardClient {
    get { self[BusinessCardClient.self] }
    set { self[BusinessCardClient.self] = newValue }
  }
}
