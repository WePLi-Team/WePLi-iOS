import ComposableArchitecture
import Foundation
import WidgetKit

// REQ-079 · UI-13e · DEC-015 — 잠금화면 위젯에 보여줄 친구 · 그룹을 저장하고 위젯을 다시 그린다

struct NowPlayingWidgetClient {
  var update: @Sendable (_ snapshot: NowPlayingWidgetSnapshot) async -> Void
}

extension NowPlayingWidgetClient: DependencyKey {
  static let liveValue = NowPlayingWidgetClient(
    update: { snapshot in
      NowPlayingWidgetStore.write(snapshot)
      WidgetCenter.shared.reloadTimelines(ofKind: NowPlayingWidgetStore.widgetKind)
    }
  )

  static let previewValue = NowPlayingWidgetClient(update: { _ in })
  static let testValue = NowPlayingWidgetClient(update: unimplemented("NowPlayingWidgetClient.update"))
}

extension DependencyValues {
  var nowPlayingWidgetClient: NowPlayingWidgetClient {
    get { self[NowPlayingWidgetClient.self] }
    set { self[NowPlayingWidgetClient.self] = newValue }
  }
}

extension NowPlayingWidgetSnapshot {
  /// 친구 피드에서 — 지금 듣는 첫 친구(나는 빼고), 그룹은 미결정이라 원본 예시 「우리 넷」에 지금 듣는 친구 수
  init(_ feed: FriendFeed, now: Date) {
    let playing = feed.rail.filter { !$0.isMe && $0.isPlaying }
    self.init(
      person: playing.first.map { Person(name: $0.name, title: $0.title, artist: $0.artist, listenedAt: now) },
      group: Group(name: "우리 넷", listeningCount: playing.count)
    )
  }
}
