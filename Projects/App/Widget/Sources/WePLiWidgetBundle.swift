import SwiftUI
import WidgetKit

// REQ-079 · UI-13e — 잠금화면 위젯: 직사각형(친구가 지금 듣는 곡) · 원형(그룹에서 듣는 사람 수)
// 미결정 — 위젯 편집에서 사람 · 그룹 고르기는 AppIntent(iOS 17+)가 필요해, iOS 16 지원을 위해 지금은 앱이 정한 사람을 보여준다

@main
struct WePLiWidgetBundle: WidgetBundle {
  var body: some Widget {
    NowPlayingWidget()
  }
}

struct NowPlayingEntry: TimelineEntry {
  let date: Date
  let snapshot: NowPlayingWidgetSnapshot
}

struct NowPlayingProvider: TimelineProvider {
  func placeholder(in context: Context) -> NowPlayingEntry {
    NowPlayingEntry(date: Date(), snapshot: .placeholder)
  }

  func getSnapshot(in context: Context, completion: @escaping (NowPlayingEntry) -> Void) {
    completion(NowPlayingEntry(date: Date(), snapshot: NowPlayingWidgetStore.read() ?? .placeholder))
  }

  /// 몇 분 단위로 갱신 — 「2분 전」이 맞게 5분마다 다시 그린다
  func getTimeline(in context: Context, completion: @escaping (Timeline<NowPlayingEntry>) -> Void) {
    let now = Date()
    let snapshot = NowPlayingWidgetStore.read() ?? NowPlayingWidgetSnapshot()
    let entries = (0 ..< 6).map { NowPlayingEntry(date: now.addingTimeInterval(Double($0) * 300), snapshot: snapshot) }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

struct NowPlayingWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: NowPlayingWidgetStore.widgetKind, provider: NowPlayingProvider()) { entry in
      NowPlayingWidgetView(entry: entry)
    }
    .configurationDisplayName("지금 듣는 음악")
    .description("친구와 그룹이 지금 듣는 곡을 잠금화면에서 봐요.")
    .supportedFamilies([.accessoryRectangular, .accessoryCircular])
  }
}
