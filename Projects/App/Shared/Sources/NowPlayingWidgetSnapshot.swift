import Foundation

// REQ-079 · UI-13e · DEC-015 — 잠금화면 위젯 데이터. 앱과 위젯 확장이 App Group으로 함께 쓴다.
// 다른 사람의 음악만 담는다(내 음악은 iOS가 이미 보여준다). 개인 식별자 · 토큰은 담지 않는다.

struct NowPlayingWidgetSnapshot: Codable, Equatable, Sendable {
  struct Person: Codable, Equatable, Sendable {
    let name: String
    let title: String
    let artist: String
    /// 그 곡을 들은 시각
    let listenedAt: Date
  }

  struct Group: Codable, Equatable, Sendable {
    let name: String
    /// 지금 듣는 사람 수
    let listeningCount: Int
  }

  var person: Person?
  var group: Group?

  /// 원본(UI-13e) 예시 — 위젯 미리보기 · 데이터가 없을 때
  static let placeholder = NowPlayingWidgetSnapshot(
    person: Person(name: "여자친구", title: "밤편지", artist: "아이유", listenedAt: Date().addingTimeInterval(-120)),
    group: Group(name: "우리 넷", listeningCount: 3)
  )
}

enum NowPlayingWidgetText {
  /// 「방금」 · 「2분 전」 · 「1시간 전」 · 「어제」 — 위젯은 몇 분 단위로 갱신되므로 시각을 함께 둔다
  static func ago(_ date: Date, now: Date) -> String {
    let minutes = Int(now.timeIntervalSince(date) / 60)
    switch minutes {
    case ..<1: return "방금"
    case ..<60: return "\(minutes)분 전"
    case ..<1440: return "\(minutes / 60)시간 전"
    default: return "어제"
    }
  }
}

/// App Group 저장소 — 앱이 쓰고 위젯이 읽는다
enum NowPlayingWidgetStore {
  static let appGroup = "group.com.example.wepli"
  static let key = "wepli.widget.nowPlaying"
  static let widgetKind = "WePLiNowPlaying"

  static func read() -> NowPlayingWidgetSnapshot? {
    guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: key) else { return nil }
    return try? JSONDecoder().decode(NowPlayingWidgetSnapshot.self, from: data)
  }

  static func write(_ snapshot: NowPlayingWidgetSnapshot) {
    guard let data = try? JSONEncoder().encode(snapshot) else { return }
    UserDefaults(suiteName: Self.appGroup)?.set(data, forKey: Self.key)
  }
}
