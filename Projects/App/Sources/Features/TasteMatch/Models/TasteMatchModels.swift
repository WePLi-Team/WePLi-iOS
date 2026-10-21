import ComposableArchitecture
import Foundation

// REQ-102 · UI-6d · DEC-023 — 취향 궁합. 점수는 서버가 낸다(최근 30일 동안 둘 다 듣거나 추천한 곡 · 가수가
// 겹치는 비율). 서로 팔로우한 사이에서만 보이고 두 사람이 같은 점수를 본다(DEC-004).

struct TasteMatch: Equatable, Sendable {
  let userID: String
  /// 0–100
  let score: Int
  /// 같은 성향이면 그 이름(「센티멘탈 심포니」) — 다르면 nil
  let sharedPersona: String?
  /// 둘 다 자주 듣는 아티스트
  let artists: [String]
  /// 내가 좋아하지만 상대는 아직 안 들어본 곡
  var recommendations: IdentifiedArrayOf<TasteMatchSong>
}

struct TasteMatchSong: Equatable, Identifiable, Sendable {
  var id: String {
    "\(self.title)|\(self.artist)"
  }

  let title: String
  let artist: String
  /// 추천을 보냈다 — 곡당 1번, 되돌리지 않는다(REQ-102)
  var isSent = false
}

enum TasteMatchText {
  /// 「chuuuuu__님과 꽤 잘 맞아요」 — 미결정: 점수 구간별 문구(원본은 82점 예시 하나)
  static func headline(name: String, score: Int) -> String {
    let phrase = switch score {
    case 90...: "정말 잘 맞아요"
    case 70...: "꽤 잘 맞아요"
    case 40...: "조금 맞아요"
    default: "아직 잘 몰라요"
    }
    return "\(name)님과 \(phrase)"
  }

  static func recommendTitle(_ name: String) -> String {
    "\(name)님에게 추천해 볼 곡"
  }

  // 원본에 없는 문구 — 디자인 확인 필요
  static let sendFailed = "추천을 보내지 못했어요. 다시 시도해 주세요"
  static let loadFailed = "취향 궁합을 불러오지 못했어요"
}
