import ComposableArchitecture
import Foundation

// UI-13g — 화면 안 동작 · 팔로우 · 초대 · 좋아요 · ··· 메뉴(차단 · 신고)

extension FriendProfileFeature {
  /// 화면 안에서만 바뀌는 것 — 탭 · 토스트 · 지금 듣는 중 메뉴
  func local(_ action: Action, _ state: inout State) -> Effect<Action>? {
    switch action {
    case let .tabSelected(tab):
      state.tab = tab
    case .toastDismissed:
      state.toast = nil
    case .nowPlayingTapped:
      state.isNowPlayingMenuOpen = state.profile?.nowPlaying != nil
    case .nowPlayingMenuDismissed:
      state.isNowPlayingMenuOpen = false
    case .playNowPlayingTapped:
      state.isNowPlayingMenuOpen = false
      guard let song = state.profile?.nowPlaying else { return .none }
      let track = PlayerTrack(id: "\(song.title)|\(song.artist)", title: song.title, artist: song.artist)
      return .send(.delegate(.play(track)))
    default:
      return nil
    }
    return .none
  }

  /// 서버에 남는 것 — 먼저 반영하고 실패하면 되돌린다
  func social(_ action: Action, _ state: inout State) -> Effect<Action>? {
    guard let profile = state.profile else { return nil }
    let userID = profile.id
    switch action {
    case .followTapped:
      let isOn = !profile.isFollowing
      state.profile?.isFollowing = isOn
      state.profile?.followerCount += isOn ? 1 : -1
      let rollback = FriendProfileRollback.follow(
        isFollowing: profile.isFollowing,
        followerCount: profile.followerCount
      )
      return self.send(rollback) { try await self.client.setFollowing(userID, isOn) }
    case .saveSongTapped:
      guard !state.isSongSaved, let song = profile.nowPlaying else { return .none }
      state.isSongSaved = true
      return self.send(.saveSong) { try await self.client.saveSong(song.title, song.artist) }
    case .inviteTapped:
      // 미결정 — 원본은 다시 누르면 취소되지만 보낸 초대는 되돌리지 않는다
      guard !state.isInviteSent, let relay = profile.inviteRelay else { return .none }
      state.isInviteSent = true
      return self.send(.invite) { try await self.client.invite(userID, relay.id) }
    case let .postLikeTapped(id):
      guard let post = profile.posts.first(where: { $0.id == id }) else { return .none }
      let isOn = !post.isLiked
      state.profile?.posts[id: id]?.isLiked = isOn
      state.profile?.posts[id: id]?.likeCount += isOn ? 1 : -1
      return self.send(.postLike(post)) { try await self.client.likePost(id, isOn) }
    default:
      return nil
    }
  }

  func menu(_ action: FriendProfileMenuAction, _ state: inout State) -> Effect<Action> {
    switch action {
    case .moreTapped:
      state.isNowPlayingMenuOpen = false
      state.overlay = .menu
    case .copyLinkTapped:
      state.overlay = nil
      guard let profile = state.profile, let url = FriendProfileText.link(profile) else { return .none }
      state.toast = FriendProfileText.linkCopied
      return .run { _ in await self.client.copyLink(url) }
    case .blockConfirmed, .unblockTapped:
      return self.block(isOn: action == .blockConfirmed, &state)
    case .reportSubmitted:
      return self.report(&state)
    case .reportHistoryTapped:
      state.overlay = nil
      return .send(.delegate(.showInquiryHistory))
    default:
      Self.step(action, &state)
    }
    return .none
  }

  /// 메뉴 → 차단 확인 · 신고 시트(이미 신고했으면 기록), 신고 사유 고르기, 접수 안내
  private static func step(_ action: FriendProfileMenuAction, _ state: inout State) {
    switch action {
    case .blockTapped, .reportBlockTapped:
      state.overlay = .blockConfirm
    case .reportTapped:
      state.reportReason = nil
      state.reportDetail = ""
      state.overlay = state.profile?.myReport == nil ? .report : .reportExisting
    case let .reasonSelected(reason):
      state.reportReason = reason
    case let .reportDetailChanged(text):
      state.reportDetail = String(text.prefix(FriendProfileText.reportDetailLimit))
    case .dismissed:
      // 차단 확인 창으로 넘어가는 중이거나 신고를 보내는 중이면 그대로 둔다
      guard state.overlay != .blockConfirm, !state.isReporting else { return }
      state.overlay = nil
      state.reportReason = nil
      state.reportDetail = ""
    case .blockCancelled:
      state.overlay = nil
    case let .reported(report):
      state.isReporting = false
      state.reportReason = nil
      state.reportDetail = ""
      state.profile?.myReport = report
      state.overlay = .reportDone
    default:
      break
    }
  }

  /// 차단하면 서로 팔로우가 끊긴다 — 풀어도 팔로우는 다시 해야 한다(원본 토스트)
  private func block(isOn: Bool, _ state: inout State) -> Effect<Action> {
    let rollback = FriendProfileRollback.blocked(isBlocked: state.isBlocked, profile: state.profile)
    state.overlay = nil
    state.isBlocked = isOn
    state.isNowPlayingMenuOpen = false
    if isOn, state.profile?.isFollowing == true {
      state.profile?.isFollowing = false
      state.profile?.followerCount -= 1
    }
    state.toast = isOn ? FriendProfileText.blocked : FriendProfileText.unblocked
    let userID = state.userID
    return self.send(rollback) { try await self.client.setBlocked(userID, isOn) }
  }

  /// 접수되면 안내 시트로 바꾼다. 보내는 동안 시트는 그대로 둔다
  private func report(_ state: inout State) -> Effect<Action> {
    guard state.canSubmitReport, let reason = state.reportReason else { return .none }
    state.isReporting = true
    let detail = reason == .other ? state.reportDetail.trimmingCharacters(in: .whitespacesAndNewlines) : nil
    let userID = state.userID
    return .run { send in
      do {
        let report = try await self.client.report(userID, reason, detail)
        await send(.menu(.reported(report)))
      } catch {
        await send(.rollback(.report))
      }
    }
  }

  private func send(
    _ rollback: FriendProfileRollback,
    _ operation: @escaping @Sendable () async throws -> Void
  ) -> Effect<Action> {
    .run { send in
      do {
        try await operation()
      } catch {
        await send(.rollback(rollback))
      }
    }
  }

  static func apply(_ rollback: FriendProfileRollback, _ state: inout State) {
    switch rollback {
    case let .follow(isFollowing, followerCount):
      state.profile?.isFollowing = isFollowing
      state.profile?.followerCount = followerCount
    case let .blocked(isBlocked, profile):
      state.isBlocked = isBlocked
      state.profile = profile
    case let .postLike(post):
      state.profile?.posts[id: post.id] = post
    case .invite:
      state.isInviteSent = false
    case .saveSong:
      state.isSongSaved = false
    case .report:
      // 시트 뒤에서는 토스트가 보이지 않아 닫고 알린다
      state.isReporting = false
      state.overlay = nil
    }
    state.toast = FriendProfileText.failed
  }
}
