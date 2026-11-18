import Foundation

// REQ-066 · UI-3g — 곡 공유 카드

public struct SongShareCard: Equatable, Sendable {
  public let songID: String
  public let title: String
  public let artist: String
  /// 공유자 — 프로필을 불러오기 전에는 nil이고 프로필 칩을 숨긴다
  public var sharerName: String?
  /// 성향 이름 — 원본 카드는 영문(「Melody Memories」)이지만 영문 이름이 하나만 있어 한글 이름을 쓴다(문구 확인 필요)
  public var sharerPersona: String?
  /// 「15」
  public let day: String
  /// 「OCT」
  public let month: String

  /// 「소년, 길을 걷다 · 이승기」
  public var subtitle: String {
    "\(self.title) · \(self.artist)"
  }

  public init(songID: String, title: String, artist: String, sharerName: String?, sharerPersona: String?, today: Date) {
    self.songID = songID
    self.title = title
    self.artist = artist
    self.sharerName = sharerName
    self.sharerPersona = sharerPersona
    let date = ShareCardDate(today)
    self.day = date.day
    self.month = date.month
  }
}

/// 카드 날짜는 오늘 날짜 — Asia/Seoul 기준(DEC-004)
public struct ShareCardDate: Equatable {
  public static let months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

  public let day: String
  public let month: String

  public init(_ date: Date) {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    let components = calendar.dateComponents([.day, .month], from: date)
    self.day = String(format: "%02d", components.day ?? 1)
    self.month = Self.months[((components.month ?? 1) - 1) % 12]
  }
}

/// 시스템 공유 시트에 넘길 내용
public struct SystemShareItem: Equatable, Identifiable {
  public let id: Int
  public let image: Data
  public let link: URL?

  public init(id: Int, image: Data, link: URL?) {
    self.id = id
    self.image = image
    self.link = link
  }
}
