import ComposableArchitecture
import Foundation

// REQ-022 — 화면의 재생 버튼 → 미리듣기 플레이어(UI-4b). 화면에 보이는 곡 목록을 대기열로 쓴다.
// 릴레이 상세 전체 듣기 · 곡 재생(UI-3c), 완성 플리 전체 듣기(UI-14b), 플리 상세 재생 · 셔플(UI-3d)

struct PlaybackNavigation: Reducer {
  typealias State = MainTabFeature.State
  typealias Action = MainTabFeature.Action

  @Dependency(\.withRandomNumberGenerator)
  var withRandomNumberGenerator

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      guard let (source, action) = action.pathElement,
            let request = self.request(action, state[stack: source.tab][id: source.id])
      else { return .none }
      return .send(.player(.play(queue: request.queue, startAt: request.startAt, source: request.source)))
    }
  }

  private struct Request {
    let queue: [PlayerTrack]
    var startAt = 0
    let source: String?
  }

  private func request(_ action: MainTabFeature.Path.Action, _ screen: MainTabFeature.Path.State?) -> Request? {
    switch (action, screen) {
    case let (.relayDetail(.delegate(.playAll)), .relayDetail(relay)?),
         let (.relayDetail(.delegate(.playSong)), .relayDetail(relay)?):
      guard let detail = relay.detail else { return nil }
      let queue = detail.ranking.map { PlayerTrack(id: $0.id, title: $0.title, artist: $0.artist) }
      var startAt = 0
      if case let .relayDetail(.delegate(.playSong(id))) = action {
        startAt = queue.firstIndex { $0.id == id } ?? 0
      }
      return Request(queue: queue, startAt: startAt, source: Self.oneLine(detail.title))
    case let (.completedPlaylist(.delegate(.playAll)), .completedPlaylist(completed)?):
      guard let playlist = completed.playlist else { return nil }
      let queue = playlist.ranking.map { PlayerTrack(id: $0.id, title: $0.title, artist: $0.artist) }
      return Request(queue: queue, source: Self.oneLine(playlist.title))
    case let (.playlistDetail(.delegate(.play(_, shuffled))), .playlistDetail(detail)?):
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

  private static func oneLine(_ title: String) -> String {
    title.replacingOccurrences(of: "\n", with: " ")
  }
}
