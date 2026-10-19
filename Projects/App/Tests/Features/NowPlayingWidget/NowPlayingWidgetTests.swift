import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-079 · UI-13e · DEC-015

@MainActor
final class NowPlayingWidgetTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1792079276)

  func testAgo() {
    XCTAssertEqual(NowPlayingWidgetText.ago(self.now, now: self.now), "방금")
    XCTAssertEqual(NowPlayingWidgetText.ago(self.now.addingTimeInterval(-120), now: self.now), "2분 전")
    XCTAssertEqual(NowPlayingWidgetText.ago(self.now.addingTimeInterval(-3 * 3600), now: self.now), "3시간 전")
    XCTAssertEqual(NowPlayingWidgetText.ago(self.now.addingTimeInterval(-2 * 86400), now: self.now), "어제")
  }

  func testSnapshot_firstPlayingFriendNotMe() {
    let snapshot = NowPlayingWidgetSnapshot(.mock, now: self.now)
    XCTAssertEqual(snapshot.person?.name, "지수")
    XCTAssertEqual(snapshot.person?.title, "밤편지")
    XCTAssertEqual(snapshot.group?.listeningCount, 3)
    let data = try? JSONEncoder().encode(snapshot)
    XCTAssertEqual(data.flatMap { try? JSONDecoder().decode(NowPlayingWidgetSnapshot.self, from: $0) }, snapshot)
  }

  func testFriendFeedLoaded_updatesWidget() async {
    let updated = LockIsolated<NowPlayingWidgetSnapshot?>(nil)
    let store = TestStore(initialState: FriendFeedFeature.State()) { FriendFeedFeature() } withDependencies: {
      $0.date.now = self.now
      $0.nowPlayingWidgetClient.update = { updated.setValue($0) }
    }
    await store.send(.loaded(.mock)) { $0.feed = .mock }
    XCTAssertEqual(updated.value, NowPlayingWidgetSnapshot(.mock, now: self.now))
  }
}
