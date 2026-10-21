import ComposableArchitecture
import Foundation

// REQ-023 · UI-1b 곡 메뉴 시트 — 묶음 3개(탐색 · 공유 · 정보). 묶음 제목은 화면에 보이지 않는다.

/// 곡 메뉴 행
enum SongMenuItem: CaseIterable, Equatable, Sendable {
  case artist
  case lyrics
  case addToPlaylist
  case shareAsPost
  case instagram
  case link
  case screenshot
  case info

  static let groups: [[SongMenuItem]] = [
    [.artist, .lyrics, .addToPlaylist],
    [.shareAsPost, .instagram, .link, .screenshot],
    [.info],
  ]

  var title: String {
    switch self {
    case .artist: "아티스트 정보 보기"
    case .lyrics: "가사 보기"
    case .addToPlaylist: "내 플레이리스트에 추가하기"
    case .shareAsPost: "게시글로 공유하기"
    case .instagram: "인스타그램으로 공유하기"
    case .link: "링크로 공유하기"
    case .screenshot: "스크린샷으로 저장"
    case .info: "곡 정보"
    }
  }
}

@Reducer
struct SongMenuFeature {
  @ObservableState
  struct State: Equatable {
    let songID: String
    let title: String
    let artist: String
    var isLiked: Bool
    var toast: String?
    /// 곡 상세 없이 연 시트(홈 TOP 100 ···)는 좋아요를 직접 저장한다
    var savesLike = false
  }

  enum Action: Equatable {
    case likeButtonTapped
    case likeFailed(restore: Bool)
    case closeButtonTapped
    case itemTapped(SongMenuItem)
    case linkCopied
    case linkFailed
    case toastDismissed
    case delegate(SongMenuDelegate)
  }

  @Dependency(\.songShareClient)
  var shareClient

  @Dependency(\.songDetailClient)
  var songDetailClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .likeButtonTapped:
        // 서버 저장 · 되돌리기는 곡 상세가 한다(같은 곡의 좋아요 하나). 시트는 바로 바꿔 보여 준다.
        state.isLiked.toggle()
        guard state.savesLike else { return .send(.delegate(.toggleLike)) }
        let (id, isLiked) = (state.songID, state.isLiked)
        return .run { send in
          do {
            try await self.songDetailClient.setLiked(id, isLiked)
          } catch {
            await send(.likeFailed(restore: !isLiked))
          }
        }

      case let .likeFailed(restore):
        state.isLiked = restore
        return .none

      case .closeButtonTapped:
        return .send(.delegate(.dismiss))

      case .itemTapped(.link):
        let songID = state.songID
        return .run { send in
          do {
            let url = try await self.shareClient.link(songID)
            await self.shareClient.copy(url)
            await send(.linkCopied)
          } catch {
            await send(.linkFailed)
          }
        }

      case let .itemTapped(item):
        return .send(.delegate(.selected(item)))

      case .linkCopied:
        // 원본에 없는 문구 — 공유 카드(UI-3g)와 같은 임시 문구, 디자인 확인 필요
        state.toast = "링크를 복사했어요"
        return .none

      case .linkFailed:
        state.toast = "링크를 만들지 못했어요"
        return .none

      case .toastDismissed:
        state.toast = nil
        return .none

      case .delegate:
        return .none
      }
    }
  }
}

enum SongMenuDelegate: Equatable {
  case dismiss
  case toggleLike
  /// 링크 복사를 뺀 나머지 행 — 목적지는 부모가 정한다
  case selected(SongMenuItem)
}
