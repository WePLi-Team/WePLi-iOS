import ComposableArchitecture
import Foundation

// REQ-061 · UI-2b — 게시글 작성

@Reducer
struct ComposePostFeature {
  @ObservableState
  struct State: Equatable {
    var title = ""
    var body = ""
    var tracks: [ComposeTrack] = []
    var isPublishing = false
    var toast: String?
    @Presents var addSongDialog: ConfirmationDialogState<AddSongDialog>?
    @Presents var picker: SongPickerFeature.State?

    /// 제목과 본문이 모두 있어야 등록할 수 있다(노래는 선택)
    var canPublish: Bool {
      ComposeInput.hasText(self.title) && ComposeInput.hasText(self.body) && !self.isPublishing
    }
  }

  enum Action: Equatable {
    case titleChanged(String)
    case bodyChanged(String)
    case addSongTapped
    case addSongDialog(PresentationAction<AddSongDialog>)
    case picker(PresentationAction<SongPickerFeature.Action>)
    case removeTrackTapped(ComposeTrack.ID)
    case tracksMoved(IndexSet, Int)
    case publishButtonTapped
    case published
    case publishFailed
    case toastDismissed
    case cancelButtonTapped
    case delegate(Delegate)
  }

  /// 「노래 추가하기」 액션 시트 (UI-2b)
  enum AddSongDialog: Equatable {
    case searchSongs
    case importPlaylist
  }

  enum Delegate: Equatable {
    case dismiss
    case published
    /// 곡 추가 시트 · 플리 가져오기 (UI-9e)
    case importPlaylist
  }

  @Dependency(\.composeClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .titleChanged(text):
        state.title = text
        return .none

      case let .bodyChanged(text):
        state.body = ComposeInput.clampBody(text)
        return .none

      case .addSongTapped:
        state.addSongDialog = ConfirmationDialogState(titleVisibility: .visible) {
          TextState("노래를 어떻게 가져올까요?")
        } actions: {
          ButtonState(action: .searchSongs) { TextState("노래 검색하기") }
          ButtonState(action: .importPlaylist) { TextState("플레이리스트 가져오기") }
          ButtonState(role: .cancel) { TextState("취소") }
        }
        return .none

      case .addSongDialog(.presented(.searchSongs)):
        state.picker = SongPickerFeature.State()
        return .none

      case .addSongDialog(.presented(.importPlaylist)):
        return .send(.delegate(.importPlaylist))

      case .addSongDialog:
        return .none

      case let .picker(.presented(.delegate(.add(tracks)))):
        // 같은 곡은 한 번만(UI-2b 안내 문구)
        let existing = Set(state.tracks.map(\.id))
        state.tracks += tracks.filter { !existing.contains($0.id) }
        return .none

      case .picker(.presented(.delegate(.dismiss))):
        state.picker = nil
        return .none

      case .picker:
        return .none

      case let .removeTrackTapped(id):
        state.tracks.removeAll { $0.id == id }
        return .none

      case let .tracksMoved(source, destination):
        state.tracks.move(fromOffsets: source, toOffset: destination)
        return .none

      case .publishButtonTapped:
        guard state.canPublish else { return .none }
        state.isPublishing = true
        let draft = PostDraft(
          title: state.title.trimmingCharacters(in: .whitespacesAndNewlines),
          body: state.body.trimmingCharacters(in: .whitespacesAndNewlines),
          tracks: state.tracks
        )
        return .run { send in
          do {
            try await self.client.publish(draft)
            await send(.published)
          } catch {
            await send(.publishFailed)
          }
        }

      case .published:
        state.isPublishing = false
        return .send(.delegate(.published))

      case .publishFailed:
        state.isPublishing = false
        // 원본에 없는 문구 — 디자인 확인 필요
        state.toast = "게시글을 올리지 못했어요. 잠시 후 다시 시도해 주세요"
        return .none

      case .toastDismissed:
        state.toast = nil
        return .none

      case .cancelButtonTapped:
        return .send(.delegate(.dismiss))

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$addSongDialog, action: \.addSongDialog)
    .ifLet(\.$picker, action: \.picker) {
      SongPickerFeature()
    }
  }
}
