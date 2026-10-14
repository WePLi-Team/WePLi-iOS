import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-036 · UI-6a · DEC-004

@MainActor
final class CreateRelayFeatureTests: XCTestCase {
  private let song = ComposeTrack(id: "1", title: "밤편지", artist: "아이유 (IU)")

  func testDefaults_andLimits() async {
    let store = TestStore(initialState: CreateRelayFeature.State()) {
      CreateRelayFeature()
    }
    XCTAssertEqual(store.state.relay.duration, .threeDays)
    XCTAssertEqual(store.state.relay.voteFormat, .card)
    XCTAssertEqual(store.state.relay.audience, .everyone)
    XCTAssertEqual(RelayDuration.sevenDays.countdownText, "완성까지 7일 0시간 0분 0초")

    let long = String(repeating: "가", count: 40)
    await store.send(.topicChanged(long)) { $0.relay.topic = String(repeating: "가", count: 30) }
    await store.send(.descriptionChanged(long + long)) { $0.relay.description = String(repeating: "가", count: 60) }
  }

  func testCreate_needsTopicAndFirstSong() async {
    let store = TestStore(initialState: CreateRelayFeature.State()) {
      CreateRelayFeature()
    }

    await store.send(.topicChanged("   ")) { $0.relay.topic = "   " }
    XCTAssertFalse(store.state.canCreate)
    await store.send(.createTapped)
    await store.send(.topicChanged("비 오는 날")) { $0.relay.topic = "비 오는 날" }
    XCTAssertFalse(store.state.canCreate)
    await store.send(.firstSongTapped) { $0.picker = SongPickerFeature.State() }
    await store.send(.picker(.presented(.delegate(.add([self.song]))))) {
      $0.picker = nil
      $0.relay.firstSong = self.song
    }
    XCTAssertTrue(store.state.canCreate)
  }

  func testCreate_successDelegates_failureShowsToast() async {
    var initial = CreateRelayFeature.State()
    initial.relay.topic = "비 오는 날"
    initial.relay.firstSong = self.song
    let relay = Relay(
      id: "new",
      title: "비 오는 날",
      voteFormat: .card,
      participantCount: 1,
      status: .live(endsAt: Date(timeIntervalSince1970: 0)),
      isMine: true
    )
    let calls = LockIsolated(0)
    let store = TestStore(initialState: initial) {
      CreateRelayFeature()
    } withDependencies: {
      $0.createRelayClient.create = { _ in
        calls.withValue { $0 += 1 }
        if calls.value == 1 {
          throw URLError(.timedOut)
        }
        return relay
      }
    }

    await store.send(.createTapped) { $0.isCreating = true }
    await store.receive(.createFailed) {
      $0.isCreating = false
      $0.toast = "릴레이리스트를 만들지 못했어요. 다시 시도해 주세요"
    }
    await store.send(.createTapped) { $0.isCreating = true }
    await store.receive(.created(relay)) { $0.isCreating = false }
    await store.receive(.delegate(.created(relay)))
  }

  func testLiveClient_setsEndDateFromDuration() async throws {
    let now = Date(timeIntervalSince1970: 1791991800)
    var relay = NewRelay()
    relay.topic = "  카페 BGM "
    relay.duration = .sevenDays
    relay.voteFormat = .worldCup
    let created = try await withDependencies {
      $0.date.now = now
      $0.uuid = .incrementing
    } operation: {
      try await CreateRelayClient.liveValue.create(relay)
    }
    XCTAssertEqual(created.title, "카페 BGM")
    XCTAssertEqual(created.voteFormat, .worldCup)
    XCTAssertEqual(created.endsAt, now.addingTimeInterval(7 * 86400))
    XCTAssertTrue(created.isMine)
  }
}

@MainActor
final class CreateRelayNavigationTests: XCTestCase {
  func testOpenRelay_presentsSheetAndCreatedRelayAppearsInList() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .relay
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    }
    store.exhaustivity = .off
    let relay = Relay(
      id: "new",
      title: "비 오는 날",
      voteFormat: .card,
      participantCount: 1,
      status: .live(endsAt: Date(timeIntervalSince1970: 0)),
      isMine: true
    )

    await store.send(.relay(.openRelayButtonTapped))
    await store.receive(.relay(.delegate(.showCreateRelay)))
    XCTAssertNotNil(store.state.createRelay)

    await store.send(.createRelay(.presented(.delegate(.created(relay)))))
    XCTAssertNil(store.state.createRelay)
    XCTAssertEqual(store.state.relay.relays.first?.id, "new")
  }
}
