import Foundation

// REQ-036 · UI-6a — 릴레이리스트 만들기

enum RelayDuration: Int, CaseIterable, Equatable, Sendable {
  case oneDay = 1
  case threeDays = 3
  case sevenDays = 7

  /// 「3일」
  var title: String {
    "\(self.rawValue)일"
  }

  /// 미리보기 「완성까지 3일 0시간 0분 0초」 — 원본은 고정 문구
  var countdownText: String {
    "완성까지 \(self.rawValue)일 0시간 0분 0초"
  }
}

/// 투표 방식 — 만들기에서는 카드 · 월드컵만 고른다(바통은 따로 연다)
enum CreateRelayVoteFormat: CaseIterable, Equatable, Sendable {
  case card
  case worldCup

  var title: String {
    switch self {
    case .card: "카드 넘기기"
    case .worldCup: "곡 월드컵"
    }
  }

  var detail: String {
    switch self {
    case .card: "상위 10곡을 한 장씩 어울려요/별로예요"
    case .worldCup: "두 곡 중 더 어울리는 곡을 골라 결승까지"
    }
  }

  var relayFormat: Relay.VoteFormat {
    switch self {
    case .card: .card
    case .worldCup: .worldCup
    }
  }
}

enum RelayAudience: CaseIterable, Equatable, Sendable {
  case everyone
  case followers

  var title: String {
    switch self {
    case .everyone: "전체 공개"
    case .followers: "팔로워만"
    }
  }

  var detail: String {
    switch self {
    case .everyone: "누구나 곡을 추천하고 투표할 수 있어요"
    case .followers: "나를 팔로우한 사람만 참여해요"
    }
  }
}

/// 서버에 보낼 새 릴레이
struct NewRelay: Equatable, Sendable {
  static let topicLimit = 30
  static let descriptionLimit = 60
  /// 커버 4종(원본은 예시 사진 — 앱 커버 묶음은 미결정이라 자리 표시 색으로 둔다)
  static let coverCount = 4

  var topic = ""
  var description = ""
  var cover = 0
  var duration: RelayDuration = .threeDays
  var voteFormat: CreateRelayVoteFormat = .card
  var firstSong: ComposeTrack?
  var audience: RelayAudience = .everyone

  /// 주제(공백 제외)와 첫 곡이 있어야 만든다
  var canCreate: Bool {
    !self.trimmedTopic.isEmpty && self.firstSong != nil
  }

  var trimmedTopic: String {
    self.topic.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
