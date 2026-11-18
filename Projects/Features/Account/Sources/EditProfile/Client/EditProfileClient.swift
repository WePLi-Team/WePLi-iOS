import ComposableArchitecture
import Foundation
import WePLiSharedModels

// REQ-012 — 백엔드가 정해지기 전까지 저장은 목업이다(받은 값을 그대로 돌려준다).

public struct EditProfileClient {
  public var save: @Sendable (_ profile: MyProfile) async throws -> MyProfile

  public init(save: @escaping @Sendable (_ profile: MyProfile) async throws -> MyProfile) {
    self.save = save
  }
}

extension EditProfileClient: DependencyKey {
  public static let mockValue = EditProfileClient(save: { $0 })
  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  public static let liveValue = mockValue
  public static let previewValue = mockValue
  public static let testValue = EditProfileClient(save: unimplemented("EditProfileClient.save", placeholder: .mock))
}

public extension DependencyValues {
  var editProfileClient: EditProfileClient {
    get { self[EditProfileClient.self] }
    set { self[EditProfileClient.self] = newValue }
  }
}

/// 입력 규칙(UI-3e) — 글자 수는 보이는 글자(그래핌) 기준, 넘치면 잘라낸다
public enum ProfileInput {
  public static let nicknameLimit = 16
  public static let bioLimit = 50

  public static func clamp(_ text: String, to limit: Int) -> String {
    text.count > limit ? String(text.prefix(limit)) : text
  }

  public static func isValidNickname(_ text: String) -> Bool {
    !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}
