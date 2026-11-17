import Foundation

// DEC-033 · 여러 기능이 함께 쓰는 값 타입 — 기능 폴더에서 옮겨 왔다

/// 나의 성향 5종 — 원본 personaData 순서
public enum Persona: Int, CaseIterable, Equatable, Sendable {
  case socialTunes
  case melodyMemories
  case nostalgiaSeoner
  case sentimentalSymphony
  case energyFlash

  public var name: String {
    switch self {
    case .socialTunes: "소셜 튠즈"
    case .melodyMemories: "멜로디 메모리즈"
    case .nostalgiaSeoner: "노스텔지어 서너"
    case .sentimentalSymphony: "센티멘탈 심포니"
    case .energyFlash: "에너지 플래시"
    }
  }

  public var summary: String {
    switch self {
    case .socialTunes: "같이 노래 듣는 걸 좋아해요"
    case .melodyMemories: "추억을 노래와 함께 간직하고 싶어요"
    case .nostalgiaSeoner: "옛날 감성의 노래를 좋아해요"
    case .sentimentalSymphony: "감성적인 노래를 좋아해요"
    case .energyFlash: "신나는 노래를 좋아해요"
    }
  }
}

public struct MyProfile: Equatable, Sendable {
  public var nickname: String
  public var email: String
  public var persona: Persona?
  public var photoURL: URL?
  /// 소개(50자, UI-3e)
  public var bio = ""

  public init(nickname: String, email: String, persona: Persona? = nil, photoURL: URL? = nil, bio: String = "") {
    self.nickname = nickname
    self.email = email
    self.persona = persona
    self.photoURL = photoURL
    self.bio = bio
  }
}
