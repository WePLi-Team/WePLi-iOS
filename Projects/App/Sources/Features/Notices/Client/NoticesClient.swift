import ComposableArchitecture
import Foundation

// REQ-110 · DEC-004 — 백엔드가 정해지기 전까지 원본(UI-7a) 예시를 돌려주는 목업이다.

struct NoticesClient {
  var fetch: @Sendable () async throws -> [Notice]
  var markRead: @Sendable (_ id: Notice.ID) async -> Void
}

extension NoticesClient: DependencyKey {
  static let liveValue = NoticesClient(fetch: { Notice.mock }, markRead: { _ in })
  static let previewValue = liveValue
  static let testValue = NoticesClient(
    fetch: unimplemented("NoticesClient.fetch", placeholder: []),
    markRead: unimplemented("NoticesClient.markRead")
  )
}

extension DependencyValues {
  var noticesClient: NoticesClient {
    get { self[NoticesClient.self] }
    set { self[NoticesClient.self] = newValue }
  }
}

extension Notice {
  /// 원본(UI-7a) 예시 — 각 탭의 위 두 글이 안 읽음
  static let mock: [Notice] = [
    Notice(
      id: "maintenance",
      kind: .notice,
      title: "서버 점검 안내 (10월 15일 02:00–05:00)",
      dateText: "2026.10.08",
      body: """
      보다 안정적인 위플리를 위해 서버 점검을 진행해요.

      일시: 10월 15일(목) 02:00 – 05:00
      내용: 서버 안정화, 투표 시스템 개선

      점검 중에는 앱을 이용할 수 없어요. 진행 중인 릴레이리스트의 마감 시간은 점검 시간만큼 자동으로 늘어나요.
      """,
      isPinned: true,
      isUnread: true
    ),
    Notice(
      id: "vote-change",
      kind: .notice,
      title: "릴레이리스트 투표 방식이 바뀌어요",
      dateText: "2026.10.01",
      body: """
      이제 상위 10곡을 한 장씩 넘기며 ‘주제와 어울려요 / 별로인 것 같아요’로 투표해요. 11위 이하는 추천 수로 점수가 쌓여요.

      바뀐 방식은 1.2.0 버전부터 적용돼요.
      """,
      isUnread: true
    ),
    Notice(
      id: "policy",
      kind: .notice,
      title: "커뮤니티 운영정책 개정 안내",
      dateText: "2026.09.20",
      body: "신고 · 차단 기준과 이용 제한 단계를 명확하게 정리했어요. 자세한 내용은 앱 정보 › 운영정책에서 확인할 수 있어요."
    ),
    Notice(
      id: "launch",
      kind: .notice,
      title: "WePLi iOS 앱이 출시됐어요",
      dateText: "2026.09.01",
      body: "iPhone에서도 위플리와 함께 플레이리스트를 만들어 보세요. 잠금화면 Live Activity와 위젯도 지원해요."
    ),
    Notice(
      id: "instagram",
      kind: .event,
      title: "위플리 인스타그램 OPEN! 팔로우 이벤트",
      dateText: "~ 2026.10.31",
      body: """
      감성 가득한 일상을 위플리 인스타그램에서 만나보세요. 10월 31일까지 팔로우한 분 중 추첨으로 선물을 드려요.

      당첨자 발표: 11월 7일 공지사항
      """,
      eventStatus: .ongoing,
      hasImage: true,
      isUnread: true
    ),
    Notice(
      id: "chart",
      kind: .event,
      title: "실시간 통합 순위를 한 눈에! 위플리 차트 오픈",
      dateText: "2026.09.01 – 09.30",
      body: "위플리 차트 오픈을 기념한 이벤트가 종료되었어요. 참여해 주셔서 고마워요.",
      eventStatus: .ended,
      hasImage: true,
      isUnread: true
    ),
  ]
}
