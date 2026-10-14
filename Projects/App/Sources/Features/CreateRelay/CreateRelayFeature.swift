import ComposableArchitecture
import Foundation

// REQ-036 · UI-6a · DEC-004 — 릴레이리스트 만들기(시트)

@Reducer
struct CreateRelayFeature {
  @ObservableState
  struct State: Equatable {
    var relay = NewRelay()
    var isCreating = false
    var toast: String?
    @Presents var picker: SongPickerFeature.State?

    var canCreate: Bool {
      self.relay.canCreate && !self.isCreating
    }
  }

  enum Action: Equatable {
    case cancelTapped
    case createTapped
    case topicChanged(String)
    case descriptionChanged(String)
    case coverSelected(Int)
    case addPhotoTapped
    case durationSelected(RelayDuration)
    case voteFormatSelected(CreateRelayVoteFormat)
    case audienceSelected(RelayAudience)
    case firstSongTapped
    case picker(PresentationAction<SongPickerFeature.Action>)
    case created(Relay)
    case createFailed
    case toastDismissed
    case delegate(CreateRelayDelegate)
  }

  @Dependency(\.createRelayClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .cancelTapped:
        return .send(.delegate(.dismiss))

      case .createTapped:
        guard state.canCreate else { return .none }
        state.isCreating = true
        let relay = state.relay
        return .run { send in
          do {
            try await send(.created(self.client.create(relay)))
          } catch {
            await send(.createFailed)
          }
        }

      case let .topicChanged(text):
        state.relay.topic = String(text.prefix(NewRelay.topicLimit))
        return .none

      case let .descriptionChanged(text):
        state.relay.description = String(text.prefix(NewRelay.descriptionLimit))
        return .none

      case let .coverSelected(index):
        guard (0 ..< NewRelay.coverCount).contains(index) else { return .none }
        state.relay.cover = index
        return .none

      case let .durationSelected(duration):
        state.relay.duration = duration
        return .none

      case let .voteFormatSelected(format):
        state.relay.voteFormat = format
        return .none

      case let .audienceSelected(audience):
        state.relay.audience = audience
        return .none

      case .firstSongTapped:
        // 원본에 곡 고르는 화면이 없어 게시글의 곡 검색 시트(UI-2a)를 쓴다 — 처음 고른 한 곡
        state.picker = SongPickerFeature.State()
        return .none

      case let .picker(.presented(.delegate(.add(tracks)))):
        state.picker = nil
        if let track = tracks.first {
          state.relay.firstSong = track
        }
        return .none

      case .picker(.presented(.delegate(.dismiss))):
        state.picker = nil
        return .none

      case let .created(relay):
        state.isCreating = false
        return .send(.delegate(.created(relay)))

      case .createFailed:
        state.isCreating = false
        // 원본에 없는 문구 — 디자인 확인 필요
        state.toast = "릴레이리스트를 만들지 못했어요. 다시 시도해 주세요"
        return .none

      case .toastDismissed:
        state.toast = nil
        return .none

      // 원본에 동작이 없다(사진으로 커버 추가) — 사진 선택 정책이 정해지면 잇는다
      case .addPhotoTapped, .picker, .delegate:
        return .none
      }
    }
    .ifLet(\.$picker, action: \.picker) {
      SongPickerFeature()
    }
  }
}

enum CreateRelayDelegate: Equatable {
  case dismiss
  case created(Relay)
}
