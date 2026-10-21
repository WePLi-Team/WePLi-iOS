import ComposableArchitecture
@testable import WePLi
import XCTest

// REQ-079 · UI-13g · UI-17d · DEC-020 · DEC-023 · DEC-029

private let reportRecord = FriendReport(
  date: Date(timeIntervalSince1970: 1792400000),
  reason: .abuse,
  status: .reviewing
)

@MainActor
final class FriendProfileFeatureTests: XCTestCase {
  private struct Failure: Error {}

  private func loaded() -> FriendProfileFeature.State {
    var state = FriendProfileFeature.State(userID: "jisoo")
    state.profile = .mock(id: "jisoo")
    return state
  }

  func testTasteMatch_onlyWhenMutualFollow() {
    var profile = FriendProfile.mock(id: "jisoo")
    XCTAssertEqual(profile.visibleTasteMatch, 82)
    profile.isFollowing = false
    XCTAssertNil(profile.visibleTasteMatch)
  }

  func testLoad() async {
    let store = TestStore(initialState: FriendProfileFeature.State(userID: "jisoo")) {
      FriendProfileFeature()
    } withDependencies: {
      $0.friendProfileClient.fetch = { .mock(id: $0) }
    }
    await store.send(.onAppear)
    await store.receive(.loaded(.mock(id: "jisoo"))) { $0.profile = .mock(id: "jisoo") }
  }

  func testFollow_rollsBackOnFailure() async {
    let store = TestStore(initialState: self.loaded()) { FriendProfileFeature() } withDependencies: {
      $0.friendProfileClient.setFollowing = { _, _ in throw Failure() }
    }
    await store.send(.followTapped) {
      $0.profile?.isFollowing = false
      $0.profile?.followerCount = 127
    }
    await store.receive(.rollback(.follow(isFollowing: true, followerCount: 128))) {
      $0.profile?.isFollowing = true
      $0.profile?.followerCount = 128
      $0.toast = FriendProfileText.failed
    }
  }

  func testBlock_confirmThenUnblock() async {
    let calls = LockIsolated<[Bool]>([])
    let store = TestStore(initialState: self.loaded()) { FriendProfileFeature() } withDependencies: {
      $0.friendProfileClient.setBlocked = { _, isOn in calls.withValue { $0.append(isOn) } }
    }
    await store.send(.menu(.moreTapped)) { $0.overlay = .menu }
    await store.send(.menu(.blockTapped)) { $0.overlay = .blockConfirm }
    // 메뉴 시트가 닫혀도 확인 창은 남는다
    await store.send(.menu(.dismissed))
    await store.send(.menu(.blockConfirmed)) {
      $0.overlay = nil
      $0.isBlocked = true
      $0.profile?.isFollowing = false
      $0.profile?.followerCount = 127
      $0.toast = FriendProfileText.blocked
    }
    await store.send(.menu(.unblockTapped)) {
      $0.isBlocked = false
      $0.toast = FriendProfileText.unblocked
    }
    // 풀어도 팔로우는 다시 해야 한다
    XCTAssertEqual(store.state.profile?.isFollowing, false)
    XCTAssertEqual(calls.value, [true, false])
  }

  func testReport_needsReasonThenShowsDoneSheet() async {
    let sent = LockIsolated<[ReportReason]>([])
    let store = TestStore(initialState: self.loaded()) { FriendProfileFeature() } withDependencies: {
      $0.friendProfileClient.report = { _, value, detail in
        XCTAssertNil(detail)
        sent.withValue { $0.append(value) }
        return reportRecord
      }
    }
    await store.send(.menu(.reportTapped)) { $0.overlay = .report }
    // 사유를 고르기 전에는 보내지 않는다
    await store.send(.menu(.reportSubmitted))
    await store.send(.menu(.reasonSelected(.spam))) { $0.reportReason = .spam }
    await store.send(.menu(.reasonSelected(.impersonation))) { $0.reportReason = .impersonation }
    // 보내는 동안 시트는 그대로 — 끌어내려도 닫히지 않는다
    await store.send(.menu(.reportSubmitted)) { $0.isReporting = true }
    await store.receive(.menu(.reported(reportRecord))) {
      $0.isReporting = false
      $0.reportReason = nil
      $0.profile?.myReport = reportRecord
      $0.overlay = .reportDone
    }
    // 접수 안내에서 바로 차단 확인 창으로
    await store.send(.menu(.reportBlockTapped)) { $0.overlay = .blockConfirm }
    XCTAssertEqual(sent.value, [.impersonation])
  }

