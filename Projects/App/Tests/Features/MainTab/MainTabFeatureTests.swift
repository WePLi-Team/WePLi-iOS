import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-001

@MainActor
final class MainTabFeatureTests: XCTestCase {
  func testInitialTab_isHome() {
    XCTAssertEqual(MainTabFeature.State().selectedTab, .home)
  }

  func testTabSelected_changesSelectedTab() async {
    let store = TestStore(initialState: MainTabFeature.State()) {
      MainTabFeature()
    }

    await store.send(.tabSelected(.relay)) {
      $0.selectedTab = .relay
    }
    await store.send(.tabSelected(.search)) {
      $0.selectedTab = .search
    }
  }

  func testTabs_matchDesignOrder() {
    XCTAssertEqual(MainTabFeature.Tab.allCases, [.home, .relay, .community, .my, .search])
    XCTAssertEqual(MainTabFeature.Tab.capsuleTabs, [.home, .relay, .community, .my])
    XCTAssertEqual(MainTabFeature.Tab.allCases.map(\.title), ["홈", "릴레이", "커뮤니티", "마이", "검색"])
  }
}

// DEC-007 · REQ-030 · REQ-031 · REQ-033 — 릴레이 탭 → 상세 → 투표 → 돌아가기

@MainActor
final class RelayNavigationTests: XCTestCase {
  func testRelayFlow_listToDetailToVoteAndBack() async throws {
    let now = Date(timeIntervalSince1970: 1800000000)
    let detail = RelayDetail.mock(id: "first-love", now: now)
    var initial = MainTabFeature.State()
    initial.selectedTab = .relay
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    } withDependencies: {
      $0.relayDetailClient.fetch = { _ in detail }
    }
    store.exhaustivity = .off

    await store.send(.relay(.relayTapped("first-love")))
    await store.receive(.relay(.delegate(.showRelay("first-love"))))
    XCTAssertEqual(store.state.relayPath.count, 1)
    XCTAssertTrue(store.state.hidesTabBar)

    guard let detailID = store.state.relayPath.ids.first else { return XCTFail("상세가 열리지 않음") }
    await store.send(.relayPath(.element(id: detailID, action: .relayDetail(.detailLoaded(detail)))))
    await store.send(.relayPath(.element(id: detailID, action: .relayDetail(.voteButtonTapped))))
    await store.receive(.relayPath(.element(
      id: detailID,
      action: .relayDetail(.delegate(.showVote(relayID: "first-love")))
    )))
    XCTAssertEqual(store.state.relayPath.count, 2)
    let vote = try store.state.relayPath[id: XCTUnwrap(store.state.relayPath.ids.last), case: \.vote]
    XCTAssertEqual(vote?.topic, "첫 사랑이 생각나는 노래 모음")

    guard let voteID = store.state.relayPath.ids.last else { return XCTFail("투표가 열리지 않음") }
    await store.send(.relayPath(.element(id: voteID, action: .vote(.returnToRelayButtonTapped))))
    await store.receive(.relayPath(.element(id: voteID, action: .vote(.delegate(.dismiss)))))
    XCTAssertEqual(store.state.relayPath.count, 1)

    await store.send(.relayPath(.element(id: detailID, action: .relayDetail(.backButtonTapped))))
    await store.receive(.relayPath(.element(id: detailID, action: .relayDetail(.delegate(.dismiss)))))
    XCTAssertTrue(store.state.relayPath.isEmpty)
    XCTAssertFalse(store.state.hidesTabBar)
  }
}

@MainActor
final class CommunityNavigationTests: XCTestCase {
  func testBell_pushesNotificationsAndBackPops() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .community
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    }
    store.exhaustivity = .off

    await store.send(.community(.notificationButtonTapped))
    await store.receive(.community(.delegate(.showNotifications)))
    XCTAssertEqual(store.state.communityPath.count, 1)
    XCTAssertTrue(store.state.hidesTabBar)

    guard let id = store.state.communityPath.ids.first else { return XCTFail("알림이 열리지 않음") }
    await store.send(.communityPath(.element(id: id, action: .notifications(.backButtonTapped))))
    await store.receive(.communityPath(.element(id: id, action: .notifications(.delegate(.dismiss)))))
    XCTAssertTrue(store.state.communityPath.isEmpty)
  }
}

