import ComposableArchitecture
import Foundation

// REQ-013 · UI-7c · UI-17e · DEC-004 — 계정 정보 · 탈퇴 신청 · 되살리기 · 로그인 직후 계정 상태.
// 14일 보관 · 삭제 예정일 · 재가입 제한은 서버가 정한다(소셜 로그인 식별값 기준). 백엔드가 정해지기 전까지 목업.
// Apple로 가입한 계정은 탈퇴할 때 Apple 토큰도 revoke해야 한다(App Store 요구) — 실제 로그인 연동(#14)에서.
// 개인정보 — 이메일 · 탈퇴 사유는 로그에 남기지 않는다.

struct AccountClient {
  var account: @Sendable () async throws -> AccountInfo
  var blockedUsers: @Sendable () async throws -> [BlockedUser]
  var linkGoogle: @Sendable () async throws -> String
  /// 탈퇴 신청 — 서버가 정한 삭제 예정일을 돌려준다
  var withdraw: @Sendable (_ reasons: Set<WithdrawReason>) async throws -> Date
  var signOut: @Sendable () async -> Void
  /// 로그인 직후 계정 상태(UI-17e)
  var status: @Sendable () async throws -> AccountStatus
  /// 탈퇴 신청 취소(계정 되살리기)
  var restore: @Sendable () async throws -> Void
}

extension AccountClient: DependencyKey {
  static let liveValue = AccountClient(
    account: {
      AccountInfo(linked: [.apple: "d•••••@privaterelay.appleid.com"], joinedText: "2024.05.03", primary: .apple)
    },
    blockedUsers: {
      [BlockedUser(id: "woogi", name: "woogi"), BlockedUser(id: "dbeoddl__", name: "dbeoddl__")]
    },
    linkGoogle: { "w•••••@gmail.com" },
    withdraw: { _ in
      @Dependency(\.date.now)
      var now
      // 목업 — 서버가 신청일 + 14일을 정한다
      return now.addingTimeInterval(14 * 24 * 60 * 60)
    },
    signOut: {},
    status: { .active },
    restore: {}
  )

  /// 미리보기 — 로그인하면 탈퇴 유예 화면(17e)이 먼저 뜬다
  static let previewValue = {
    var client = Self.liveValue
    client.status = { .pendingDeletion(.preview) }
    return client
  }()

  static let testValue = AccountClient(
    account: unimplemented(
      "AccountClient.account",
      placeholder: AccountInfo(linked: [:], joinedText: "", primary: .apple)
    ),
    blockedUsers: unimplemented("AccountClient.blockedUsers", placeholder: []),
    linkGoogle: unimplemented("AccountClient.linkGoogle", placeholder: ""),
    withdraw: unimplemented("AccountClient.withdraw", placeholder: Date(timeIntervalSince1970: 0)),
    signOut: unimplemented("AccountClient.signOut"),
    // 로그인 테스트가 계정 상태를 몰라도 되게 기본은 정상 계정
    status: { .active },
    restore: unimplemented("AccountClient.restore")
  )
}

extension PendingDeletion {
  /// 원본 17e 예시 — 10월 21일 신청 · 11월 4일 삭제
  static let preview = PendingDeletion(
    requestedAt: Date(timeIntervalSince1970: 1792551600),
    deletesAt: Date(timeIntervalSince1970: 1793761200),
    keeps: ["추천한 곡 42곡과 릴레이 순위 기록", "팔로우 18명 · 팔로워 24명", "내 명함과 칭호 3개", "보관함 플레이리스트 6개"]
  )
}

extension RejoinBlock {
  /// 원본 17e 예시 — 11월 2일부터 다시 가입
  static let preview = RejoinBlock(
    reason: "욕설 · 비하 표현",
    rejoinAt: Date(timeIntervalSince1970: 1793588400),
    provider: .apple
  )
}

extension DependencyValues {
  var accountClient: AccountClient {
    get { self[AccountClient.self] }
    set { self[AccountClient.self] = newValue }
  }
}
