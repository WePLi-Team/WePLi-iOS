import SwiftUI
import WidgetKit

// UI-13e — 잠금화면은 흑백으로 그려진다. 브랜드 색 대신 흰색 투명도로만 나눈다(원본)

struct NowPlayingWidgetView: View {
  let entry: NowPlayingEntry

  @Environment(\.widgetFamily)
  private var family

  var body: some View {
    switch self.family {
    case .accessoryCircular: self.circular
    default: self.rectangular()
    }
  }

  @ViewBuilder
  private func rectangular() -> some View {
    if let person = self.entry.snapshot.person {
      VStack(alignment: .leading, spacing: 1) {
        HStack(spacing: 3) {
          Image(systemName: "headphones").font(.system(size: 10, weight: .bold))
          Text("지금 듣는 중").font(.system(size: 11, weight: .semibold))
        }
        .opacity(0.8)
        Text(person.name).font(.system(size: 14, weight: .bold)).lineLimit(1)
        Text("\(person.title) · \(person.artist)").font(.system(size: 12)).lineLimit(1).opacity(0.85)
        Text(NowPlayingWidgetText.ago(person.listenedAt, now: self.entry.date)).font(.system(size: 11)).opacity(0.6)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .widgetBackground()
    } else {
      // 원본에 없는 빈 상태 — 디자인 확인 필요
      Text("친구가 듣는 음악이 여기 보여요").font(.system(size: 12)).widgetBackground()
    }
  }

  private var circular: some View {
    VStack(spacing: 1) {
      Text("\(self.entry.snapshot.group?.listeningCount ?? 0)").font(.system(size: 22, weight: .bold))
      Text(self.entry.snapshot.group?.name ?? "그룹").font(.system(size: 10, weight: .semibold)).lineLimit(1).opacity(0.8)
    }
    .widgetBackground()
  }
}

private extension View {
  /// iOS 17부터 위젯 바탕을 containerBackground로 알려야 한다
  @ViewBuilder
  func widgetBackground() -> some View {
    if #available(iOS 17.0, *) {
      self.containerBackground(for: .widget) { AccessoryWidgetBackground() }
    } else {
      self
    }
  }
}