@MainActor
final class MyNavigationTests: XCTestCase {
  func testProfileCard_pushesEditAndSavedProfileUpdatesMyTab() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .my
    initial.my.profile = .mock
    var updated = MyProfile.mock
    updated.nickname = "새 이름"
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    } withDependencies: {
      $0.editProfileClient.save = { $0 }
    }
    store.exhaustivity = .off

    await store.send(.my(.profileTapped))
    await store.receive(.my(.delegate(.editProfile)))
    guard let id = store.state.myPath.ids.first else { return XCTFail("내 정보 수정이 열리지 않음") }
    XCTAssertTrue(store.state.hidesTabBar)

    await store.send(.myPath(.element(id: id, action: .editProfile(.nicknameChanged("새 이름")))))
    await store.send(.myPath(.element(id: id, action: .editProfile(.doneButtonTapped))))
    await store.receive(.myPath(.element(id: id, action: .editProfile(.delegate(.profileUpdated(updated))))))
    XCTAssertEqual(store.state.my.profile?.nickname, "새 이름")

    await store.send(.myPath(.element(id: id, action: .editProfile(.backButtonTapped))))
    await store.receive(.myPath(.element(id: id, action: .editProfile(.delegate(.dismiss)))))
    XCTAssertTrue(store.state.myPath.isEmpty)
  }

  func testNotificationSettings_pushesAndPops() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .my
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    }
    store.exhaustivity = .off

    await store.send(.my(.menuTapped(.notificationSettings)))
    await store.receive(.my(.delegate(.show(.notificationSettings))))
    guard let id = store.state.myPath.ids.first else { return XCTFail("알림 설정이 열리지 않음") }
    XCTAssertTrue(store.state.hidesTabBar)

    await store.send(.myPath(.element(id: id, action: .notificationSettings(.backButtonTapped))))
    await store.receive(.myPath(.element(id: id, action: .notificationSettings(.delegate(.dismiss)))))
    XCTAssertTrue(store.state.myPath.isEmpty)
  }
}

@MainActor
final class ComposeNavigationTests: XCTestCase {
  func testCompose_opensAsSheetAndPublishingReloadsFeed() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .community
    initial.community.hasLoaded = true
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    } withDependencies: {
      $0.composeClient.publish = { _ in }
      $0.communityClient.fetchFeed = { .mock }
    }
    store.exhaustivity = .off

    await store.send(.community(.composeButtonTapped))
    await store.receive(.community(.delegate(.showCompose)))
    XCTAssertNotNil(store.state.compose)

    await store.send(.compose(.presented(.titleChanged("제목"))))
    await store.send(.compose(.presented(.bodyChanged("내용"))))
    await store.send(.compose(.presented(.publishButtonTapped)))
    await store.receive(.compose(.presented(.delegate(.published))))
    XCTAssertNil(store.state.compose)
    await store.receive(.community(.feedLoaded(.mock)))
    XCTAssertTrue(store.state.community.hasLoaded)
  }
}

@MainActor
final class PostDetailNavigationTests: XCTestCase {
  func testPost_pushesDetailAndSongReplyComesBackFromPicker() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .community
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    } withDependencies: {
      $0.postDetailClient.fetch = { .mock(postID: $0) }
    }
    store.exhaustivity = .off

    await store.send(.community(.postTapped("p3")))
    await store.receive(.community(.delegate(.showPost("p3"))))
    guard let id = store.state.communityPath.ids.first else { return XCTFail("게시글 상세가 열리지 않음") }
    await store.send(.communityPath(.element(id: id, action: .postDetail(.loaded(.mock(postID: "p3"))))))

    await store.send(.communityPath(.element(id: id, action: .postDetail(.songReplyButtonTapped))))
    await store.receive(.communityPath(.element(id: id, action: .postDetail(.delegate(.pickReplySong)))))
    XCTAssertNotNil(store.state.replySongPicker)

    let track = ComposeTrack(id: "c13", title: "밤양갱", artist: "비비(bibi)")
    await store.send(.replySongPicker(.presented(.delegate(.add([track])))))
    XCTAssertNil(store.state.replySongPicker)
    await store.receive(.communityPath(.element(
      id: id,
      action: .postDetail(.replySongPicked(Track(title: "밤양갱", artist: "비비(bibi)")))
    )))
    XCTAssertEqual(store.state.communityPath[id: id, case: \.postDetail]?.replySong?.title, "밤양갱")
  }
}

@MainActor
final class LibraryNavigationTests: XCTestCase {
  func testMyMenus_openLibrarySegmentAndContinueVoting() async {
    let now = Date(timeIntervalSince1970: 1800000000)
    var initial = MainTabFeature.State()
    initial.selectedTab = .my
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    }
    store.exhaustivity = .off

