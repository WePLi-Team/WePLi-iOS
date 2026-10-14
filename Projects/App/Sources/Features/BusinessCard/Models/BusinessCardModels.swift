import Foundation

// REQ-075 · UI-2e — 명함 만들기 6단계: 소개 → 곡 → 한 줄 소개 → Instagram → 생성 → 완성

enum BusinessCardStep: Int, CaseIterable, Equatable, Sendable {
  case intro
  case song
  case oneLiner
  case instagram
  case generating
  case done

  /// 위쪽 3칸 진행 막대 — 입력 단계(곡 · 한 줄 소개 · Instagram)에서만 보인다
  var showsNavigation: Bool {
    (1 ... 3).contains(self.rawValue)
  }

  /// 「1 / 3 · 곡 선택」 — 진행 막대의 접근성 라벨
  var accessibilityLabel: String {
    switch self {
    case .intro: "인트로"
    case .song: "1 / 3 · 곡 선택"
    case .oneLiner: "2 / 3 · 한 줄 소개"
    case .instagram: "3 / 3 · Instagram"
    case .generating: "생성 중"
    case .done: "완성"
    }
  }
}

struct BusinessCard: Equatable, Sendable {
  static let defaultOneLiner = "반갑습니다. 소통해요"

  let nickname: String
  /// 원본 카드는 영문 성향(「Melody Memories」)이지만 공유 카드와 같이 한글 이름을 쓴다(문구 확인 필요)
  let persona: String?
  let oneLiner: String
  let song: ComposeTrack?
  /// 앞의 @를 뺀 계정. 없으면 카드에 Instagram 줄을 숨긴다
  let instagram: String?
  /// 만든 날(Asia/Seoul) 「15」 · 「OCT」
  let day: String
  let month: String
}

/// 입력 규칙(UI-2e 스크립트)
enum BusinessCardInput {
  static let limit = 20

  /// 한 줄 소개 — 20자에서 자른다(공백 허용)
  static func oneLiner(_ text: String) -> String {
    String(text.prefix(self.limit))
  }

  /// Instagram — 모든 공백을 지우고 20자에서 자른다
  static func instagram(_ text: String) -> String {
    String(text.filter { !$0.isWhitespace }.prefix(self.limit))
  }

  /// 카드에 보일 계정 — 앞의 @ 한 개만 뺀다
  static func displayInstagram(_ text: String) -> String? {
    let handle = text.hasPrefix("@") ? String(text.dropFirst()) : text
    return handle.isEmpty ? nil : handle
  }

  static func hasText(_ text: String) -> Bool {
    !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}

/// 명함 공유 시트 행
enum BusinessCardShareItem: CaseIterable, Equatable, Sendable {
  case instagramStory
  case link
  case saveImage
  case otherApps

  var title: String {
    switch self {
    case .instagramStory: "인스타그램 스토리로 공유하기"
    case .link: "링크로 공유하기"
    case .saveImage: "이미지로 저장"
    case .otherApps: "다른 앱으로 공유…"
    }
  }
}
