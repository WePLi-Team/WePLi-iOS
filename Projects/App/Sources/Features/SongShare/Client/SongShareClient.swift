import ComposableArchitecture
import Foundation
import Photos
import UIKit

// REQ-066 · UI-3g — 공유 링크 · 클립보드 · 사진 앱 저장

enum SongShareError: Error, Equatable {
  /// 사진 앱 접근을 허용하지 않음
  case photoAccessDenied
}

struct SongShareClient {
  var link: @Sendable (_ songID: String) async throws -> URL
  var copy: @Sendable (_ url: URL) async -> Void
  var saveImage: @Sendable (_ png: Data) async throws -> Void
}

extension SongShareClient: DependencyKey {
  /// 미결정 — 공유 링크 도메인(Universal Links). 정해지기 전까지 예약 도메인을 쓴다.
  static let linkBase = URL(string: "https://wepli.example/songs")

  static let liveValue = SongShareClient(
    link: { songID in
      guard let url = linkBase?.appendingPathComponent(songID) else { throw URLError(.badURL) }
      return url
    },
    copy: { url in
      await MainActor.run { UIPasteboard.general.url = url }
    },
    saveImage: { png in
      let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
      guard status == .authorized || status == .limited else { throw SongShareError.photoAccessDenied }
      try await PHPhotoLibrary.shared().performChanges {
        PHAssetCreationRequest.forAsset().addResource(with: .photo, data: png, options: nil)
      }
    }
  )

  static let previewValue = SongShareClient(
    link: { URL(string: "https://wepli.example/songs/\($0)") ?? URL(fileURLWithPath: "/") },
    copy: { _ in },
    saveImage: { _ in }
  )

  static let testValue = SongShareClient(
    link: unimplemented("SongShareClient.link", placeholder: URL(fileURLWithPath: "/")),
    copy: unimplemented("SongShareClient.copy"),
    saveImage: unimplemented("SongShareClient.saveImage")
  )
}

extension DependencyValues {
  var songShareClient: SongShareClient {
    get { self[SongShareClient.self] }
    set { self[SongShareClient.self] = newValue }
  }
}
