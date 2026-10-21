import Foundation

// REQ-039 · UI-8d · DEC-021 — 내 칭호. 한 번 얻은 칭호는 유지되고 대표 칭호는 1개다.
// 얻었는지 · 진행도는 서버 값(DEC-004)

struct UserTitle: Equatable, Identifiable, Sendable {
  enum Icon: Equatable, Sendable {
    case curator
    case seer
    case comeback
    case host
    case baton
    case season

    /// 원본 선 아이콘 대신 가까운 SF Symbol — 아이콘 에셋이 붙으면 바꾼다
    var systemName: String {
      switch self {
      case .curator: "music.note.list"
      case .seer: "alarm"
      case .comeback: "arrow.up.arrow.down"
      case .host: "crown"
      case .baton: "arrow.up.right"
      case .season: "star"
      }
    }
  }

  let id: String
  /// 「플레이리스트 MD」
  let name: String
  /// 「내 추천곡 TOP 3에 5번」
  let condition: String
  let icon: Icon
  let isEarned: Bool
  /// 아직 못 얻은 칭호의 진행도 — 「2/3」
  var progress: String?

  /// 「추천곡 역전 3회 · 2/3」
  var conditionLine: String {
    self.progress.map { "\(self.condition) · \($0)" } ?? self.condition
  }
}

struct TitleBoard: Equatable, Sendable {
  /// 대표 칭호 미리보기에 붙는 내 이름
  let nickname: String
  let titles: [UserTitle]
  /// 대표 칭호 — 얻은 칭호 중 1개
  var representativeID: UserTitle.ID?

  var representative: UserTitle? {
    self.representativeID.flatMap { id in self.titles.first { $0.id == id } }
  }

  /// 대표로 고를 수 있는지 — 얻은 칭호이고 지금 대표가 아닐 때
  func canChoose(_ id: UserTitle.ID) -> Bool {
    self.representativeID != id && self.titles.contains { $0.id == id && $0.isEarned }
  }
}

extension TitleBoard {
  /// 원본(UI-8d) 예시 — 조건은 DEC-021
  static let mock = TitleBoard(
    nickname: "김동",
    titles: [
      UserTitle(id: "curator", name: "플레이리스트 MD", condition: "내 추천곡 TOP 3에 5번", icon: .curator, isEarned: true),
      UserTitle(id: "seer", name: "예언자", condition: "1위 예측 3번 적중", icon: .seer, isEarned: true),
      UserTitle(
        id: "comeback",
        name: "역전의 명수",
        condition: "추천곡 역전 3회",
        icon: .comeback,
        isEarned: false,
        progress: "2/3"
      ),
      UserTitle(id: "host", name: "호스트", condition: "내가 연 릴레이에 50명 참여", icon: .host, isEarned: true),
      UserTitle(id: "baton", name: "바통 러너", condition: "바통 릴레이 완주", icon: .baton, isEarned: false),
      UserTitle(id: "season", name: "시즌 TOP 10", condition: "시즌 랭킹 10위 안", icon: .season, isEarned: false),
    ],
    representativeID: "curator"
  )
}
