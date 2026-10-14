import ComposableArchitecture
import Foundation

// REQ-082 · UI-5d — 알림 설정은 서버에 저장한다. 백엔드가 정해지기 전까지 목업이다.

enum NotificationSetting: String, CaseIterable, Equatable, Sendable {
  case deadline
  case rank
  case completed
  case comment
  case like
  case follower
  case doNotDisturb
  case promotion

  var title: String {
    switch self {
    case .deadline: "마감 1시간 전"
    case .rank: "내 추천곡 순위 변동"
    case .completed: "릴레이리스트 완성"
    case .comment: "내 게시글에 달린 댓글"
    case .like: "좋아요"
    case .follower: "새 팔로워"
    case .doNotDisturb: "방해 금지 시간 사용"
    case .promotion: "이벤트 · 혜택 알림"
    }
  }

  var detail: String? {
    switch self {
    case .deadline: "참여한 릴레이리스트가 끝나기 전에 알려드려요"
    case .promotion: "광고성 정보 수신"
    case .rank, .completed, .comment, .like, .follower, .doNotDisturb: nil
    }
  }
}

struct NotificationSettings: Equatable, Sendable {
  /// 푸시 알림 전체 — 끄면 아래 값은 남겨 둔 채 모두 받지 않는다
  var isPushEnabled: Bool
  var enabled: Set<NotificationSetting>
  /// 「22:00 – 08:00」
  var quietHours: String
  /// 광고성 정보 수신 동의 날짜(「2024.05.03」). 동의하지 않았으면 nil
  var promotionConsentDate: String?

  static let defaults = NotificationSettings(
    isPushEnabled: true,
    enabled: [.deadline, .rank, .completed, .comment, .follower, .doNotDisturb],
    quietHours: "22:00 – 08:00",
    promotionConsentDate: nil
  )
}

struct NotificationSettingsClient {
  var fetch: @Sendable () async throws -> NotificationSettings
  /// 저장한 결과를 돌려준다 — 광고성 알림을 켜면 서버가 동의 날짜를 기록한다
  var save: @Sendable (_ settings: NotificationSettings) async throws -> NotificationSettings
}

extension NotificationSettingsClient: DependencyKey {
  static let liveValue = NotificationSettingsClient(
    fetch: { .defaults },
    save: { settings in
      @Dependency(\.date.now)
      var now
      var saved = settings
      if saved.enabled.contains(.promotion) {
        saved.promotionConsentDate = saved.promotionConsentDate ?? ConsentDate.string(now)
      } else {
        saved.promotionConsentDate = nil
      }
      return saved
    }
  )

  static let previewValue = liveValue

  static let testValue = NotificationSettingsClient(
    fetch: unimplemented("NotificationSettingsClient.fetch", placeholder: .defaults),
    save: unimplemented("NotificationSettingsClient.save", placeholder: .defaults)
  )
}

extension DependencyValues {
  var notificationSettingsClient: NotificationSettingsClient {
    get { self[NotificationSettingsClient.self] }
    set { self[NotificationSettingsClient.self] = newValue }
  }
}

/// 동의 날짜 「yyyy.MM.dd」 — Asia/Seoul 기준(DEC-004)
enum ConsentDate {
  static func string(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
    formatter.dateFormat = "yyyy.MM.dd"
    return formatter.string(from: date)
  }
}
