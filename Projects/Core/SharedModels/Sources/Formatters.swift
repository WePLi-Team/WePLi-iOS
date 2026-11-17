import Foundation

// DEC-033 · 여러 기능이 함께 쓰는 값 타입 — 기능 폴더에서 옮겨 왔다

/// 「10,123」 — 천 단위 쉼표 (원본 toLocaleString('en-US'))
public enum CountFormatter {
  public static func string(_ count: Int) -> String {
    count.formatted(.number.locale(Locale(identifier: "en_US")))
  }
}

/// 남은 시간 표기 — 1일 이상 「N일 N시간」, 미만 「H:MM:SS」 (UI-9a · UI-10a)
public enum RemainingTimeFormatter {
  public static func string(from now: Date, to end: Date) -> String {
    var seconds = max(0, Int(end.timeIntervalSince(now)))
    let days = seconds / 86400
    seconds %= 86400
    let hours = seconds / 3600
    seconds %= 3600
    let minutes = seconds / 60
    seconds %= 60
    if days > 0 {
      return "\(days)일 \(hours)시간"
    }
    return String(format: "%d:%02d:%02d", hours, minutes, seconds)
  }
}
