import ComposableArchitecture
import Foundation
import WePLiSharedModels

// REQ-074 · DEC-004 — 백엔드가 정해지기 전까지 원본(UI-10c) 예시를 돌려주는 목업이다.

public struct FollowUser: Equatable, Identifiable, Sendable {
  public var id: String {
    self.name
  }

  public let name: String
  public let persona: Persona
  /// 이 사람이 나를 팔로우한다
  public let followsMe: Bool
  /// 내가 이 사람을 팔로우한다
  public var isFollowing: Bool

  public init(name: String, persona: Persona, followsMe: Bool, isFollowing: Bool) {
    self.name = name
    self.persona = persona
    self.followsMe = followsMe
    self.isFollowing = isFollowing
  }
}

public struct FollowLists: Equatable, Sendable {
  public var followerCount: Int
  public var followingCount: Int
  public var followers: [FollowUser]
  public var following: [FollowUser]

  public init(followerCount: Int, followingCount: Int, followers: [FollowUser], following: [FollowUser]) {
    self.followerCount = followerCount
    self.followingCount = followingCount
    self.followers = followers
    self.following = following
  }
}

public struct FollowListClient {
  public var fetch: @Sendable (_ userName: String) async throws -> FollowLists
  public var setFollowing: @Sendable (_ userName: String, _ isFollowing: Bool) async throws -> Void

  public init(
    fetch: @escaping @Sendable (_ userName: String) async throws -> FollowLists,
    setFollowing: @escaping @Sendable (_ userName: String, _ isFollowing: Bool) async throws -> Void
  ) {
    self.fetch = fetch
    self.setFollowing = setFollowing
  }
}

extension FollowListClient: DependencyKey {
  public static let mockValue = FollowListClient(fetch: { _ in .mock }, setFollowing: { _, _ in })
  /// 실제 API를 붙이기 전까지 목업(백엔드 미정 · AGENTS.md) — 붙이면 이 줄만 바꾼다
  public static let liveValue = mockValue
  public static let previewValue = mockValue
  public static let testValue = FollowListClient(
    fetch: unimplemented("FollowListClient.fetch", placeholder: .mock),
    setFollowing: unimplemented("FollowListClient.setFollowing")
  )
}

public extension DependencyValues {
  var followListClient: FollowListClient {
    get { self[FollowListClient.self] }
    set { self[FollowListClient.self] = newValue }
  }
}

public extension FollowLists {
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
