import Foundation

// REQ-033 · UI-3b

public struct VoteCandidate: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  public let artist: String
  /// 서버가 집계한 표 수(표시용)
  public let voteCount: Int

  public init(id: String, title: String, artist: String, voteCount: Int) {
    self.id = id
    self.title = title
    self.artist = artist
    self.voteCount = voteCount
  }
}

public enum VoteChoice: Equatable, Sendable {
  /// 주제와 어울려요!
  case fits
  /// 별로인 것 같아요
  case doesNotFit
}

/// 카드 드래그 규칙(UI-3b 원본 스크립트)
public enum CardSwipe {
  /// 이 거리를 넘으면 투표된다
  public static let threshold: Double = 90
  /// 투표하면 카드가 날아가는 거리
  public static let flyOutDistance: Double = 460
  /// 날아간 뒤 다음 카드까지
  public static let advanceDelay: Duration = .milliseconds(240)

  /// 회전 = dx / 18 도
  public static func rotation(for offset: Double) -> Double {
    offset / 18
  }

  /// 오른쪽(어울려요) · 왼쪽(별로예요) 도장 불투명도 = |dx| / 90 (0–1)
  public static func stampOpacity(for offset: Double, toward choice: VoteChoice) -> Double {
    let signed = choice == .fits ? offset : -offset
    return min(max(signed / self.threshold, 0), 1)
  }

  /// 손을 뗐을 때 투표할지
  public static func choice(forReleasedOffset offset: Double) -> VoteChoice? {
    if offset > self.threshold {
      return .fits
    }
    if offset < -self.threshold {
      return .doesNotFit
    }
    return nil
  }
}
