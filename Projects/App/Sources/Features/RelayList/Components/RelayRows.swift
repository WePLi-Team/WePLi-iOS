import SwiftUI

// UI-10a — 피처 카드 · 목록 행 · 필터 칩
// 커버 이미지는 백엔드가 정해지면 붙인다. 지금은 릴레이마다 다른 그라디언트 자리 표시.

struct RelayCover: View {
  let relay: Relay
  var cornerRadius: CGFloat

  var body: some View {
    // hashValue는 실행마다 바뀌므로 글자 값의 합으로 색을 고정한다.
    let hue = Double(self.relay.id.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 360) / 360
    RoundedRectangle(cornerRadius: self.cornerRadius)
      .fill(
        LinearGradient(
          colors: [Color(hue: hue, saturation: 0.35, brightness: 0.45), WePLiColor.surface2],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .overlay {
        Image(systemName: "music.note.list")
          .font(.system(size: 22, weight: .light))
          .foregroundStyle(WePLiColor.textPrimary.opacity(0.5))
      }
      .accessibilityHidden(true)
  }
}

struct RelayFeaturedCard: View {
  let relay: Relay
  let now: Date

  enum Metric {
    static let height: CGFloat = 200
    static let cornerRadius: CGFloat = 22
  }

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      RelayCover(relay: self.relay, cornerRadius: Metric.cornerRadius)
      LinearGradient(
        stops: [.init(color: .black.opacity(0.05), location: 0.2), .init(color: .black.opacity(0.85), location: 1)],
        startPoint: .top,
        endPoint: .bottom
      )
      .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius))

      VStack(alignment: .leading, spacing: 6) {
        if let endsAt = self.relay.endsAt {
          Text("곧 마감 · \(RemainingTimeFormatter.string(from: self.now, to: endsAt)) 남음")
            .wepliFont(.caption, weight: .semibold)
            .foregroundStyle(WePLiColor.highlight)
            .monospacedDigit()
        }
        Text(self.relay.title)
          .wepliFont(.title3, weight: .bold)
          .foregroundStyle(WePLiColor.textPrimary)
          .lineLimit(2)
        Text("\(self.relay.voteFormat.title) 투표 · \(self.relay.participantText)명 참여 중")
          .wepliFont(.footnote)
          .foregroundStyle(WePLiColor.textMuted)
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 14)
    }
    .frame(height: Metric.height)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isButton)
  }
}

struct RelayRow: View {
  let relay: Relay
  let now: Date

  enum Metric {
    static let coverSize: CGFloat = 72
    static let coverCornerRadius: CGFloat = 14
  }

  var body: some View {
    HStack(spacing: 14) {
      RelayCover(relay: self.relay, cornerRadius: Metric.coverCornerRadius)
        .frame(width: Metric.coverSize, height: Metric.coverSize)
      VStack(alignment: .leading, spacing: 4) {
        Text(self.relay.title)
          .wepliFont(.callout, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
          .lineLimit(2)
        HStack(spacing: 6) {
          Text(self.relay.voteFormat.title)
            .wepliFont(.caption)
            .foregroundStyle(WePLiColor.textMuted)
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(WePLiColor.surface2, in: RoundedRectangle(cornerRadius: 4))
          Text(self.meta)
            .wepliFont(.caption)
            .foregroundStyle(WePLiColor.textTertiary)
            .monospacedDigit()
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .contentShape(Rectangle())
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isButton)
  }

  /// 「2:17:59 남음 · 3,012명」 · 완성은 「완성 · 1,284명 참여」
  private var meta: String {
    guard let endsAt = self.relay.endsAt else {
      return "완성 · \(self.relay.participantText)명 참여"
    }
    return "\(RemainingTimeFormatter.string(from: self.now, to: endsAt)) 남음 · \(self.relay.participantText)명"
  }
}

struct RelayFilterChips: View {
  let selected: RelayFilter
  let onSelect: (RelayFilter) -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(RelayFilter.allCases, id: \.self) { filter in
          let isOn = filter == self.selected
          Button {
            self.onSelect(filter)
          } label: {
            Text(filter.title)
              .wepliFont(.subheadline, weight: isOn ? .semibold : .regular)
              .foregroundStyle(isOn ? Color.black : WePLiColor.textMuted)
              .padding(.horizontal, 14)
              .frame(height: 34)
              .background(isOn ? WePLiColor.textPrimary : WePLiColor.surface2, in: Capsule())
          }
          .buttonStyle(.plain)
          .accessibilityAddTraits(isOn ? .isSelected : [])
        }
      }
      .padding(.horizontal, 20)
    }
  }
}
