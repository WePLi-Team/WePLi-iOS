import ComposableArchitecture
import Foundation

// DEC-007 — 탭 스택 안의 화면이 다음 화면을 열 때. 어느 탭에서 열렸든 같은 탭 스택에 push한다.
// 곡 상세(UI-2d) · 아티스트(UI-5b) · 플리 상세(UI-3d) · 게시글 상세(UI-2c) · 보관함(UI-5c) · 내 플리(UI-10d) · 릴레이 상세(UI-3c)

struct ContentNavigation: Reducer {
  typealias State = MainTabFeature.State
  typealias Action = MainTabFeature.Action
  typealias Path = MainTabFeature.Path

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      guard let (source, action) = action.pathElement else { return .none }
      if Self.isDismiss(action) {
        state[stack: source.tab].pop(from: source.id)
        return .none
      }
      let next = self.music(action, source, state) ?? self.relay(action, source, state)
        ?? self.notice(action, source, state)
      if let next {
        state[stack: source.tab].append(next)
        return .none
      }
      if case let .topPrediction(.delegate(.predicted(relayID, optionID))) = action {
        Self.markHomePrediction(relayID: relayID, optionID: optionID, &state)
        return .none
      }
      if case .appInfo(.delegate(.developerModeEnabled)) = action {
        // 마이 「기타」에 개발자 모드 행을 보인다(UI-7g 노트 02)
        state.my.isDeveloperModeEnabled = true
        return .none
      }
      return self.mine(action, source, &state)
    }
  }

  /// 뒤로 — 모든 화면 공통
  static func isDismiss(_ action: Path.Action) -> Bool {
    switch action {
    case .relayDetail(.delegate(.dismiss)), .vote(.delegate(.dismiss)), .worldCup(.delegate(.dismiss)),
         .myRecommendation(.delegate(.dismiss)), .topPrediction(.delegate(.dismiss)),
         .completedPlaylist(.delegate(.dismiss)), .exportedPlaylist(.delegate(.dismiss)),
         .notifications(.delegate(.dismiss)),
         .postDetail(.delegate(.dismiss)), .editProfile(.delegate(.dismiss)), .library(.delegate(.dismiss)),
         .notificationSettings(.delegate(.dismiss)), .musicServices(.delegate(.dismiss)),
         .notices(.delegate(.dismiss)), .appInfo(.delegate(.dismiss)),
         .myPlaylist(.delegate(.dismiss)),
         .songDetail(.delegate(.dismiss)), .artist(.delegate(.dismiss)), .playlistDetail(.delegate(.dismiss)):
      true
    default:
      false
    }
  }

  /// 곡 · 아티스트 · 플리 · 게시글 사이 이동
  private func music(_ action: Path.Action, _ source: PathSource, _ state: State) -> Path.State? {
    switch action {
    case .songDetail(.delegate(.showArtist)):
      // 곡 상세의 가수 이름 → 아티스트(5b 노트 01)
      let song = state[stack: source.tab][id: source.id, case: \.songDetail]?.song
      return song.map { .artist(ArtistFeature.State(artistID: $0.artist)) }
    case let .songDetail(.delegate(.showSong(id))),
         let .completedPlaylist(.delegate(.showSong(id))),
         let .artist(.delegate(.showSong(id))),
         let .playlistDetail(.delegate(.showTrack(id))):
      return .songDetail(SongDetailFeature.State(songID: id))
    case let .library(.delegate(.showSong(title))):
      return .songDetail(SongDetailFeature.State(songID: title))
    case let .artist(.delegate(.showArtist(name))),
         let .playlistDetail(.delegate(.showArtist(name))):
      return .artist(ArtistFeature.State(artistID: name))
    case let .artist(.delegate(.showPlaylist(id))):
      return .playlistDetail(PlaylistDetailFeature.State(playlistID: id))
    case let .artist(.delegate(.showPost(id))),
         let .library(.delegate(.showPost(id))):
      return .postDetail(PostDetailFeature.State(postID: id))
    default:
      return nil
    }
  }

  /// 릴레이 상세 · 투표
  private func relay(_ action: Path.Action, _ source: PathSource, _ state: State) -> Path.State? {
    let stack = state[stack: source.tab]
    switch action {
    case let .relayDetail(.delegate(.showVote(relayID))):
      // 상세 제목은 줄바꿈이 있어 투표 화면 주제에서는 한 줄로 보인다
      let detail = stack[id: source.id, case: \.relayDetail]?.detail
      let topic = (detail?.title ?? "").replacingOccurrences(of: "\n", with: " ")
      // 투표 방식은 릴레이를 만들 때 정한다(6a) — 곡 월드컵이면 8b, 아니면 카드 넘기기(3b)
      if detail?.voteFormat == .worldCup {
        return .worldCup(SongWorldCupFeature.State(relayID: relayID, topic: topic))
      }
      return .vote(CardVoteFeature.State(relayID: relayID, topic: topic))
    case let .library(.delegate(.continueVoting(relayID))):
      let topic = stack[id: source.id, case: \.library]?.library?.liveRelays.first { $0.id == relayID }?.title ?? ""
      return .vote(CardVoteFeature.State(relayID: relayID, topic: topic))
    case let .library(.delegate(.showRelay(id))):
      return .relayDetail(RelayDetailFeature.State(relayID: id))
    case let .library(.delegate(.showPlaylist(id))):
      // 보관함 「내 플레이리스트」 → 내 플레이리스트 · 편집(UI-10d)
      return .myPlaylist(MyPlaylistFeature.State(playlistID: id))
    default:
      return nil
    }
  }

  /// 알림 → 알림 종류에 맞는 화면 · 완성 플리 → 비슷한 플리 · 음악 서비스 → 내보낸 플리
  private func notice(_ action: Path.Action, _ source: PathSource, _ state: State) -> Path.State? {
    let stack = state[stack: source.tab]
    switch action {
    case let .notifications(.delegate(.open(id))):
      // 「내 추천곡 순위 변동」 → 내 추천곡(UI-8a) · 완성 알림 → 완성 플리(UI-14b) · 마감 알림 → 릴레이 상세
      guard let notice = stack[id: source.id, case: \.notifications]?.notifications[id: id],
            let relayID = notice.relayID
      else { return nil }
      switch notice.kind {
      case .rankChanged: return .myRecommendation(MyRecommendationFeature.State(relayID: relayID))
      case .relayCompleted: return .completedPlaylist(CompletedPlaylistFeature.State(relayID: relayID))
      default: return .relayDetail(RelayDetailFeature.State(relayID: relayID))
      }
    case let .musicServices(.delegate(.showExported(id))):
      // 「내보낸 플레이리스트」 한 줄 → 내보낸 플리(UI-14m)
      return .exportedPlaylist(ExportedPlaylistFeature.State(playlistID: id))
    case let .completedPlaylist(.delegate(.showPlaylist(id))):
      return .completedPlaylist(CompletedPlaylistFeature.State(relayID: id))
    default:
      return nil
    }
  }

  /// 내 정보 · 내 플리 · 노래로 답하기 — 화면을 열지 않고 상태를 바꾼다
  private func mine(_ action: Path.Action, _ source: PathSource, _ state: inout State) -> Effect<Action> {
    switch action {
    case let .editProfile(.delegate(.profileUpdated(profile))):
      // 저장하면 마이 탭 프로필 카드에 바로 반영한다
      state.my.profile = profile
    case let .myPlaylist(.delegate(.deleted(playlistID))):
      state[stack: source.tab].pop(from: source.id)
      // 지운 플리는 보관함 목록에서도 뺀다
      for id in state[stack: source.tab].ids {
        state[stack: source.tab][id: id, case: \.library]?.library?.playlists.removeAll { $0.id == playlistID }
      }
    case let .myPlaylist(.delegate(.shareAsPost(tracks))):
      state.compose = ComposePostFeature.State(tracks: tracks)
    case let .completedPlaylist(.delegate(.songMenu(song))):
      state.songMenuSource = nil
      state.songMenu = SongMenuFeature.State(
        songID: song.id,
        title: song.title,
        artist: song.artist,
        isLiked: false,
        savesLike: true
      )
    case .completedPlaylist(.delegate(.export)):
      // 이미 담은 플리면 기존 플리를 맞출지 새로 만들지 먼저 묻는다(14n)
      guard let playlist = state[stack: source.tab][id: source.id, case: \.completedPlaylist]?.playlist else { break }
      state.exportFlow = ExportFlowFeature.State(playlist)
    case .relayDetail(.delegate(.export)):
      self.exportRelay(source, &state)
    case .postDetail(.delegate(.pickReplySong)):
      state.replySongTarget = source
      state.replySongPicker = SongPickerFeature.State()
    default:
      break
    }
    return .none
  }

  /// 릴레이 상세 「내 음악 앱으로」 — 완성됐으면 내보내기(14c), 진행 중이면 지금 순위로 먼저 담기(14l)
  private func exportRelay(_ source: PathSource, _ state: inout State) {
    guard let relay = state[stack: source.tab][id: source.id, case: \.relayDetail],
          let detail = relay.detail
    else { return }
    let title = detail.title.replacingOccurrences(of: "\n", with: " ")
    let songs = detail.ranking.map { ExportSong(id: $0.id, title: $0.title, artist: $0.artist, recommender: "") }
    if let endsAt = detail.endsAt, relay.displayState != .completed {
      state.liveExportSource = source
      state.liveExport = LiveExportFeature.State(relayID: detail.id, title: title, endsAt: endsAt, songs: songs)
    } else {
      state.exportFlow = ExportFlowFeature.State(
        relayID: detail.id,
        title: title,
        recommenderCount: detail.participantCount,
        songs: songs
      )
    }
  }

  /// 1위 예측을 확정하면 홈 1위 예측도 「예측 완료」로 — 같은 릴레이 · 같은 곡이 홈 후보에 있을 때
  private static func markHomePrediction(relayID: String, optionID: String, _ state: inout State) {
    guard let prediction = state.home.feed?.prediction, prediction.relayID == relayID else { return }
    guard prediction.options.contains(where: { $0.id == optionID }) else { return }
    state.home.feed?.prediction?.pickedID = optionID
  }
}
