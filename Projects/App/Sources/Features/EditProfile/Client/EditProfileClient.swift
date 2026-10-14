import ComposableArchitecture
import Foundation

// REQ-012 — 백엔드가 정해지기 전까지 저장은 목업이다(받은 값을 그대로 돌려준다).

struct EditProfileClient {
  var save: @Sendable (_ profile: MyProfile) async throws -> MyProfile
}

extension EditProfileClient: DependencyKey {
  static let liveValue = EditProfileClient(save: { $0 })
  static let previewValue = liveValue
  static let testValue = EditProfileClient(save: unimplemented("EditProfileClient.save", placeholder: .mock))
}

extension DependencyValues {
  var editProfileClient: EditProfileClient {
    get { self[EditProfileClient.self] }
    set { self[EditProfileClient.self] = newValue }
  }
}

/// 입력 규칙(UI-3e) — 글자 수는 보이는 글자(그래핌) 기준, 넘치면 잘라낸다
enum ProfileInput {
  static let nicknameLimit = 16
  static let bioLimit = 50

  static func clamp(_ text: String, to limit: Int) -> String {
    text.count > limit ? String(text.prefix(limit)) : text
  }

  static func isValidNickname(_ text: String) -> Bool {
    !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}
