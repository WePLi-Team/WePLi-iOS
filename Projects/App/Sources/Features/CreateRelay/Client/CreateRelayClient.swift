import ComposableArchitecture
import Foundation

// REQ-036 · DEC-004 — 마감 시각은 서버가 정한다. 백엔드가 정해지기 전까지 목업이다.

struct CreateRelayClient {
  var create: @Sendable (_ relay: NewRelay) async throws -> Relay
}

extension CreateRelayClient: DependencyKey {
  static let liveValue = CreateRelayClient(
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

  static let previewValue = liveValue

  static let testValue = CreateRelayClient(
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

extension DependencyValues {
  var createRelayClient: CreateRelayClient {
    get { self[CreateRelayClient.self] }
    set { self[CreateRelayClient.self] = newValue }
  }
}
