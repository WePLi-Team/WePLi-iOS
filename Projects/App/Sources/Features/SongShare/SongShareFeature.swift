import ComposableArchitecture
import Foundation

// REQ-066 · UI-3g — 곡 공유 카드
// 공유 대상(스토리 · 링크 · 이미지 · 더보기)은 아이콘 줄, 앱 안의 동작(게시글 · 플리 추가)은 아래 목록(원본 노트 02)

@Reducer
struct SongShareFeature {
  @ObservableState
  struct State: Equatable {
    let card: SongShareCard
    var systemShare: SystemShareItem?
    var toast: String?
    var shareCount = 0
  }

  enum Action: Equatable {
    case closeButtonTapped
    /// 카드 이미지는 화면이 그려서 넘긴다(ImageRenderer)
    case storyTapped(image: Data?)
    case copyLinkTapped
    case linkCopied
    case linkFailed
    case saveImageTapped(image: Data?)
    case imageSaved
    case imageSaveFailed(SongShareError?)
    case moreTapped(image: Data?)
    case systemShareReady(image: Data, link: URL?)
    case systemShareDismissed
    case shareAsPostTapped
    case addToPlaylistTapped
    case toastDismissed
    case delegate(SongShareDelegate)
  }

  @Dependency(\.songShareClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .closeButtonTapped:
        return .send(.delegate(.dismiss))

      case let .storyTapped(image):
        // 미결정 — Instagram 스토리 직접 공유는 Facebook App ID가 필요하다. 그 전까지 시스템 공유 시트로 넘긴다.
        guard let image else { return .none }
        return .send(.systemShareReady(image: image, link: nil))

      case .copyLinkTapped:
        let songID = state.card.songID
        return .run { send in
          do {
            let url = try await self.client.link(songID)
            await self.client.copy(url)
            await send(.linkCopied)
          } catch {
            await send(.linkFailed)
          }
        }

      case .linkCopied:
        // 원본에 없는 문구 — 디자인 확인 필요
        state.toast = "링크를 복사했어요"
        return .none

      case .linkFailed:
        state.toast = "링크를 만들지 못했어요"
        return .none

      case let .saveImageTapped(image):
        guard let image else { return .none }
        return .run { send in
          do {
            try await self.client.saveImage(image)
            await send(.imageSaved)
          } catch {
            await send(.imageSaveFailed(error as? SongShareError))
          }
        }

      case .imageSaved:
        state.toast = "이미지를 저장했어요"
        return .none

      case let .imageSaveFailed(error):
        state.toast = error == .photoAccessDenied ? "사진 접근을 허용하면 저장할 수 있어요" : "이미지를 저장하지 못했어요"
        return .none

      case let .moreTapped(image):
        guard let image else { return .none }
        let songID = state.card.songID
        return .run { send in
          let url = try? await self.client.link(songID)
          await send(.systemShareReady(image: image, link: url))
        }

      case let .systemShareReady(image, link):
        state.shareCount += 1
        state.systemShare = SystemShareItem(id: state.shareCount, image: image, link: link)
        return .none

      case .systemShareDismissed:
        state.systemShare = nil
        return .none

      case .shareAsPostTapped:
        return .send(.delegate(.shareAsPost(songID: state.card.songID)))

      case .addToPlaylistTapped:
        return .send(.delegate(.addToPlaylist(songID: state.card.songID)))

      case .toastDismissed:
        state.toast = nil
        return .none

      case .delegate:
        return .none
      }
    }
  }
}

enum SongShareDelegate: Equatable {
  case dismiss
  /// 게시글로 공유하기 → 게시글 작성
  case shareAsPost(songID: String)
  /// 내 플레이리스트에 추가하기 → 플리 추가
  case addToPlaylist(songID: String)
}
