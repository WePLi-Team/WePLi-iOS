import ComposableArchitecture
import SwiftUI

// REQ-038 · UI-8a(v2) — 내 추천곡 실시간 순위
// 히어로 460(내 곡 아트) · 내비(뒤로 · 잠금화면 · 응원 요청) · 「현재 순위」 목록 · 위에서 내려오는 역전 알림

struct MyRecommendationView: View {
  let store: StoreOf<MyRecommendationFeature>

  @Environment(\.accessibilityReduceMotion)
  private var reduceMotion

  var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        ScrollView {
          if let standing = self.store.standing {
            VStack(alignment: .leading, spacing: 0) {
              self.hero(standing)
              VStack(alignment: .leading, spacing: 4) {
                Text("현재 순위")
                  .wepliFont(.headline)
                  .foregroundStyle(WePLiColor.textPrimary)
                  .accessibilityAddTraits(.isHeader)
                Text("곡마다 추천한 사람이 표시돼요")
                  .wepliFont(.caption, weight: .light)
                  .foregroundStyle(WePLiColor.textTertiary)
              }
              .padding(EdgeInsets(top: 26, leading: 20, bottom: 8, trailing: 20))
              ForEach(Array(standing.songs.enumerated()), id: \.element.id) { index, song in
                StandingRow(rank: index + 1, song: song)
              }
            }
            .padding(.bottom, 60)
            .animation(
              self.reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.55, dampingFraction: 0.9),
              value: standing.songs.map(\.id)
            )
          } else if self.store.loadFailed {
            // 원본에 오류 화면이 없어 임시 문구 — 디자인 확인 필요
            Text("순위를 불러오지 못했어요")
              .wepliFont(.callout, weight: .semibold)
              .foregroundStyle(WePLiColor.textPrimary)
              .frame(maxWidth: .infinity, minHeight: 500)
          } else {
            ProgressView().tint(WePLiColor.textTertiary).frame(maxWidth: .infinity, minHeight: 500)
          }
        }
        .ignoresSafeArea(edges: .top)
        self.navigationBar
        if let banner = self.store.banner {
          ReversalBannerView(banner: banner)
            .padding(.horizontal, 10)
            .transition(self.reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            .zIndex(1)
        }
      }
      .animation(.easeOut(duration: 0.35), value: self.store.banner)
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .onAppear { self.store.send(.onAppear) }
      .onDisappear { self.store.send(.onDisappear) }
    }
  }

  private var navigationBar: some View {
    HStack(spacing: 8) {
      WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") { self.store.send(.backButtonTapped) }
      VStack(spacing: 0) {
        Text(self.store.standing?.title ?? "")
          .wepliFont(.body, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
          .lineLimit(1)
        Text(self.store.remainingText)
          .wepliFont(.caption)
          .foregroundStyle(WePLiColor.textMuted)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity)
      WePLiIconButton(systemName: "iphone", accessibilityLabel: "잠금화면에 순위 띄우기") {
        self.store.send(.liveActivityTapped)
      }
      WePLiIconButton(systemName: "square.and.arrow.up", accessibilityLabel: "친구에게 응원 요청") {
        self.store.send(.cheerTapped)
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
  }

  private func hero(_ standing: RelayStanding) -> some View {
    ZStack(alignment: .bottomLeading) {
      WePLiColor.imagePlaceholder
        .overlay {
          Image(systemName: "music.note")
            .font(.system(size: 80, weight: .ultraLight))
            .foregroundStyle(WePLiColor.textQuaternary.opacity(0.5))
        }
      VStack(spacing: 0) {
        LinearGradient(
          stops: [
            .init(color: .black.opacity(0.75), location: 0),
            .init(color: .black.opacity(0.45), location: 0.5),
            .init(color: .black.opacity(0), location: 1),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: 180)
        Spacer(minLength: 0)
        LinearGradient(
          stops: [
            .init(color: .black.opacity(0.01), location: 0),
            .init(color: .black.opacity(0.2), location: 0.45),
            .init(color: .black.opacity(0.59), location: 0.66),
            .init(color: .black, location: 1),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: 380)
      }
      if let song = standing.heroSong, let rank = standing.rank(of: song.id) {
        MyRecommendationHero(standing: standing, song: song, rank: rank)
          .padding(.horizontal, 20)
          .padding(.bottom, 24)
      }
    }
    .frame(height: 460)
    .clipped()
  }
}

/// 히어로 안 내 곡 — 「내 추천곡」 · 곡명 28 · 「#가수」 · 순위 44 Bold + 「위」 · 변동 · 남은 점수
private struct MyRecommendationHero: View {
  let standing: RelayStanding
  let song: StandingSong
  let rank: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .bottom, spacing: 16) {
        VStack(alignment: .leading, spacing: 6) {
          Text("내 추천곡")
            .wepliFont(.footnote, weight: .semibold)
            .foregroundStyle(WePLiColor.accent)
          Text(self.song.title)
            .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 28, relativeTo: .title))
            .foregroundStyle(WePLiColor.textPrimary)
            .lineLimit(2)
          Text("#\(self.song.artist)")
            .wepliFont(.subheadline, weight: .light)
            .foregroundStyle(WePLiColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        VStack(alignment: .trailing, spacing: 2) {
          (Text("\(self.rank)")
            .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 44, relativeTo: .largeTitle))
            + Text("위").font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 18, relativeTo: .headline)))
            .monospacedDigit()
            .foregroundStyle(WePLiColor.textPrimary)
            .contentTransition(.numericText())
          Text(StandingText.move(RankChange(startRank: self.song.startRank, rank: self.rank)))
            .wepliFont(.caption, weight: .semibold)
            .foregroundStyle(WePLiColor.positive)
        }
      }
      HStack(spacing: 8) {
        Circle().fill(WePLiGradient.vsRing).frame(width: 6, height: 6)
        (Text(StandingText.gap(self.standing, song: self.song)).foregroundColor(WePLiColor.textPrimary)
          + Text(" · \(StandingText.score(self.song.score))점")
          .font(.custom(WePLiFont.Weight.light.postScriptName, size: 14, relativeTo: .subheadline))
          .foregroundColor(WePLiColor.textTertiary))
          .wepliFont(.subheadline, weight: .semibold)
          .monospacedDigit()
          .contentTransition(.numericText())
      }
    }
    .accessibilityElement(children: .combine)
  }
}

#Preview {
  NavigationStack {
    MyRecommendationView(store: Store(initialState: MyRecommendationFeature.State(relayID: "first-love")) {
      MyRecommendationFeature()
    })
  }
}
