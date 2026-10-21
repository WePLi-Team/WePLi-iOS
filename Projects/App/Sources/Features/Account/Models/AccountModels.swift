import Foundation

// REQ-013 · UI-7c · UI-17e · DEC-004 — 계정 관리 · 회원 탈퇴 · 탈퇴 유예 · 재가입 제한.
// 삭제 예정일 · 제한 종료일은 서버 값(14일 계산도 서버). 화면은 Asia/Seoul 날짜로만 보인다.

/// 로그인 수단 — 계정 관리 「로그인 정보」
enum LoginProvider: CaseIterable, Equatable, Sendable {
  case apple
  case google

  var name: String {
    switch self {
    case .apple: "Apple"
    case .google: "Google"
    }
  }
}

struct AccountInfo: Equatable, Sendable {
  /// 연결된 수단과 표시용 이메일(가린 값 — 서버가 준다)
  var linked: [LoginProvider: String]
  /// 「2024.05.03」
  let joinedText: String
  /// 가입한 수단 — 탈퇴하면 이 수단의 로그인 연결도 끊는다(7c 노트 01)
  let primary: LoginProvider
}

struct BlockedUser: Equatable, Identifiable, Sendable {
  let id: String
  let name: String
  var photoURL: URL?
}

/// 탈퇴 사유(여러 개) — 원본 7c 순서
enum WithdrawReason: CaseIterable, Equatable, Hashable, Sendable {
  case rarelyUsed
  case noSongs
  case community
  case privacy
  case otherService

  var title: String {
    switch self {
    case .rarelyUsed: "자주 사용하지 않아요"
    case .noSongs: "듣고 싶은 노래가 없어요"
    case .community: "커뮤니티 이용이 불편해요"
    case .privacy: "개인정보가 걱정돼요"
    case .otherService: "다른 서비스를 이용할 거예요"
    }
  }
}

/// 계정 관리 → 탈퇴 1/2 사유 → 2/2 확인 → 완료
enum AccountStep: Int, Comparable, Equatable, Sendable {
  case manage
  case reason
  case confirm
  case done

  static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

  var title: String {
    switch self {
    case .manage: "계정 관리"
    case .reason, .confirm: "회원 탈퇴"
    case .done: ""
    }
  }
}

/// 로그인 직후 계정 상태(UI-17e)
enum AccountStatus: Equatable, Sendable {
  case active
  /// 탈퇴 유예 — 14일 안에 다시 로그인함
  case pendingDeletion(PendingDeletion)
  /// 이용 제한 중에 탈퇴한 계정 — 제한이 끝날 때까지 다시 가입할 수 없다
  case rejoinBlocked(RejoinBlock)
}

struct PendingDeletion: Equatable, Sendable {
  let requestedAt: Date
  let deletesAt: Date
  /// 되살리면 돌아오는 것 — 「추천한 곡 42곡과 릴레이 순위 기록」 …
  let keeps: [String]
}

struct RejoinBlock: Equatable, Sendable {
  /// 「욕설 · 비하 표현」
  let reason: String
  let rejoinAt: Date
  let provider: LoginProvider
}

enum AccountText {
  static let seoul: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    return calendar
  }()

  /// 「11월 4일」 — Asia/Seoul 날짜(DEC-004)
  static func day(_ date: Date) -> String {
    let parts = self.seoul.dateComponents([.month, .day], from: date)
    return "\(parts.month ?? 0)월 \(parts.day ?? 0)일"
  }

  /// 탈퇴 확인(7c 2/2) — 원본 5줄. 마지막 줄은 가입한 수단 이름
  static func rules(_ provider: LoginProvider) -> [String] {
    [
      "탈퇴를 신청하고 14일 안에 다시 로그인하면 계정을 되살릴 수 있어요. 14일이 지나면 모든 정보가 삭제돼요.",
      "내가 쓴 게시글과 댓글은 지워지지 않고 ‘탈퇴한 사용자’로 표시돼요. 지우고 싶다면 탈퇴 전에 직접 삭제해 주세요.",
      "추천한 곡과 투표 기록은 릴레이리스트 집계에 그대로 남아요.",
      "명함, 내 플레이리스트, 좋아요·저장 목록은 모두 삭제되고 되돌릴 수 없어요.",
      "\(provider.name) 로그인 연결도 함께 해제돼요.",
    ]
  }
}
