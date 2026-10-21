import ComposableArchitecture
import SwiftUI

// REQ-079 · UI-13f — 지금 위플리. 히어로(실시간 점 · 듣는 사람 수 · 곡 · 듣기) → 시간대 밑줄 탭 → 순위 → 안내

struct LiveTrendView: View {
  let store: StoreOf<LiveTrendFeature>

  var body: some View {
    WithPerceptionTracking {
      ScrollView {
        if let trend = self.store.trend {
          VStack(alignment: .leading, spacing: 0) {
            self.hero(trend)
            WePLiUnderlineTabs(items: LiveTrendSlot.allCases, selected: self.store.slot, title: \.title) {
              self.store.send(.slotSelected($0))
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            self.ranking.padding(.horizontal, 20).padding(.top, 14)
            Text("전체 공개를 고른 사람들의 재생만 이름 없이 모아요. 10명이 안 되는 곡은 보여주지 않아요.")
              .wepliFont(.caption, weight: .light)
              .foregroundStyle(WePLiColor.textDisabled)
              .padding(.horizontal, 20)
              .padding(.top, 16)
          }
          .padding(.bottom, 60)
        } else if self.store.loadFailed {
          VStack(spacing: 12) {
            // 원본에 없는 문구 — 디자인 확인 필요
            Text("지금 위플리를 불러오지 못했어요").wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
            Button("다시 시도") { self.store.send(.retryButtonTapped) }
              .wepliFont(.subheadline, weight: .semibold)
              .foregroundStyle(WePLiColor.accent)
          }
          .frame(maxWidth: .infinity, minHeight: 400)
        } else {
          ProgressView().tint(WePLiColor.textTertiary).frame(maxWidth: .infinity, minHeight: 400)
        }
      }
      .ignoresSafeArea(edges: .top)
      .overlay(alignment: .topLeading) {
        WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") { self.store.send(.backButtonTapped) }
          .padding(.horizontal, 16)
      }
      .background(WePLiColor.background.ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
      .onAppear { self.store.send(.onAppear) }
      .onDisappear { self.store.send(.onDisappear) }
    }
  }

  /// 미결정 — 원본은 히어로 곡 커버를 꽉 채운다. 커버가 없어 자리 표시
  private func hero(_ trend: LiveTrend) -> some View {
    ZStack(alignment: .bottomLeading) {
      WePLiColor.imagePlaceholder
      LinearGradient(
        stops: [
          .init(color: .black.opacity(0.01), location: 0.3),
          .init(color: .black.opacity(0.59), location: 0.75),
          .init(color: .black, location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      VStack(alignment: .leading, spacing: 18) {
        VStack(alignment: .leading, spacing: 6) {
          HStack(spacing: 6) {
            LiveTrendPulseDot()
            Text("지금 위플리 · 실시간").wepliFont(.footnote, weight: .semibold).foregroundStyle(WePLiColor.accent)
          }
          Text("\(HomeText.count(trend.listeners))명이\n듣는 중")
            .wepliFont(.title1)
            .monospacedDigit()
            .foregroundStyle(WePLiColor.textPrimary)
            .contentTransition(.numericText())
            .animation(.easeOut(duration: 0.3), value: trend.listeners)
        }
        self.heroSong(trend.hero)
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 22)
    }
    .frame(height: 430)
    .clipped()
  }

  private func heroSong(_ hero: LiveTrendSong) -> some View {
    HStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 4) {
        Text(hero.title).wepliFont(.headline).foregroundStyle(WePLiColor.textPrimary)
        Text(hero.artist).wepliFont(.subheadline, weight: .light).foregroundStyle(WePLiColor.textSecondary)
      }
      Button {
        self.store.send(.heroPlayTapped)
      } label: {
        HStack(spacing: 6) {
          Image(systemName: "play.fill").font(.system(size: 10))
          Text("듣기").wepliFont(.footnote, weight: .semibold)
        }
        .foregroundStyle(WePLiColor.textPrimary)
        .padding(.leading, 10)
        .padding(.trailing, 12)
        .frame(height: 32)
        .background(WePLiColor.secondaryButtonFill, in: Capsule())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("\(hero.title) 듣기")
    }
  }

  private var ranking: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(self.store.slot.subtitle).wepliFont(.footnote).foregroundStyle(WePLiColor.textQuaternary).padding(.bottom, 6)
      ForEach(Array(self.store.songs.enumerated()), id: \.element.id) { index, song in
        Button {
          self.store.send(.songTapped(song.id))
        } label: {
          HStack(spacing: 12) {
            Text("\(index + 1)").wepliFont(.body, weight: .semibold).monospacedDigit().frame(width: 16)
            RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 2) {
              Text(song.title).wepliFont(.body).lineLimit(1)
              Text(song.artist).wepliFont(.footnote, weight: .light)
                .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
              Text("\(song.listeners)명").wepliFont(.footnote, weight: .semibold).monospacedDigit()
              if song.isRising {
                Text("급상승")
                  .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 11, relativeTo: .caption2))
                  .foregroundStyle(WePLiColor.highlight)
              }
            }
          }
          .foregroundStyle(WePLiColor.textPrimary)
          .frame(height: 62)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
    .animation(.easeInOut(duration: 0.2), value: self.store.slot)
  }
}

/// 홀로그램 실시간 점 — 1.4초마다 퍼지는 시안 고리
private struct LiveTrendPulseDot: View {
  @State private var isPulsing = false

  @Environment(\.accessibilityReduceMotion)
  private var reduceMotion

  var body: some View {
    Circle()
      .fill(WePLiGradient.vsRing)
      .frame(width: 8, height: 8)
      .background {
        Circle()
          .stroke(WePLiColor.positive.opacity(self.isPulsing ? 0 : 0.55), lineWidth: 2)
          .scaleEffect(self.isPulsing ? 3 : 1)
      }
      .onAppear {
        guard !self.reduceMotion else { return }
        withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) { self.isPulsing = true }
      }
      .accessibilityHidden(true)
  }
}

#Preview {
  NavigationStack {
    LiveTrendView(store: Store(initialState: LiveTrendFeature.State()) { LiveTrendFeature() })
  }
}
