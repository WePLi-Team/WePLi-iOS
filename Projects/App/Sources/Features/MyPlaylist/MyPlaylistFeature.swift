import ComposableArchitecture
import Foundation

// REQ-078 · UI-10d · DEC-004 — 내 플레이리스트 · 편집
// 편집 중 바뀐 이름 · 곡 · 순서는 화면에 바로 반영되고(원본), 「완료」를 누르면 서버에 저장한다. 실패하면 편집 전으로 되돌린다.

@Reducer
struct MyPlaylistFeature {
  @ObservableState
  struct State: Equatable {
    let playlistID: String
    var playlist: MyPlaylist?
    /// 편집을 시작할 때의 값 — 저장 실패 시 되돌린다
    var beforeEdit: MyPlaylist?
    var isEditing = false
    var isSaving = false
    var loadFailed = false
    var toast: String?
    @Presents var deleteDialog: ConfirmationDialogState<MyPlaylistDeleteDialog>?

    init(playlistID: String) {
      self.playlistID = playlistID
    }
  }

  enum Action: Equatable {
    case onAppear
    case loaded(MyPlaylist)
    case loadFailed
    case retryButtonTapped
    case backButtonTapped
    case editButtonTapped
    case nameChanged(String)
    case removeTapped(ComposeTrack.ID)
    case moveUpTapped(ComposeTrack.ID)
    case moveDownTapped(ComposeTrack.ID)
    case coverTapped
    case playTapped
    case shareAsPostTapped
    case trackMenuTapped(ComposeTrack.ID)
    case deleteTapped
    case deleteDialog(PresentationAction<MyPlaylistDeleteDialog>)
    case saved(MyPlaylist)
    case saveFailed
    case deleted
    case deleteFailed
    case toastDismissed
    case delegate(MyPlaylistDelegate)
  }

  @Dependency(\.myPlaylistClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.playlist == nil else { return .none }
        return self.load(&state)

      case let .loaded(playlist):
        state.playlist = playlist
        return .none

      case .loadFailed:
        state.loadFailed = true
        return .none

      case .retryButtonTapped:
        return self.load(&state)

      case .backButtonTapped:
        return .send(.delegate(.dismiss))

      case .editButtonTapped:
        return self.toggleEditing(&state)

      case let .nameChanged(text):
        state.playlist?.name = MyPlaylist.clampName(text)
        return .none

      case let .removeTapped(id):
        state.playlist?.tracks.removeAll { $0.id == id }
        return .none

      case let .moveUpTapped(id):
        self.move(id, by: -1, in: &state)
        return .none

      case let .moveDownTapped(id):
        self.move(id, by: 1, in: &state)
        return .none

      case .shareAsPostTapped:
        guard let playlist = state.playlist else { return .none }
        return .send(.delegate(.shareAsPost(playlist.tracks)))

      case .deleteTapped:
        // 원본엔 확인 단계가 없지만 되돌릴 수 없는 동작이라 확인을 받는다(문구 확인 필요)
        state.deleteDialog = ConfirmationDialogState(titleVisibility: .visible) {
          TextState("플레이리스트를 삭제할까요?")
        } actions: {
          ButtonState(role: .destructive, action: .confirm) { TextState("플레이리스트 삭제") }
          ButtonState(role: .cancel) { TextState("취소") }
        }
        return .none

      case .deleteDialog(.presented(.confirm)):
        let id = state.playlistID
        return .run { send in
          do {
            try await self.client.delete(id)
            await send(.deleted)
          } catch {
            await send(.deleteFailed)
          }
        }

      case let .saved(playlist):
        state.isSaving = false
        state.playlist = playlist
        state.beforeEdit = nil
        return .none

      case .saveFailed:
        state.isSaving = false
        state.playlist = state.beforeEdit ?? state.playlist
        state.beforeEdit = nil
        // 원본에 없는 문구 — 디자인 확인 필요
        state.toast = "변경 사항을 저장하지 못했어요"
        return .none

      case .deleted:
        return .send(.delegate(.deleted(state.playlistID)))

      case .deleteFailed:
        state.toast = "플레이리스트를 삭제하지 못했어요"
        return .none

      case .toastDismissed:
        state.toast = nil
        return .none

      // 원본에 동작이 정해지지 않았다(커버 변경 · 재생 · 곡 메뉴) — 화면이 생기면 잇는다
      case .playTapped:
        return .send(.delegate(.play))

      case .coverTapped, .trackMenuTapped, .deleteDialog, .delegate:
        return .none
      }
    }
    .ifLet(\.$deleteDialog, action: \.deleteDialog)
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.loadFailed = false
    let id = state.playlistID
    return .run { send in
      do {
        try await send(.loaded(self.client.fetch(id)))
      } catch {
        await send(.loadFailed)
      }
    }
  }

  private func toggleEditing(_ state: inout State) -> Effect<Action> {
    guard var playlist = state.playlist, !state.isSaving else { return .none }
    if !state.isEditing {
      state.isEditing = true
      state.beforeEdit = playlist
      return .none
    }
    state.isEditing = false
    // 이름을 비우면 원래 이름으로 둔다(원본에 규칙 없음)
    if playlist.name.trimmingCharacters(in: .whitespaces).isEmpty, let before = state.beforeEdit {
      playlist.name = before.name
      state.playlist = playlist
    }
    guard playlist != state.beforeEdit else {
      state.beforeEdit = nil
      return .none
    }
    state.isSaving = true
    return .run { [playlist] send in
      do {
        try await send(.saved(self.client.save(playlist)))
      } catch {
        await send(.saveFailed)
      }
    }
  }

  /// ▲▼ — 이웃 곡과 자리를 바꾼다. 맨 위 · 맨 아래에서는 아무 일도 없다(원본)
  private func move(_ id: ComposeTrack.ID, by offset: Int, in state: inout State) {
    guard var tracks = state.playlist?.tracks, let index = tracks.firstIndex(where: { $0.id == id }) else { return }
    let target = index + offset
    guard tracks.indices.contains(target) else { return }
    tracks.swapAt(index, target)
    state.playlist?.tracks = tracks
  }
}

enum MyPlaylistDeleteDialog: Equatable {
  case confirm
}

enum MyPlaylistDelegate: Equatable {
  case dismiss
  case deleted(MyPlaylist.ID)
  /// 게시글로 공유 → 이 플리의 곡을 담은 게시글 작성(UI-2b)
  case shareAsPost([ComposeTrack])
  /// 재생 → 미리듣기 플레이어(UI-4b)
  case play
}
