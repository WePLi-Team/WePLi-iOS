import Foundation

// REQ-035 · UI-8c · UI-11c — 바통 릴레이. 차례 · 남은 시간 · 다음 사람은 서버 값(DEC-004)

public struct BatonRelay: Equatable, Identifiable, Sendable {
  public struct Runner: Equatable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public var state: BatonRunnerState

    public init(id: String, name: String, state: BatonRunnerState) {
      self.id = id
      self.name = name
      self.state = state
    }
  }

  /// 이어진 곡 한 칸
  public struct Link: Equatable, Identifiable, Sendable {
    public var id: String {
      "\(self.runner)|\(self.title)"
    }

    public let runner: String
    public let title: String
    public let artist: String
    /// 「시작」 · 「#비 이어받음」
    public let keywordFrom: String
    /// 다음 사람에게 넘긴 키워드 「#새벽」
    public let keyword: String

    public init(runner: String, title: String, artist: String, keywordFrom: String, keyword: String) {
      self.runner = runner
      self.title = title
      self.artist = artist
      self.keywordFrom = keywordFrom
      self.keyword = keyword
    }
  }

  public struct Pick: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let artist: String

    public init(id: String, title: String, artist: String) {
      self.id = id
      self.title = title
      self.artist = artist
    }
  }

  /// 내 차례 상태
  public enum Turn: Equatable, Sendable {
    /// 링크로 받았다 — 아직 받지 않음(11c)
    case invited(passer: String)
    /// 내 차례 — 이 시각까지
    case mine(endsAt: Date)
    /// 넘겼다
    case passed(keyword: String)
    /// 받지 않고 바로 넘겼다(11c)
    case skipped
  }

  public let id: String
  /// 「비 오는 밤 이어달리기」
  public let title: String
  public var runners: [Runner]
  public var chain: [Link]
  /// 이어받을 키워드 「#바다」
  public let keyword: String
  /// 내 차례에 고를 곡 · 다음 키워드 후보
  public let picks: [Pick]
  public let nextKeywords: [String]
  /// 다음 사람 「dlwlrma」
  public let nextRunner: String
  public var turn: Turn

  public var total: Int {
    self.runners.count
  }

  /// 이어진 사람 수 「4 / 8」
  public var count: Int {
    self.chain.count
  }

  /// 「8명 중 5번째」
  public var myPosition: Int {
    self.chain.count + 1
  }

  public init(
    id: String,
    title: String,
    runners: [Runner],
    chain: [Link],
    keyword: String,
    picks: [Pick],
    nextKeywords: [String],
    nextRunner: String,
    turn: Turn
  ) {
    self.id = id
    self.title = title
    self.runners = runners
    self.chain = chain
    self.keyword = keyword
    self.picks = picks
    self.nextKeywords = nextKeywords
    self.nextRunner = nextRunner
    self.turn = turn
  }
}

/// 이은 사람 · 지금 달리는 사람 · 기다리는 사람
public enum BatonRunnerState: Equatable, Sendable {
  case done
  case now
  case waiting
}

public enum BatonText {
  /// 차례 시간(24시간)
  public static let turnLength: TimeInterval = 24 * 3600

  /// 「23:41:12」 — 시간은 0을 채우지 않는다(원본)
  public static func clock(from now: Date, to endsAt: Date) -> String {
    let seconds = max(0, Int(endsAt.timeIntervalSince(now)))
    return "\(seconds / 3600):" + String(format: "%02d:%02d", seconds % 3600 / 60, seconds % 60)
  }
}
