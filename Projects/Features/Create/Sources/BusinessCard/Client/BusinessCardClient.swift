import ComposableArchitecture
import Foundation

// REQ-075 · DEC-004 — 명함 저장 · 공유 링크. 백엔드가 정해지기 전까지 목업이다.

public struct BusinessCardClient {
  /// 저장하고 명함 id를 돌려준다
  public var create: @Sendable (_ card: BusinessCard) async throws -> String
  public var link: @Sendable (_ cardID: String) async throws -> URL

  public init(
    create: @escaping @Sendable (_ card: BusinessCard) async throws -> String,
    link: @escaping @Sendable (_ cardID: String) async throws -> URL
  ) {
    self.create = create
    self.link = link
  }
}

extension BusinessCardClient: DependencyKey {
  /// 미결정 — 공유 링크 웹 미리보기(11차 남은 후보). 정해지기 전까지 예약 도메인을 쓴다.
  public static let linkBase = URL(string: "https://wepli.example/cards")

  public static let mockValue = BusinessCardClient(
    create: { _ in "me" },
    link: { cardID in
      guard let url = linkBase?.appendingPathComponent(cardID) else { throw URLError(.badURL) }
      return url
    }
  )

  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  public static let liveValue = mockValue
  public static let previewValue = mockValue

  public static let testValue = BusinessCardClient(
    create: unimplemented("BusinessCardClient.create", placeholder: ""),
    link: unimplemented("BusinessCardClient.link", placeholder: URL(fileURLWithPath: "/"))
  )
}

public extension DependencyValues {
  var businessCardClient: BusinessCardClient {
    get { self[BusinessCardClient.self] }
    set { self[BusinessCardClient.self] = newValue }
  }
}
