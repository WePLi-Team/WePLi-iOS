import Foundation

// REQ-035 · UI-8c · UI-11c — 바통 릴레이. 차례 · 남은 시간 · 다음 사람은 서버 값(DEC-004)

struct BatonRelay: Equatable, Identifiable, Sendable {
  struct Runner: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    var state: BatonRunnerState
  }

  /// 이어진 곡 한 칸
  struct Link: Equatable, Identifiable, Sendable {
    var id: String {
      "\(self.runner)|\(self.title)"
    }

    let runner: String
    let title: String
    let artist: String
    /// 「시작」 · 「#비 이어받음」
    let keywordFrom: String
    /// 다음 사람에게 넘긴 키워드 「#새벽」
    let keyword: String
  }

  struct Pick: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let artist: String
  }

  /// 내 차례 상태
  enum Turn: Equatable, Sendable {
    /// 링크로 받았다 — 아직 받지 않음(11c)
    case invited(passer: String)
    /// 내 차례 — 이 시각까지
    case mine(endsAt: Date)
    /// 넘겼다
    case passed(keyword: String)
    /// 받지 않고 바로 넘겼다(11c)
    case skipped
  }

  let id: String
  /// 「비 오는 밤 이어달리기」
  let title: String
  var runners: [Runner]
  var chain: [Link]
  /// 이어받을 키워드 「#바다」
  let keyword: String
  /// 내 차례에 고를 곡 · 다음 키워드 후보
  let picks: [Pick]
  let nextKeywords: [String]
  /// 다음 사람 「dlwlrma」
  let nextRunner: String
  var turn: Turn

  var total: Int {
    self.runners.count
  }

  /// 이어진 사람 수 「4 / 8」
  var count: Int {
    self.chain.count
  }

  /// 「8명 중 5번째」
  var myPosition: Int {
    self.chain.count + 1
  }
}

/// 이은 사람 · 지금 달리는 사람 · 기다리는 사람
enum BatonRunnerState: Equatable, Sendable {
  case done
  case now
  case waiting
}

enum BatonText {
  /// 차례 시간(24시간)
  static let turnLength: TimeInterval = 24 * 3600

  /// 「23:41:12」 — 시간은 0을 채우지 않는다(원본)
  static func clock(from now: Date, to endsAt: Date) -> String {
    let seconds = max(0, Int(endsAt.timeIntervalSince(now)))
    return "\(seconds / 3600):" + String(format: "%02d:%02d", seconds % 3600 / 60, seconds % 60)
  }
}