  func testReport_otherNeedsDetailUpTo200() async {
    let detail = LockIsolated<String?>(nil)
    let store = TestStore(initialState: self.loaded()) { FriendProfileFeature() } withDependencies: {
      $0.friendProfileClient.report = { _, _, text in
        detail.setValue(text)
        return reportRecord
      }
    }
    await store.send(.menu(.reportTapped)) { $0.overlay = .report }
    await store.send(.menu(.reasonSelected(.other))) { $0.reportReason = .other }
    XCTAssertFalse(store.state.canSubmitReport)
    // 빈칸만 적으면 아직 보낼 수 없다
    await store.send(.menu(.reportDetailChanged("   "))) { $0.reportDetail = "   " }
    XCTAssertFalse(store.state.canSubmitReport)
    await store.send(.menu(.reportSubmitted))
    let long = String(repeating: "가", count: 205)
    await store.send(.menu(.reportDetailChanged(long))) { $0.reportDetail = String(repeating: "가", count: 200) }
    await store.send(.menu(.reportDetailChanged(" 프로필 사진 도용 "))) { $0.reportDetail = " 프로필 사진 도용 " }
    XCTAssertTrue(store.state.canSubmitReport)
    await store.send(.menu(.reportSubmitted)) { $0.isReporting = true }
    await store.receive(.menu(.reported(reportRecord))) {
      $0.isReporting = false
      $0.reportReason = nil
      $0.reportDetail = ""
      $0.profile?.myReport = reportRecord
      $0.overlay = .reportDone
    }
    XCTAssertEqual(detail.value, "프로필 사진 도용")
  }

  func testReport_againShowsExistingRecordAndOpensHistory() async {
    var state = self.loaded()
    state.profile?.myReport = reportRecord
    let store = TestStore(initialState: state) { FriendProfileFeature() }
    // 같은 사람은 한 번만 — 신고 시트 대신 기록을 보인다
    await store.send(.menu(.reportTapped)) { $0.overlay = .reportExisting }
    await store.send(.menu(.reportHistoryTapped)) { $0.overlay = nil }
    await store.receive(.delegate(.showInquiryHistory))
  }

  func testReport_failureClosesSheetAndAlerts() async {
    let store = TestStore(initialState: self.loaded()) { FriendProfileFeature() } withDependencies: {
      $0.friendProfileClient.report = { _, _, _ in throw Failure() }
    }
    await store.send(.menu(.reportTapped)) { $0.overlay = .report }
    await store.send(.menu(.reasonSelected(.abuse))) { $0.reportReason = .abuse }
    await store.send(.menu(.reportSubmitted)) { $0.isReporting = true }
    await store.receive(.rollback(.report)) {
      $0.isReporting = false
      $0.overlay = nil
      $0.toast = FriendProfileText.failed
    }
  }

  func testReportDate_seoul() {
    // 2026-10-19 15:00 UTC = 10월 20일 0시(서울)
    XCTAssertEqual(FriendProfileText.reportDate(Date(timeIntervalSince1970: 1792422000)), "10월 20일")
  }

  func testInquiryHistory_opensInquiryList() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .community
    let store = TestStore(initialState: initial) { MainTabFeature() }
    store.exhaustivity = .off
    await store.send(.community(.authorTapped("jisoo")))
    await store.receive(.community(.delegate(.showProfile("jisoo"))))
    guard let id = store.state.communityPath.ids.last else { return XCTFail("프로필이 없어요") }
    await store.send(.communityPath(.element(id: id, action: .friendProfile(.delegate(.showInquiryHistory)))))
    guard case .inquiryHistory? = store.state.communityPath.last else {
      return XCTFail("내 문의 내역이 열리지 않았어요")
    }
  }

  func testPostLike_andInviteOnce() async {
    let store = TestStore(initialState: self.loaded()) { FriendProfileFeature() } withDependencies: {
      $0.friendProfileClient.likePost = { _, _ in }
      $0.friendProfileClient.invite = { _, _ in }
    }
    await store.send(.postLikeTapped("jisu-1")) {
      $0.profile?.posts[id: "jisu-1"]?.isLiked = true
      $0.profile?.posts[id: "jisu-1"]?.likeCount = 43
    }
    await store.send(.inviteTapped) { $0.isInviteSent = true }
    await store.send(.inviteTapped)
  }

  func testNowPlayingMenu_playsAndOpensScreens() async {
    let store = TestStore(initialState: self.loaded()) { FriendProfileFeature() }
    await store.send(.nowPlayingTapped) { $0.isNowPlayingMenuOpen = true }
    await store.send(.playNowPlayingTapped) { $0.isNowPlayingMenuOpen = false }
    await store.receive(.delegate(.play(PlayerTrack(id: "밤편지|아이유", title: "밤편지", artist: "아이유"))))
    await store.send(.tasteMatchTapped)
    await store.receive(.delegate(.showTasteMatch(userID: "jisoo")))
    await store.send(.relayTapped("first-love"))
    await store.receive(.delegate(.showRelay("first-love")))
  }
}

extension MainTabFeatureTests {
  func testCommunityAuthor_opensFriendProfile() async {
    var initial = MainTabFeature.State()
    initial.selectedTab = .community
    let store = TestStore(initialState: initial) { MainTabFeature() }
    store.exhaustivity = .off
    await store.send(.community(.authorTapped("jisoo")))
    await store.receive(.community(.delegate(.showProfile("jisoo"))))
    XCTAssertEqual(store.state.communityPath.count, 1)
    guard case let .friendProfile(profile)? = store.state.communityPath.last else {
      return XCTFail("친구 프로필이 열리지 않았어요")
    }
    XCTAssertEqual(profile.userID, "jisoo")
  }
}
