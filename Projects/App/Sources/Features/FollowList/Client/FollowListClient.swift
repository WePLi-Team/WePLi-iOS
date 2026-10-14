import ComposableArchitecture
import Foundation

// REQ-074 · DEC-004 — 백엔드가 정해지기 전까지 원본(UI-10c) 예시를 돌려주는 목업이다.

struct FollowUser: Equatable, Identifiable, Sendable {
  var id: String {
    self.name
  }

  let name: String
  let persona: Persona
  /// 이 사람이 나를 팔로우한다
  let followsMe: Bool
  /// 내가 이 사람을 팔로우한다
  var isFollowing: Bool
}

struct FollowLists: Equatable, Sendable {
  var followerCount: Int
  var followingCount: Int
  var followers: [FollowUser]
  var following: [FollowUser]
}

struct FollowListClient {
  var fetch: @Sendable (_ userName: String) async throws -> FollowLists
  var setFollowing: @Sendable (_ userName: String, _ isFollowing: Bool) async throws -> Void
}

extension FollowListClient: DependencyKey {
  static let liveValue = FollowListClient(fetch: { _ in .mock }, setFollowing: { _, _ in })
  static let previewValue = liveValue
  static let testValue = FollowListClient(
    fetch: unimplemented("FollowListClient.fetch", placeholder: .mock),
    setFollowing: unimplemented("FollowListClient.setFollowing")
  )
}

extension DependencyValues {
  var followListClient: FollowListClient {
    get { self[FollowListClient.self] }
    set { self[FollowListClient.self] = newValue }
  }
}

extension FollowLists {
  /// 원본 예시 — 팔로워 1,284 · 팔로잉 312(목록은 앞부분)
  static let mock: FollowLists = {
    let people = [
      FollowUser(name: "chuuuuu__", persona: .sentimentalSymphony, followsMe: true, isFollowing: true),
      FollowUser(name: "roykim", persona: .melodyMemories, followsMe: true, isFollowing: false),
      FollowUser(name: "minnie._.", persona: .socialTunes, followsMe: true, isFollowing: true),
      FollowUser(name: "woogi", persona: .energyFlash, followsMe: true, isFollowing: false),
      FollowUser(name: "dlwlrma", persona: .nostalgiaSeoner, followsMe: false, isFollowing: false),
      FollowUser(name: "younha_holic", persona: .sentimentalSymphony, followsMe: false, isFollowing: true),
    ]
    return FollowLists(
      followerCount: 1284,
      followingCount: 312,
      followers: people.filter(\.followsMe),
      following: people.filter(\.isFollowing)
    )
  }()
}
