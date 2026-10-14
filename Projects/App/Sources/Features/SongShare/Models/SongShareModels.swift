import Foundation

// REQ-066 · UI-3g — 곡 공유 카드

struct SongShareCard: Equatable, Sendable {
  let songID: String
  let title: String
  let artist: String
  /// 공유자 — 프로필을 불러오기 전에는 nil이고 프로필 칩을 숨긴다
  var sharerName: String?
  /// 성향 이름 — 원본 카드는 영문(「Melody Memories」)이지만 영문 이름이 하나만 있어 한글 이름을 쓴다(문구 확인 필요)
  var sharerPersona: String?
  /// 「15」
  let day: String
  /// 「OCT」
  let month: String

  /// 「소년, 길을 걷다 · 이승기」
  var subtitle: String {
    "\(self.title) · \(self.artist)"
  }

  init(songID: String, title: String, artist: String, sharerName: String?, sharerPersona: String?, today: Date) {
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
struct ShareCardDate: Equatable {
  static let months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

  let day: String
  let month: String

  init(_ date: Date) {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    let components = calendar.dateComponents([.day, .month], from: date)
    self.day = String(format: "%02d", components.day ?? 1)
    self.month = Self.months[((components.month ?? 1) - 1) % 12]
  }
}

/// 시스템 공유 시트에 넘길 내용
struct SystemShareItem: Equatable, Identifiable {
  let id: Int
  let image: Data
  let link: URL?
}
