import Foundation

// REQ-022 · UI-4b — 미리듣기 플레이어. Apple Music 카탈로그 미리듣기는 30초다(4b 노트 02).

struct PlayerTrack: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  let artist: String
}

enum PlayerText {
  /// 미리듣기 길이(초)
  static let previewLength = 30
  /// 이보다 많이 들었으면 「이전」은 처음으로 돌아간다(iOS 음악 앱과 같다)
  static let restartThreshold = 3

  /// 「0:08」
  static func elapsed(_ seconds: Int) -> String {
    "0:" + String(format: "%02d", max(0, min(seconds, previewLength)))
  }

  /// 「-0:22」
  static func remaining(_ seconds: Int) -> String {
    "-0:" + String(format: "%02d", max(0, previewLength - seconds))
  }

  static func progress(_ seconds: Int) -> Double {
    Double(max(0, min(seconds, previewLength))) / Double(previewLength)
  }
}
