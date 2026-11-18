import ComposableArchitecture
import Foundation
import WePLiSharedModels

// REQ-036 · DEC-004 — 마감 시각은 서버가 정한다. 백엔드가 정해지기 전까지 목업이다.

public struct CreateRelayClient {
  public var create: @Sendable (_ relay: NewRelay) async throws -> Relay

  public init(create: @escaping @Sendable (_ relay: NewRelay) async throws -> Relay) {
    self.create = create
  }
}

extension CreateRelayClient: DependencyKey {
  public static let mockValue = CreateRelayClient(
    create: { relay in
      @Dependency(\.date.now)
      var now
      @Dependency(\.uuid)
      var uuid
      return Relay(
        id: uuid().uuidString,
        title: relay.trimmedTopic,
        voteFormat: relay.voteFormat.relayFormat,
        participantCount: 1,
        status: .live(endsAt: now.addingTimeInterval(TimeInterval(relay.duration.rawValue) * 86400)),
        isMine: true
      )
    }
  )

  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  public static let liveValue = mockValue
  public static let previewValue = mockValue

  public static let testValue = CreateRelayClient(
    create: unimplemented("CreateRelayClient.create", placeholder: Relay(
      id: "",
      title: "",
      voteFormat: .card,
      participantCount: 0,
      status: .completed,
      isMine: true
    ))
  )
}

public extension DependencyValues {
  var createRelayClient: CreateRelayClient {
    get { self[CreateRelayClient.self] }
    set { self[CreateRelayClient.self] = newValue }
  }
}
