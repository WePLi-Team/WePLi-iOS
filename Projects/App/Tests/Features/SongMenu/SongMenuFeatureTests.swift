import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-023 · UI-1b 곡 메뉴 시트

@MainActor
final class SongMenuFeatureTests: XCTestCase {
  private let initial = SongMenuFeature.State(songID: "s1", title: "밤편지", artist: "아이유", isLiked: false)

  func testGroups_matchDesignOrder() {
    XCTAssertEqual(SongMenuItem.groups.map(\.count), [3, 4, 1])
    XCTAssertEqual(SongMenuItem.groups.flatMap(\.self).map(\.title), [
      "아티스트 정보 보기", "가사 보기", "내 플레이리스트에 추가하기",
      "게시글로 공유하기", "인스타그램으로 공유하기", "링크로 공유하기", "스크린샷으로 저장",
      "곡 정보",
    ])
  }

  func testLike_togglesAndAsksParent() async {
    let store = TestStore(initialState: self.initial) {
      SongMenuFeature()
    }

    await store.send(.likeButtonTapped) { $0.isLiked = true }
    await store.receive(.delegate(.toggleLike))
  }

  func testLink_copiesAndShowsToast() async {
    let copied = LockIsolated<URL?>(nil)
    let url = URL(string: "https://wepli.example/songs/s1")
    let store = TestStore(initialState: self.initial) {
      SongMenuFeature()
    } withDependencies: {
      $0.songShareClient.link = { _ in try XCTUnwrap(url) }
      $0.songShareClient.copy = { copied.setValue($0) }
    }

    await store.send(.itemTapped(.link))
    await store.receive(.linkCopied) { $0.toast = "링크를 복사했어요" }
    XCTAssertEqual(copied.value, url)
  }

  func testOtherItems_delegate() async {
    let store = TestStore(initialState: self.initial) {
      SongMenuFeature()
    }

    await store.send(.itemTapped(.artist))
    await store.receive(.delegate(.selected(.artist)))
    await store.send(.closeButtonTapped)
    await store.receive(.delegate(.dismiss))
  }
}
