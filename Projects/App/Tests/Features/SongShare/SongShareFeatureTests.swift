import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-066 · UI-3g · DEC-004

@MainActor
final class SongShareFeatureTests: XCTestCase {
  // 2026-10-14 15:30 UTC = 2026-10-15 00:30 KST
  private let now = Date(timeIntervalSince1970: 1791991800)
  private let link = URL(string: "https://wepli.example/songs/s1")

  private func state() -> SongShareFeature.State {
    SongShareFeature.State(card: SongShareCard(
      songID: "s1",
      title: "소년, 길을 걷다",
      artist: "이승기",
      sharerName: "김동",
      sharerPersona: "멜로디 메모리즈",
      today: self.now
    ))
  }

  func testCardDate_isTodayInSeoul() {
    let card = self.state().card
    XCTAssertEqual(card.day, "15")
    XCTAssertEqual(card.month, "OCT")
    XCTAssertEqual(card.subtitle, "소년, 길을 걷다 · 이승기")
    XCTAssertEqual(ShareCardDate(Date(timeIntervalSince1970: 1767225600)).month, "JAN")
  }

  func testOnAppear_loadsSharerWhenMissing() async {
    var initial = self.state()
    initial.card.sharerName = nil
    initial.card.sharerPersona = nil
    let profile = MyProfile(nickname: "위플리", email: "", persona: .melodyMemories, photoURL: nil)
    let store = TestStore(initialState: initial) {
      SongShareFeature()
    } withDependencies: {
      $0.myClient.fetchProfile = { profile }
    }

    await store.send(.onAppear)
    await store.receive(.sharerLoaded(profile)) {
      $0.card.sharerName = "위플리"
      $0.card.sharerPersona = "멜로디 메모리즈"
    }
  }

  func testCopyLink_copiesAndShowsToast() async {
    let copied = LockIsolated<URL?>(nil)
    let link = self.link
    let store = TestStore(initialState: self.state()) {
      SongShareFeature()
    } withDependencies: {
      $0.songShareClient.link = { _ in try XCTUnwrap(link) }
      $0.songShareClient.copy = { url in copied.setValue(url) }
    }

    await store.send(.copyLinkTapped)
    await store.receive(.linkCopied) { $0.toast = "링크를 복사했어요" }
    XCTAssertEqual(copied.value, link)
  }

  func testSaveImage_deniedShowsGuide() async {
    let store = TestStore(initialState: self.state()) {
      SongShareFeature()
    } withDependencies: {
      $0.songShareClient.saveImage = { _ in throw SongShareError.photoAccessDenied }
    }

    await store.send(.saveImageTapped(image: Data([1])))
    await store.receive(.imageSaveFailed(.photoAccessDenied)) {
      $0.toast = "사진 접근을 허용하면 저장할 수 있어요"
    }
  }

  func testSaveImage_success() async {
    let store = TestStore(initialState: self.state()) {
      SongShareFeature()
    } withDependencies: {
      $0.songShareClient.saveImage = { _ in }
    }

    await store.send(.saveImageTapped(image: Data([1])))
    await store.receive(.imageSaved) { $0.toast = "이미지를 저장했어요" }
  }

  func testMore_presentsSystemShareWithLink() async {
    let link = self.link
    let store = TestStore(initialState: self.state()) {
      SongShareFeature()
    } withDependencies: {
      $0.songShareClient.link = { _ in try XCTUnwrap(link) }
    }

    await store.send(.moreTapped(image: Data([1])))
    await store.receive(.systemShareReady(image: Data([1]), link: link)) {
      $0.shareCount = 1
      $0.systemShare = SystemShareItem(id: 1, image: Data([1]), link: link)
    }
    await store.send(.systemShareDismissed) { $0.systemShare = nil }
  }

  func testInAppActions_delegate() async {
    let store = TestStore(initialState: self.state()) {
      SongShareFeature()
    }

    await store.send(.shareAsPostTapped)
    await store.receive(.delegate(.shareAsPost(songID: "s1")))
    await store.send(.addToPlaylistTapped)
    await store.receive(.delegate(.addToPlaylist(songID: "s1")))
    await store.send(.closeButtonTapped)
    await store.receive(.delegate(.dismiss))
  }
}
