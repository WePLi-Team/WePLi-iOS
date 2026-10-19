import Foundation

// REQ-112 · UI-7d · DEC-014 — 시스템 상태. 설정 · 제한은 서버 값(DEC-004). 날짜는 Asia/Seoul

/// 앱 시작 때 받는 서버 설정
struct SystemConfig: Equatable, Sendable {
  struct Update: Equatable, Sendable {
    let latest: String
    /// 「투표 방식이 바뀌어서 업데이트가 필요해요.」
    let reason: String
  }

  struct Maintenance: Equatable, Sendable {
    /// 「10월 15일 02:00 – 05:00」
    let window: String
    let endsAt: Date
  }

  struct Event: Equatable, Identifiable, Sendable {
    let id: String
    /// 「위플리\n인스타그램\nOPEN!」
    let title: String
    let body: String
  }

  /// 이 버전보다 낮으면 강제 업데이트
  var minimumVersion: String?
  var update: Update?
  var maintenance: Maintenance?
  var event: Event?
}

/// 커뮤니티 이용 제한 — 커뮤니티 동작 때 서버가 알려준다
struct CommunityRestriction: Equatable, Sendable {
  /// 「운영정책 위반 신고 누적\n(욕설 · 비하 표현)」
  let reason: String
  let days: Int
  let until: Date
  /// 「게시글 · 댓글 작성, 릴레이 곡 추천」
  let scope: String
}

/// 지금 보일 상태 — 겹치면 강제 업데이트 > 점검 > 오프라인 > 이용 제한 > 이벤트(DEC-014)
enum SystemStatus: Equatable, Sendable {
  case forceUpdate(current: String, SystemConfig.Update)
  case maintenance(SystemConfig.Maintenance)
  case offline
  case restricted(CommunityRestriction)
  case event(SystemConfig.Event)

  /// 앱 전체를 막는 상태 — 강제 업데이트 · 점검 · 오프라인
  var blocksApp: Bool {
    switch self {
    case .forceUpdate, .maintenance, .offline: true
    case .restricted, .event: false
    }
  }

  /// 강제 업데이트가 필요하면 그 상태 — 최소 버전보다 낮을 때
  static func forceUpdate(_ config: SystemConfig?, appVersion: String) -> SystemStatus? {
    guard let minimum = config?.minimumVersion, let update = config?.update else { return nil }
    return AppInfoText.isNewer(minimum, than: appVersion) ? .forceUpdate(current: appVersion, update) : nil
  }
}

enum SystemStatusText {
  /// 「약 1시간 20분」
  static func remaining(from now: Date, to endsAt: Date) -> String {
    let minutes = max(1, Int(endsAt.timeIntervalSince(now) / 60))
    let hours = minutes / 60
    if hours > 0 {
      return minutes % 60 > 0 ? "약 \(hours)시간 \(minutes % 60)분" : "약 \(hours)시간"
    }
    return "약 \(minutes)분"
  }

  /// 「2026.10.26」 — Asia/Seoul
  static func date(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
    formatter.dateFormat = "yyyy.MM.dd"
    return formatter.string(from: date)
  }

  /// 오늘 하루 보지 않기 키 — Asia/Seoul 날짜
  static func dayKey(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }
}
