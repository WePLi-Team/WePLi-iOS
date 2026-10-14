import Foundation

// REQ-070 · UI-1e · UI-3e

/// 나의 성향 5종 — 원본 personaData 순서
enum Persona: Int, CaseIterable, Equatable, Sendable {
  case socialTunes
  case melodyMemories
  case nostalgiaSeoner
  case sentimentalSymphony
  case energyFlash

  var name: String {
    switch self {
    case .socialTunes: "소셜 튠즈"
    case .melodyMemories: "멜로디 메모리즈"
    case .nostalgiaSeoner: "노스텔지어 서너"
    case .sentimentalSymphony: "센티멘탈 심포니"
    case .energyFlash: "에너지 플래시"
    }
  }

  var summary: String {
    switch self {
    case .socialTunes: "같이 노래 듣는 걸 좋아해요"
    case .melodyMemories: "추억을 노래와 함께 간직하고 싶어요"
    case .nostalgiaSeoner: "옛날 감성의 노래를 좋아해요"
    case .sentimentalSymphony: "감성적인 노래를 좋아해요"
    case .energyFlash: "신나는 노래를 좋아해요"
    }
  }
}

struct MyProfile: Equatable, Sendable {
  var nickname: String
  var email: String
  var persona: Persona?
  var photoURL: URL?
  /// 소개(50자, UI-3e)
  var bio = ""
}

/// 마이 탭 그룹 목록의 행 (UI-1e)
enum MyMenu: Equatable, CaseIterable, Sendable {
  case myPlaylists
  case joinedRelays
  case likesAndSaves
  case notificationSettings
  case serviceGuide
  case noticesAndTerms
  case developerMode

  var title: String {
    switch self {
    case .myPlaylists: "내 플레이리스트"
    case .joinedRelays: "참여한 릴레이리스트"
    case .likesAndSaves: "좋아요 • 저장"
    case .notificationSettings: "알림 설정"
    case .serviceGuide: "서비스 이용 가이드"
    case .noticesAndTerms: "공지 • 이용약관"
    case .developerMode: "개발자 모드"
    }
  }

  var systemImage: String {
    switch self {
    case .myPlaylists: "list.bullet"
    case .joinedRelays: "music.note.list"
    case .likesAndSaves: "heart"
    case .notificationSettings: "bell"
    case .serviceGuide: "book.closed"
    case .noticesAndTerms: "doc.text"
    case .developerMode: "terminal"
    }
  }
}

/// 그룹 순서와 헤더 — 「앱 버전」 행은 값만 보여 주는 행이라 메뉴가 아니다.
enum MyMenuSection: CaseIterable, Equatable {
  case activity
  case settings
  case appInfo
  case etc

  var title: String {
    switch self {
    case .activity: "내 활동"
    case .settings: "설정"
    case .appInfo: "앱 정보"
    case .etc: "기타"
    }
  }

  /// 개발자 모드 행은 개발자 모드가 켜졌을 때만 보인다(UI-7g).
  func menus(isDeveloperModeEnabled: Bool) -> [MyMenu] {
    switch self {
    case .activity: [.myPlaylists, .joinedRelays, .likesAndSaves]
    case .settings: [.notificationSettings]
    case .appInfo: [.serviceGuide, .noticesAndTerms]
    case .etc: isDeveloperModeEnabled ? [.developerMode] : []
    }
  }
}