    await store.send(.my(.menuTapped(.likesAndSaves)))
    await store.receive(.my(.delegate(.show(.likesAndSaves))))
    guard let id = store.state.myPath.ids.first else { return XCTFail("보관함이 열리지 않음") }
    XCTAssertEqual(store.state.myPath[id: id, case: \.library]?.segment, .likes)

    await store.send(.myPath(.element(id: id, action: .library(.loaded(.mock(now: now))))))
    await store.send(.myPath(.element(id: id, action: .library(.continueVotingTapped("cafe-bgm")))))
    await store.receive(.myPath(.element(id: id, action: .library(.delegate(.continueVoting(relayID: "cafe-bgm"))))))
    guard let voteID = store.state.myPath.ids.last else { return XCTFail("투표가 열리지 않음") }
    XCTAssertEqual(store.state.myPath[id: voteID, case: \.vote]?.topic, "손님들이 물어보는 카페 BGM")
  }

  func testSettingsMenu_doesNotOpenLibrary() async {
    let store = TestStore(initialState: MainTabFeature.State()) {
      MainTabFeature()
    }
    store.exhaustivity = .off
    await store.send(.my(.menuTapped(.serviceGuide)))
    await store.receive(.my(.delegate(.show(.serviceGuide))))
    XCTAssertTrue(store.state.myPath.isEmpty)
  }
}

@MainActor
final class SongNavigationTests: XCTestCase {
  func testSearchSong_opensDetailThenShareCardThenCompose() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .search
    let song = SongDetail.mock(id: "밤편지|아이유")
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    } withDependencies: {
      $0.date.now = Date(timeIntervalSince1970: 1791991800)
      $0.continuousClock = ImmediateClock()
    }
    store.exhaustivity = .off

    await store.send(.search(.delegate(.showSong("밤편지|아이유"))))
    guard let id = store.state.searchPath.ids.first else { return XCTFail("곡 상세가 열리지 않음") }
    XCTAssertTrue(store.state.hidesTabBar)

    await store.send(.searchPath(.element(id: id, action: .songDetail(.loaded(song)))))
    await store.send(.searchPath(.element(id: id, action: .songDetail(.shareButtonTapped))))
    await store.receive(.searchPath(.element(id: id, action: .songDetail(.delegate(.share(songID: song.id))))))
    XCTAssertEqual(store.state.songShare?.card.title, song.title)
    XCTAssertEqual(store.state.songShare?.card.day, "15")

    await store.send(.songShare(.presented(.shareAsPostTapped)))
    await store.receive(.songShare(.presented(.delegate(.shareAsPost(songID: song.id)))))
    XCTAssertNil(store.state.songShare)
    await store.receive(.presentAfterSheet(.compose(ComposeTrack(id: song.id, title: song.title, artist: song.artist))))
    XCTAssertEqual(store.state.compose?.tracks.map(\.title), [song.title])
  }

  private func menuStore() -> (TestStoreOf<MainTabFeature>, StackElementID, SongDetail) {
    var initial = MainTabFeature.State()
    initial.selectedTab = .search
    let song = SongDetail.mock(id: "밤편지|아이유")
    initial.searchPath.append(.songDetail(SongDetailFeature.State(songID: song.id, song: song)))
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.date.now = Date(timeIntervalSince1970: 1791991800)
      $0.songDetailClient.setLiked = { _, _ in throw URLError(.timedOut) }
    }
    store.exhaustivity = .off
    return (store, initial.searchPath.ids[0], song)
  }

  func testSongMenu_opensFromMoreAndSyncsLikeWithDetail() async {
    let (store, id, song) = self.menuStore()

    await store.send(.searchPath(.element(id: id, action: .songDetail(.moreButtonTapped))))
    await store.receive(.searchPath(.element(id: id, action: .songDetail(.delegate(.more(songID: song.id))))))
    XCTAssertEqual(store.state.songMenu?.title, song.title)

    // 시트에서 좋아요 → 곡 상세가 저장 → 실패하면 둘 다 되돌린다
    await store.send(.songMenu(.presented(.likeButtonTapped)))
    await store.receive(.searchPath(.element(id: id, action: .songDetail(.likeButtonTapped))))
    await store.receive(.searchPath(.element(id: id, action: .songDetail(.likeFailed(restore: song.isLiked)))))
    XCTAssertEqual(store.state.songMenu?.isLiked, song.isLiked)
    XCTAssertEqual(store.state.searchPath[id: id, case: \.songDetail]?.song?.isLiked, song.isLiked)
  }

  func testSongMenu_artistPushesAndInstagramOpensShareCard() async {
    let (store, id, song) = self.menuStore()

    await store.send(.searchPath(.element(id: id, action: .songDetail(.moreButtonTapped))))
    await store.send(.songMenu(.presented(.itemTapped(.artist))))
    await store.receive(.songMenu(.presented(.delegate(.selected(.artist)))))
    XCTAssertNil(store.state.songMenu)
    XCTAssertEqual(store.state.searchPath.count, 2)

    await store.send(.searchPath(.element(id: id, action: .songDetail(.moreButtonTapped))))
    await store.send(.songMenu(.presented(.itemTapped(.instagram))))
    await store.receive(.songMenu(.presented(.delegate(.selected(.instagram)))))
    XCTAssertNil(store.state.songMenu)
    await store.skipReceivedActions()
    XCTAssertEqual(store.state.songShare?.card.title, song.title)
  }

  func testSongDetailArtist_opensArtistThenRelatedArtistAndSong() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .search
    let song = SongDetail.mock(id: "밤편지|아이유")
    initial.searchPath.append(.songDetail(SongDetailFeature.State(songID: song.id, song: song)))
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    }
    store.exhaustivity = .off
    guard let detailID = store.state.searchPath.ids.first else { return XCTFail("경로 없음") }

    await store.send(.searchPath(.element(id: detailID, action: .songDetail(.artistTapped))))
    await store.receive(.searchPath(.element(id: detailID, action: .songDetail(.delegate(.showArtist)))))
    XCTAssertEqual(store.state.searchPath.count, 2)
    guard let artistID = store.state.searchPath.ids.last else { return XCTFail("아티스트가 열리지 않음") }
    XCTAssertEqual(store.state.searchPath[id: artistID, case: \.artist]?.artistID, song.artist)

    await store.send(.searchPath(.element(id: artistID, action: .artist(.relatedArtistTapped("비투비")))))
    await store.receive(.searchPath(.element(id: artistID, action: .artist(.delegate(.showArtist("비투비"))))))
    XCTAssertEqual(store.state.searchPath.count, 3)

    await store.send(.searchPath(.element(id: artistID, action: .artist(.songTapped("밤편지")))))
    await store.receive(.searchPath(.element(id: artistID, action: .artist(.delegate(.showSong("밤편지"))))))
    XCTAssertEqual(store.state.searchPath.count, 4)

    await store.send(.searchPath(.element(id: artistID, action: .artist(.backButtonTapped))))
    await store.receive(.searchPath(.element(id: artistID, action: .artist(.delegate(.dismiss)))))
    XCTAssertEqual(store.state.searchPath.count, 1)
  }

  func testSongDetailBack_pops() async {
    var initial = MainTabFeature.State()
    initial.searchPath.append(.songDetail(SongDetailFeature.State(songID: "s")))
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    }
    store.exhaustivity = .off
    guard let id = store.state.searchPath.ids.first else { return XCTFail("경로 없음") }

    await store.send(.searchPath(.element(id: id, action: .songDetail(.backButtonTapped))))
    await store.receive(.searchPath(.element(id: id, action: .songDetail(.delegate(.dismiss)))))
    XCTAssertTrue(store.state.searchPath.isEmpty)
  }
}

