import Foundation

// REQ-050 · UI-14l · 14m — 진행 중 릴레이를 지금 순위로 먼저 담고, 마감까지 순위 변동을 반영한다

/// 내보낸 플리(14m) — 위플리가 무엇을 바꿨는지 기록으로 남긴다
struct ExportedPlaylist: Equatable, Identifiable, Sendable {
  let id: String
  let relayID: String
  let title: String
  let service: ExportService
  /// 「오늘 오후 2:10 담음」
  let exportedAtText: String
  /// 진행 중이면 마감 시각 — 완성된 릴레이는 없다
  let endsAt: Date?
  var isSyncOn: Bool
  let history: [ExportChange]
}

struct ExportChange: Equatable, Identifiable, Sendable {
  let id: String
  /// 「3분 전」 · 「오후 2:10」
  let timeText: String
  let title: String
  let detail: String
}

extension ExportText {
  /// 「2일 4시간」 · 「4시간」 · 「12분」 — 마감까지
  static func untilDeadline(from now: Date, to endsAt: Date) -> String {
    let minutes = max(0, Int(endsAt.timeIntervalSince(now)) / 60)
    let days = minutes / 1440
    let hours = minutes % 1440 / 60
    if days > 0 {
      return hours > 0 ? "\(days)일 \(hours)시간" : "\(days)일"
    }
    return hours > 0 ? "\(hours)시간" : "\(max(minutes, 1))분"
  }

  /// 「1위 Radical Optimism · 2위 Houdini 외 10곡」
  static func liveTop(_ titles: [String]) -> String {
    let head = titles.prefix(2).enumerated().map { "\($0.offset + 1)위 \($0.element)" }.joined(separator: " · ")
    return titles.count > 2 ? "\(head) 외 \(titles.count - 2)곡" : head
  }
}

extension ExportedPlaylist {
  /// 원본(UI-14m) 예시
  static func mock(id: String, relayID: String, title: String, service: ExportService, endsAt: Date?) -> Self {
    ExportedPlaylist(
      id: id,
      relayID: relayID,
      title: title,
      service: service,
      exportedAtText: "오늘 오후 2:10 담음",
      endsAt: endsAt,
      isSyncOn: endsAt != nil,
      history: [
        ExportChange(id: "h3", timeText: "3분 전", title: "Radical Optimism 2위 → 1위", detail: "순서를 바꿨어요"),
        ExportChange(id: "h2", timeText: "1시간 전", title: "Espresso 들어옴 · Too Sweet 빠짐", detail: "12위 안팎이 바뀌었어요"),
        ExportChange(id: "h1", timeText: "오후 2:10", title: "처음 담음", detail: "그때 TOP 12 · 12곡"),
      ]
    )
  }
}
