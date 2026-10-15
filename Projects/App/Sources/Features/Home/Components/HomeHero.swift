import SwiftUI

// UI-12a 히어로 · 넘기는 대표 릴레이 — 높이 510(12b 500 · 12c 384), 가로로 넘김, 아래 점
// 장마다: 위 스크림 150 · 아래 70% 그라디언트 · 태그 13 SemiBold · 제목 28 · 남은 시간 · 1위 곡 + 커버 60

struct HomeHeroPager: View {
  static let height: CGFloat = 510

  let heroes: [HomeHero]
  let now: Date
  @Binding var page: Int
  let onTap: (HomeHero.ID) -> Void
  let onPlayAll: (HomeHero.ID) -> Void

  var body: some View {
    ZStack(alignment: .bottom) {
      TabView(selection: self.$page) {
        ForEach(Array(self.heroes.enumerated()), id: \.element.id) { index, hero in
          HomeHeroPage(hero: hero, now: self.now, onPlayAll: { self.onPlayAll(hero.id) })
            .contentShape(Rectangle())
            .onTapGesture { self.onTap(hero.id) }
            .tag(index)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      HStack(spacing: 6) {
        ForEach(self.heroes.indices, id: \.self) { index in
          Capsule()
            .fill(index == self.page ? WePLiColor.textPrimary : Color.white.opacity(0.3))
            .frame(width: index == self.page ? 18 : 6, height: 6)
            .onTapGesture { withAnimation(.easeInOut(duration: 0.3)) { self.page = index } }
        }
      }
      .padding(.bottom, 16)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("\(self.heroes.count)장 중 \(self.page + 1)번째")
    }
    .frame(height: Self.height)
  }
}

private struct HomeHeroPage: View {
  let hero: HomeHero
  let now: Date
  let onPlayAll: () -> Void

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      // 미결정 — 릴레이 커버 사진이 아직 없어 이미지 자리 색
      WePLiColor.imagePlaceholder
      VStack(spacing: 0) {
        LinearGradient(colors: [.black.opacity(0.5), .black.opacity(0)], startPoint: .top, endPoint: .bottom)
          .frame(height: 150)
        Spacer(minLength: 0)
        LinearGradient(
          stops: [
            .init(color: .black.opacity(0.01), location: 0),
            .init(color: .black.opacity(0.1), location: 0.2163),
            .init(color: .black.opacity(0.2), location: 0.4471),
            .init(color: .black.opacity(0.5932), location: 0.66),
            .init(color: .black, location: 1),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: HomeHeroPager.height * 0.7)
      }
      self.content
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    .clipped()
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: 18) {
      VStack(alignment: .leading, spacing: 6) {
        Text(self.hero.isCompleted ? "RelayList · 완성" : "RelayList · 진행 중")
          .wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(self.hero.isCompleted ? WePLiColor.textTertiary : WePLiColor.accent)
        Text(self.hero.title)
          .wepliFont(.title1)
          .foregroundStyle(.white)
          .lineLimit(2)
        self.metaLine
      }
      HStack(spacing: 16) {
        VStack(alignment: .leading, spacing: 4) {
          Text(self.hero.rankLabel)
            .wepliFont(.caption, weight: .medium)
            .foregroundStyle(WePLiColor.textTertiary)
          Text(self.hero.song)
            .wepliFont(.headline)
            .foregroundStyle(.white)
            .lineLimit(1)
          Text(self.hero.songMeta)
            .wepliFont(.subheadline, weight: .light)
            .foregroundStyle(WePLiColor.textSecondary)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        RoundedRectangle(cornerRadius: 8)
          .fill(WePLiColor.surface2)
          .frame(width: 60, height: 60)
          .accessibilityHidden(true)
      }
      if self.hero.isCompleted {
        Button(action: self.onPlayAll) {
          HStack(spacing: 7) {
            Image(systemName: "play.fill").font(.system(size: 11))
            Text("완성된 플리 전체듣기").wepliFont(.subheadline, weight: .semibold)
          }
          .foregroundStyle(WePLiColor.textPrimary)
          .padding(.leading, 13)
          .padding(.trailing, 16)
          .frame(height: 36)
          .background(WePLiColor.secondaryButtonFill, in: Capsule())
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var metaLine: some View {
    HStack(spacing: 8) {
      if case let .live(endsAt) = self.hero.status {
        Circle().fill(WePLiGradient.vsRing).frame(width: 7, height: 7)
        Text("\(HomeCountdown.clock(from: self.now, to: endsAt)) 남음")
          .wepliFont(.subheadline, weight: .semibold)
          .foregroundStyle(WePLiColor.accent)
          .monospacedDigit()
        Text("·").foregroundStyle(WePLiColor.textQuaternary)
      }
      Text(self.hero.people)
        .foregroundStyle(WePLiColor.textMuted)
    }
    .wepliFont(.subheadline)
    .lineLimit(1)
  }
}

/// 히어로 위 머리 — 로고 · 알림(배지). 히어로와 함께 스크롤된다
struct HomeHeader: View {
  let unread: Int
  let onNotifications: () -> Void

  @Environment(\.wepliChrome)
  private var chrome

  var body: some View {
    HStack {
      // 미결정 — 로고 이미지가 번들에 없어 글자로 대신한다
      Text("WePLi")
        .font(.custom(WePLiFont.Weight.bold.postScriptName, fixedSize: 18))
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      Spacer()
      Button(action: self.onNotifications) {
        Image(systemName: "bell")
          .font(.system(size: self.chrome == .glass ? 19 : 22))
          .foregroundStyle(WePLiColor.textPrimary)
          .frame(width: 44, height: 44)
          .modifier(BellBackground(isGlass: self.chrome == .glass))
          .overlay(alignment: .topTrailing) {
            if self.unread > 0 {
              Text("\(self.unread)")
                .font(.custom(WePLiFont.Weight.bold.postScriptName, fixedSize: 10))
                .foregroundStyle(WePLiColor.textOnCTA)
                .padding(.horizontal, 4)
                .frame(minWidth: 16, minHeight: 16)
                .background(WePLiColor.accent, in: Capsule())
                .padding(.top, self.chrome == .glass ? 8 : 6)
                .padding(.trailing, self.chrome == .glass ? 9 : 5)
            }
          }
      }
      .buttonStyle(.plain)
      .accessibilityLabel(self.unread > 0 ? "알림, 읽지 않은 알림 \(self.unread)개" : "알림")
    }
    .padding(.leading, 22)
    .padding(.trailing, 12)
    .frame(height: 44)
  }
}

private struct BellBackground: ViewModifier {
  let isGlass: Bool

  func body(content: Content) -> some View {
    if self.isGlass {
      content.wepliGlass(in: Circle())
    } else {
      content
    }
  }
}
