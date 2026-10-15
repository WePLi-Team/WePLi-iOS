import ComposableArchitecture
import Foundation

// REQ-022 — 화면의 재생 버튼 → 미리듣기 플레이어(UI-4b). 화면에 보이는 곡 목록을 대기열로 쓴다.
// 릴레이 상세 전체 듣기 · 곡 재생(UI-3c), 완성 플리 전체 듣기(UI-14b), 플리 상세 재생 · 셔플(UI-3d),
// 아티스트 인기곡(UI-5b), 카드 투표 미리듣기(UI-3b), 내 플리(UI-10d), 게시글 첨부 곡(UI-2c)

struct PlaybackNavigation: Reducer {
  typealias State = MainTabFeature.State
  typealias Action = MainTabFeature.Action

  @Dependency(\.withRandomNumberGenerator)
  var withRandomNumberGenerator

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      guard let (source, action) = action.pathElement,
            let screen = state[stack: source.tab][id: source.id],
            let request = self.request(action, screen) ?? self.mine(action, screen)
      else { return .none }
      return .send(.player(.play(queue: request.queue, startAt: request.startAt, source: request.source)))
    }
  }

  private struct Request {
    let queue: [PlayerTrack]
    var startAt = 0
    let source: String?
  }

  private func request(_ action: MainTabFeature.Path.Action, _ screen: MainTabFeature.Path.State) -> Request? {
    switch (action, screen) {
    case let (.relayDetail(.delegate(.playAll)), .relayDetail(relay)),
         let (.relayDetail(.delegate(.playSong)), .relayDetail(relay)):
      guard let detail = relay.detail else { return nil }
      let queue = detail.ranking.map { PlayerTrack(id: $0.id, title: $0.title, artist: $0.artist) }
      var startAt = 0
      if case let .relayDetail(.delegate(.playSong(id))) = action {
        startAt = queue.firstIndex { $0.id == id } ?? 0
      }
      return Request(queue: queue, startAt: startAt, source: Self.oneLine(detail.title))
    case let (.completedPlaylist(.delegate(.playAll)), .completedPlaylist(completed)):
      guard let playlist = completed.playlist else { return nil }
      let queue = playlist.ranking.map { PlayerTrack(id: $0.id, title: $0.title, artist: $0.artist) }
      return Request(queue: queue, source: Self.oneLine(playlist.title))
    case let (.playlistDetail(.delegate(.play(_, shuffled))), .playlistDetail(detail)):
      guard let playlist = detail.playlist else { return nil }
      var queue = playlist.tracks.map { PlayerTrack(id: $0.id, title: $0.title, artist: $0.artist) }
      if shuffled {
        self.withRandomNumberGenerator { queue.shuffle(using: &$0) }
      }
      return Request(queue: queue, source: playlist.title)
    default:
      return nil
    }
  }

  /// 아티스트 · 카드 투표 · 내 플리 · 게시글
  private func mine(_ action: MainTabFeature.Path.Action, _ screen: MainTabFeature.Path.State) -> Request? {
    switch (action, screen) {
    case let (.artist(.delegate(.playAll)), .artist(artist)):
      guard let detail = artist.artist else { return nil }
      let queue = detail.popularSongs.map {
        PlayerTrack(id: "\($0.title)|\(detail.name)", title: $0.title, artist: detail.name)
      }
      return Request(queue: queue, source: detail.name)
    case let (.vote(.delegate(.playPreview(id))), .vote(vote)):
      // 카드 한 장의 미리듣기 — 다음 곡은 없다
      guard let candidate = vote.candidates.first(where: { $0.id == id }) else { return nil }
      let track = PlayerTrack(id: candidate.id, title: candidate.title, artist: candidate.artist)
      return Request(queue: [track], source: vote.topic)
    case let (.myPlaylist(.delegate(.play)), .myPlaylist(owned)):
      guard let playlist = owned.playlist else { return nil }
      let queue = playlist.tracks.map { PlayerTrack(id: $0.id, title: $0.title, artist: $0.artist) }
      return Request(queue: queue, source: playlist.name)
    case let (.liveTrend(.delegate(.play(song))), _):
      let track = PlayerTrack(id: song.id, title: song.title, artist: song.artist)
      return Request(queue: [track], source: "지금 위플리")
    case let (.postDetail(.delegate(.play)), .postDetail(detail)):
      return detail.post.flatMap { Self.attachment($0.attachment) }
    default:
      return nil
    }
  }

  private static func attachment(_ attachment: Post.Attachment) -> Request? {
    let tracks: [Track] = switch attachment {
    case .none: []
    case let .song(track): [track]
    case let .playlist(tracks): tracks
    }
    guard !tracks.isEmpty else { return nil }
    let queue = tracks.map { PlayerTrack(id: "\($0.title)|\($0.artist)", title: $0.title, artist: $0.artist) }
    return Request(queue: queue, source: nil)
  }

  private static func oneLine(_ title: String) -> String {
    title.replacingOccurrences(of: "\n", with: " ")
  }
}
