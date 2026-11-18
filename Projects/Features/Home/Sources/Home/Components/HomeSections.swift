import SwiftUI
import WePLiDesignSystem

// UI-12a 섹션 공용 — 제목 18 SemiBold + 꺾쇠 18 #D8D8DD(더 볼 목록이 있을 때만, 제목 전체를 누름) · 설명 12 Light #A3A3A3

public struct HomeSectionHeader<Trailing: View>: View {
  public let title: String
  public var subtitle: String?
  public var showsChevron = true
  public var onTap: (() -> Void)?
  @ViewBuilder public var trailing: () -> Trailing

  public var body: some View {
    HStack(alignment: .bottom, spacing: 12) {
      Button {
        self.onTap?()
      } label: {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 2) {
            Text(self.title)
              .wepliFont(.headline)
              .foregroundStyle(WePLiColor.textPrimary)
            if self.showsChevron {
              Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(WePLiColor.textMuted)
                .frame(width: 18, height: 18)
            }
          }
          if let subtitle = self.subtitle {
            Text(subtitle)
              .wepliFont(.caption, weight: .light)
              .foregroundStyle(WePLiColor.textTertiary)
          }
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .disabled(self.onTap == nil)
      .accessibilityAddTraits(.isHeader)
      Spacer(minLength: 0)
      self.trailing()
    }
    .padding(.horizontal, 20)
  }

  public init(
    title: String,
    subtitle: String? = nil,
    showsChevron: Bool = true,
    onTap: (() -> Void)? = nil,
    @ViewBuilder trailing: @escaping () -> Trailing
  ) {
    self.title = title
    self.subtitle = subtitle
    self.showsChevron = showsChevron
    self.onTap = onTap
    self.trailing = trailing
  }
}

public extension HomeSectionHeader where Trailing == EmptyView {
  init(title: String, subtitle: String? = nil, showsChevron: Bool = true, onTap: (() -> Void)? = nil) {
    self.init(title: title, subtitle: subtitle, showsChevron: showsChevron, onTap: onTap) { EmptyView() }
  }
}

/// 「전체듣기」 — 높이 32 알약, 흰색 10%
public struct HomePlayAllButton: View {
  public let action: () -> Void

  public var body: some View {
    Button(action: self.action) {
      HStack(spacing: 6) {
        Image(systemName: "play.fill").font(.system(size: 10))
        Text("전체듣기").wepliFont(.footnote, weight: .semibold)
      }
      .foregroundStyle(WePLiColor.textPrimary)
      .padding(.leading, 10)
      .padding(.trailing, 12)
      .frame(height: 32)
      .background(WePLiColor.secondaryButtonFill, in: Capsule())
    }
    .buttonStyle(.plain)
  }

  public init(action: @escaping () -> Void) {
    self.action = action
  }
}

/// 위플리 TOP 100 — 줄 60 · 커버 48 · 순위 15 · 재생 · ···
public struct HomeChartSection: View {
  public let feed: HomeFeed
  public let onSong: (HomeChartSong.ID) -> Void
  public let onMore: (HomeChartSong.ID) -> Void
  public let onPlayAll: () -> Void

  public var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HomeSectionHeader(title: "위플리 TOP 100", subtitle: self.feed.chartUpdatedText) {
        HomePlayAllButton(action: self.onPlayAll)
      }
      VStack(spacing: 0) {
        ForEach(Array(self.feed.chart.enumerated()), id: \.element.id) { index, song in
          HStack(spacing: 12) {
            Button {
              self.onSong(song.id)
            } label: {
              HStack(spacing: 12) {
                WePLiArtwork(size: 48, style: .rounded(4))
                Text("\(index + 1)")
                  .wepliFont(.body, weight: .semibold)
                  .monospacedDigit()
                  .foregroundStyle(WePLiColor.textPrimary)
                  .frame(width: 16)
                HomeSongText(title: song.title, artist: song.artist)
              }
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Image(systemName: "play")
              .font(.system(size: 12))
              .foregroundStyle(WePLiColor.textMuted)
              .frame(width: 40, height: 44)
              .accessibilityHidden(true)
            HomeMoreButton(label: "\(song.title) 더보기") { self.onMore(song.id) }
          }
          .padding(.leading, 20)
          .padding(.trailing, 8)
          .frame(height: 60)
        }
      }
    }
  }

  public init(
    feed: HomeFeed,
    onSong: @escaping (HomeChartSong.ID) -> Void,
    onMore: @escaping (HomeChartSong.ID) -> Void,
    onPlayAll: @escaping () -> Void
  ) {
    self.feed = feed
    self.onSong = onSong
    self.onMore = onMore
    self.onPlayAll = onPlayAll
  }
}

public struct HomeSongText: View {
  public let title: String
  public let artist: String

  public var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(self.title)
        .wepliFont(.body)
        .foregroundStyle(WePLiColor.textPrimary)
      Text(self.artist)
        .wepliFont(.footnote, weight: .light)
        .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
    }
    .lineLimit(1)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  public init(title: String, artist: String) {
    self.title = title
    self.artist = artist
  }
}

/// ··· — 40×44, 점 4 · #9292A1
public struct HomeMoreButton: View {
  public let label: String
  public let action: () -> Void

  public var body: some View {
    Button(action: self.action) {
      HStack(spacing: 3) {
        ForEach(0 ..< 3, id: \.self) { _ in
          Circle().fill(WePLiColor.tabInactiveGlass).frame(width: 4, height: 4)
        }
      }
      .frame(width: 40, height: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(self.label)
  }

  public init(label: String, action: @escaping () -> Void) {
    self.label = label
    self.action = action
  }
}

/// 배너 · 오직 위플리에서만 — 제목 없음, 한 장씩 넘김(폭 = 화면 − 40) · 높이 84 · 모서리 12 · #141417
public struct HomeBannerSection: View {
  public let banners: [HomeBanner]
  public let onTap: (HomeBanner.ID) -> Void

  public var body: some View {
    TabView {
      ForEach(self.banners) { banner in
        Button {
          self.onTap(banner.id)
        } label: {
          HStack {
            VStack(alignment: .leading, spacing: 2) {
              Text(banner.eyebrow)
                .wepliFont(.caption)
                .foregroundStyle(WePLiColor.textPrimary)
              Text(banner.title)
                .wepliFont(.body, weight: .semibold)
                .foregroundStyle(.white)
            }
            Spacer(minLength: 0)
            // 미결정 — 배너 그림(b1 · b2)이 번들에 없어 자리 표시
            RoundedRectangle(cornerRadius: 8)
              .fill(WePLiColor.imagePlaceholder)
              .frame(width: 100, height: 76)
              .accessibilityHidden(true)
          }
          .padding(.leading, 20)
          .padding(.trailing, 16)
          .frame(height: 84)
          .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 12))
          .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .frame(height: 84)
  }

  public init(banners: [HomeBanner], onTap: @escaping (HomeBanner.ID) -> Void) {
    self.banners = banners
    self.onTap = onTap
  }
}
