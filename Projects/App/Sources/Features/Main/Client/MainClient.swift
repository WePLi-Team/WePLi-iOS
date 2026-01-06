import ComposableArchitecture
import Foundation

// MARK: - MainClient

struct MainClient {
  var fetchMainData: @Sendable () async -> MainData
}

// MARK: - DependencyKey

extension MainClient: DependencyKey {
  static let liveValue = MainClient(
    fetchMainData: {
      // TODO: Implement actual API call
      try? await Task.sleep(nanoseconds: 500000000)
      return .mock
    }
  )

  static let testValue = MainClient(
    fetchMainData: { .mock }
  )

  static let previewValue = MainClient(
    fetchMainData: { .mock }
  )
}

// MARK: - DependencyValues

extension DependencyValues {
  var mainClient: MainClient {
    get { self[MainClient.self] }
    set { self[MainClient.self] = newValue }
  }
}