@MainActor
final class BusinessCardNavigationTests: XCTestCase {
  func testBusinessCardButton_presentsFlowAndExitCloses() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .my
    initial.my.profile = MyProfile(nickname: "김동", email: "", persona: .melodyMemories, photoURL: nil)
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    } withDependencies: {
      $0.date.now = Date(timeIntervalSince1970: 1791991800)
    }
    store.exhaustivity = .off

    await store.send(.my(.businessCardButtonTapped))
    await store.receive(.my(.delegate(.showBusinessCard)))
    XCTAssertEqual(store.state.businessCard?.nickname, "김동")
    XCTAssertEqual(store.state.businessCard?.persona, "멜로디 메모리즈")

    await store.send(.businessCard(.presented(.closeTapped)))
    await store.receive(.businessCard(.presented(.delegate(.dismiss))))
    XCTAssertNil(store.state.businessCard)
  }
}

@MainActor
final class SharedPathNavigationTests: XCTestCase {
  func testSearchPlaylist_opensDetailThenTrackAndArtist() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .search
    initial.search.results.lists = [SearchList(title: "비 오는 날", subtitle: "플레이리스트 · WePLi")]
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    }
    store.exhaustivity = .off

    await store.send(.search(.delegate(.showList("비 오는 날"))))
    guard let listID = store.state.searchPath.ids.last else { return XCTFail("플리 상세가 열리지 않음") }
    XCTAssertEqual(store.state.searchPath[id: listID, case: \.playlistDetail]?.playlistID, "비 오는 날")

    await store.send(.searchPath(.element(id: listID, action: .playlistDetail(.delegate(.showTrack("t1"))))))
    XCTAssertEqual(store.state.searchPath.count, 2)
    XCTAssertNotNil(store.state.searchPath[id: store.state.searchPath.ids[1], case: \.songDetail])

    await store.send(.searchPath(.element(id: listID, action: .playlistDetail(.delegate(.showArtist("아이유"))))))
    XCTAssertEqual(store.state.searchPath.count, 3)
  }

  func testSearchRelayAndPost_openMatchingScreens() async {
    var initial = MainTabFeature.State()
    initial.search.results.lists = [
      SearchList(title: "카페 BGM", subtitle: "릴레이리스트 · 3,012명 참여"),
      SearchList(title: "새벽 감성", subtitle: "게시글 · 김동"),
    ]
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    }
    store.exhaustivity = .off

    await store.send(.search(.delegate(.showList("카페 BGM"))))
    await store.send(.search(.delegate(.showList("새벽 감성"))))
    let ids = store.state.searchPath.ids
    XCTAssertNotNil(store.state.searchPath[id: ids[0], case: \.relayDetail])
    XCTAssertNotNil(store.state.searchPath[id: ids[1], case: \.postDetail])
  }

  func testLibrary_opensSongRelayAndPostInMyTab() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .my
    initial.myPath.append(.library(LibraryFeature.State(segment: .likes)))
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    }
    store.exhaustivity = .off
    let libraryID = initial.myPath.ids[0]

    await store.send(.myPath(.element(id: libraryID, action: .library(.delegate(.showSong(title: "밤편지"))))))
    await store.send(.myPath(.element(id: libraryID, action: .library(.delegate(.showRelay("cafe-bgm"))))))
    await store.send(.myPath(.element(id: libraryID, action: .library(.delegate(.showPost("p1"))))))
    let ids = store.state.myPath.ids
    XCTAssertEqual(ids.count, 4)
    XCTAssertEqual(store.state.myPath[id: ids[1], case: \.songDetail]?.songID, "밤편지")
    XCTAssertEqual(store.state.myPath[id: ids[2], case: \.relayDetail]?.relayID, "cafe-bgm")
    XCTAssertEqual(store.state.myPath[id: ids[3], case: \.postDetail]?.postID, "p1")

    // 뒤로는 어느 탭 · 어느 화면이든 그 탭 스택에서 뺀다
    await store.send(.myPath(.element(id: ids[3], action: .postDetail(.delegate(.dismiss)))))
    XCTAssertEqual(store.state.myPath.count, 3)
  }

  func testSongMenu_worksInMyTab() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .my
    let song = SongDetail.mock(id: "밤편지|아이유")
    initial.myPath.append(.songDetail(SongDetailFeature.State(songID: song.id, song: song)))
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    }
    store.exhaustivity = .off
    let id = initial.myPath.ids[0]

    await store.send(.myPath(.element(id: id, action: .songDetail(.moreButtonTapped))))
    await store.receive(.myPath(.element(id: id, action: .songDetail(.delegate(.more(songID: song.id))))))
    XCTAssertEqual(store.state.songMenuSource, PathSource(tab: .my, id: id))

    await store.send(.songMenu(.presented(.itemTapped(.artist))))
    await store.receive(.songMenu(.presented(.delegate(.selected(.artist)))))
    XCTAssertEqual(store.state.myPath.count, 2)
    XCTAssertTrue(store.state.searchPath.isEmpty)
  }
}

extension MainTabFeatureTests {
  func testCompletedPlaylistExport_presentsExportFlowAndCloses() async {
    var initial = MainTabFeature.State()
    var completed = CompletedPlaylistFeature.State(relayID: "summer")
    completed.playlist = .mock(id: "summer")
    initial.homePath.append(.completedPlaylist(completed))
    let store = TestStore(initialState: initial) {
      MainTabFeature()
    }
    store.exhaustivity = .off
    let id = initial.homePath.ids[0]

    await store.send(.homePath(.element(id: id, action: .completedPlaylist(.exportTapped))))
    await store.receive(.homePath(.element(id: id, action: .completedPlaylist(.delegate(.export(relayID: "summer"))))))
    XCTAssertEqual(store.state.exportFlow?.title, "졸릴 때 잠 깨는 청량맛 노동요")
    XCTAssertEqual(store.state.exportFlow?.songs.count, 6)

    await store.send(.exportFlow(.presented(.closeTapped)))
    await store.receive(.exportFlow(.presented(.delegate(.dismiss))))
    XCTAssertNil(store.state.exportFlow)
  }
}
