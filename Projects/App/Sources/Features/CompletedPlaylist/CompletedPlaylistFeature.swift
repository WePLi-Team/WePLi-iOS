import ComposableArchitecture
import Foundation

// REQ-040 · UI-14b · DEC-004 — 완성 플리 · 기준 화면
// 좋아요 · 저장 · 다음 릴레이 알림은 먼저 반영하고 실패하면 되돌린다.

@Reducer
struct CompletedPlaylistFeature {
  @ObservableState
  struct State: Equatable {
    let relayID: String
    var playlist: CompletedPlaylist?
    var loadFailed = false
    var toast: String?

    init(relayID: String) {
      self.relayID = relayID
    }
  }

  enum Action: Equatable {
    case onAppear
    case loaded(CompletedPlaylist)
    case loadFailed
    case retryButtonTapped
    case backButtonTapped
    case likeTapped
    case saveTapped
    case nextRelayAlertTapped
    case toggleFailed(CompletedPlaylistToggle, restore: Bool)
    case exportTapped
    case playAllTapped
    case songTapped(CompletedPlaylist.Song.ID)
    case songMoreTapped(CompletedPlaylist.Song.ID)
    case similarTapped(SimilarPlaylist.ID)
    case moreTapped
    case commentsTapped
    case shareTapped
    case toastDismissed
    case delegate(CompletedPlaylistDelegate)
  }

  @Dependency(\.completedPlaylistClient)
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

      case .likeTapped, .saveTapped, .nextRelayAlertTapped:
        return self.toggle(action, &state)

      case let .toggleFailed(toggle, restore):
        self.apply(toggle, restore, &state)
        // 원본에 없는 문구 — 디자인 확인 필요
        state.toast = "잠시 후 다시 시도해 주세요"
        return .none

      case let .songTapped(id):
        return .send(.delegate(.showSong(id)))

      case let .songMoreTapped(id):
        guard let song = state.playlist?.ranking.first(where: { $0.id == id }) else { return .none }
        return .send(.delegate(.songMenu(ComposeTrack(id: song.id, title: song.title, artist: song.artist))))

      case let .similarTapped(id):
        return .send(.delegate(.showPlaylist(id)))

      case .exportTapped:
        return .send(.delegate(.export(relayID: state.relayID)))

      case .toastDismissed:
        state.toast = nil
        return .none

      // 원본에 목적지가 없다(전체듣기 · 더보기 · 댓글 · 공유) — 재생 · 화면이 생기면 잇는다
      case .playAllTapped, .moreTapped, .commentsTapped, .shareTapped, .delegate:
        return .none
      }
    }
  }

  private func toggle(_ action: Action, _ state: inout State) -> Effect<Action> {
    guard let playlist = state.playlist else { return .none }
    let toggle: CompletedPlaylistToggle
    let isOn: Bool
    switch action {
    case .likeTapped:
      (toggle, isOn) = (.like, !playlist.isLiked)
    case .saveTapped:
      (toggle, isOn) = (.save, !playlist.isSaved)
    default:
      guard playlist.nextRelay != nil else { return .none }
      (toggle, isOn) = (.nextRelayAlert, !playlist.isNextRelayAlertOn)
    }
    self.apply(toggle, isOn, &state)
    let relayID = state.relayID
    let nextID = playlist.nextRelay?.id ?? ""
    return .run { send in
      do {
        switch toggle {
        case .like: try await self.client.setLiked(relayID, isOn)
        case .save: try await self.client.setSaved(relayID, isOn)
        case .nextRelayAlert: try await self.client.setNextRelayAlert(nextID, isOn)
        }
      } catch {
        await send(.toggleFailed(toggle, restore: !isOn))
      }
    }
  }

  private func apply(_ toggle: CompletedPlaylistToggle, _ isOn: Bool, _ state: inout State) {
    guard var playlist = state.playlist else { return }
    switch toggle {
    case .like:
      guard playlist.isLiked != isOn else { return }
      playlist.isLiked = isOn
      playlist.likeCount += isOn ? 1 : -1
    case .save:
      playlist.isSaved = isOn
    case .nextRelayAlert:
      playlist.isNextRelayAlertOn = isOn
    }
    state.playlist = playlist
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.loadFailed = false
    let id = state.relayID
    return .run { send in
      do {
        try await send(.loaded(self.client.fetch(id)))
      } catch {
        await send(.loadFailed)
      }
    }
  }
}

enum CompletedPlaylistToggle: Equatable, Sendable {
  case like
  case save
  case nextRelayAlert
}

enum CompletedPlaylistDelegate: Equatable {
  case dismiss
  case showSong(String)
  case songMenu(ComposeTrack)
  case showPlaylist(String)
  /// 내 음악 앱으로 내보내기 → 어디로 담을까요(UI-14c) — 14차 흐름이 생기면 잇는다
  case export(relayID: String)
}
