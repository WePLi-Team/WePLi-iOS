import ComposableArchitecture
import SwiftUI

// REQ-034 · UI-8b(v2) — 곡 월드컵. 위 · 아래 반쪽을 눌러 고르고, 결승이 끝나면 나의 우승곡과 다른 사람들의 우승곡을 보여 준다.

struct SongWorldCupView: View {
  let store: StoreOf<SongWorldCupFeature>

  var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        WePLiColor.background.ignoresSafeArea()
        if let champion = self.store.champion {
          self.result(champion)
        } else if let pair = self.store.pair {
          self.match(top: pair.top, bottom: pair.bottom)
        } else if self.store.loadFailed {
          // 원본에 오류 화면이 없어 임시 문구 — 디자인 확인 필요
          VStack(spacing: 12) {
            Text("대결할 곡을 불러오지 못했어요")
              .wepliFont(.callout, weight: .semibold)
              .foregroundStyle(WePLiColor.textPrimary)
            Button("다시 시도") { self.store.send(.retryButtonTapped) }
              .wepliFont(.body, weight: .semibold)
              .foregroundStyle(WePLiColor.accent)
          }
          .frame(maxHeight: .infinity)
        } else {
          ProgressView().tint(WePLiColor.textTertiary).frame(maxHeight: .infinity)
        }
        self.topBar
      }
      .toolbar(.hidden, for: .navigationBar)
      .wepliToast(self.store.toast) { self.store.send(.toastDismissed) }
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private var topBar: some View {
    HStack(spacing: 0) {
      Button {
        self.store.send(.closeTapped)
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(WePLiColor.textPrimary)
          .frame(width: 44, height: 44)
          .wepliGlass(in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("닫기")
      Text(self.store.topic)
        .wepliFont(.body, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
        .lineLimit(1)
        .frame(maxWidth: .infinity)
      Color.clear.frame(width: 44, height: 44)
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
  }

  private func match(top: WorldCupSong, bottom: WorldCupSong) -> some View {
    ZStack {
      VStack(spacing: 0) {
        WorldCupHalf(song: top, side: .top, picked: self.store.picked) { self.store.send(.sideTapped(.top)) }
        WorldCupHalf(song: bottom, side: .bottom, picked: self.store.picked) {
          self.store.send(.sideTapped(.bottom))
        }
      }
      .ignoresSafeArea()
      .id(self.store.bracket.completedMatches)
      .transition(.opacity)
      WorldCupVersusBadge()
      VStack(spacing: 4) {
        Text(self.store.bracket.roundLabel)
          .wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(WePLiColor.accent)
        Text("어느 곡이 주제에 더 어울려요?")
          .wepliFont(.button)
          .foregroundStyle(WePLiColor.textPrimary)
      }
      .allowsHitTesting(false)
      .frame(maxHeight: .infinity, alignment: .top)
      .padding(.top, 54)
      // GeometryReader 내용은 body 밖에서 그려지므로 진행률은 미리 읽어 둔다
      let progress = self.store.bracket.progress
      VStack(alignment: .leading, spacing: 8) {
        GeometryReader { proxy in
          ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.18))
            Capsule().fill(WePLiColor.accent).frame(width: proxy.size.width * progress)
          }
        }
        .frame(height: 3)
        .animation(.easeInOut(duration: 0.3), value: self.store.bracket.progress)
        Text("더 어울리는 쪽을 누르세요")
          .wepliFont(.caption, weight: .light)
          .foregroundStyle(WePLiColor.textTertiary)
      }
      .allowsHitTesting(false)
      .padding(.horizontal, 20)
      .padding(.bottom, 10)
      .frame(maxHeight: .infinity, alignment: .bottom)
    }
    .animation(.easeInOut(duration: 0.2), value: self.store.bracket.completedMatches)
  }

  private var resultButtons: some View {
    VStack(spacing: 4) {
      Button {
        self.store.send(.shareTapped)
      } label: {
        Text("결과 공유하기")
          .wepliFont(.button)
          .foregroundStyle(WePLiColor.textOnCTA)
          .frame(maxWidth: .infinity)
          .frame(height: 54)
          .background(Capsule().fill(WePLiGradient.cta))
      }
      .buttonStyle(.plain)
      Button("다시 하기") { self.store.send(.restartTapped) }
        .wepliFont(.body)
        .foregroundStyle(WePLiColor.textTertiary)
        .frame(height: 44)
    }
  }

  private func result(_ champion: WorldCupSong) -> some View {
    VStack(spacing: 14) {
      Text("나의 우승곡")
        .wepliFont(.footnote, weight: .semibold)
        .foregroundStyle(WePLiColor.accent)
      RoundedRectangle(cornerRadius: 18)
        .fill(WePLiColor.imagePlaceholder)
        .frame(width: 230, height: 230)
        .overlay {
          Image(systemName: "music.note")
            .font(.system(size: 54, weight: .light))
            .foregroundStyle(WePLiColor.textQuaternary)
        }
        .shadow(color: .black.opacity(0.55), radius: 35, y: 30)
        .accessibilityHidden(true)
      Text(champion.title)
        .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 26, relativeTo: .title))
        .foregroundStyle(WePLiColor.textPrimary)
        .multilineTextAlignment(.center)
      Text("\(champion.artist) · 추천 \(champion.recommender)")
        .wepliFont(.body)
        .foregroundStyle(WePLiColor.textMuted)
      if let crowd = self.store.crowd {
        (Text("다른 사람들의 우승곡 · ")
          + Text(crowd.summary(championID: champion.id)).font(.custom(
            WePLiFont.Weight.semibold.postScriptName,
            size: 13,
            relativeTo: .footnote
          )).foregroundColor(WePLiColor.textPrimary))
          .wepliFont(.footnote, weight: .light)
          .foregroundStyle(WePLiColor.textTertiary)
          .multilineTextAlignment(.center)
          .padding(.top, 6)
      }
      Spacer()
      self.resultButtons
    }
    .padding(.horizontal, 28)
    .padding(.top, 64)
    .padding(.bottom, 8)
  }
}

#Preview {
  NavigationStack {
    SongWorldCupView(store: Store(initialState: SongWorldCupFeature.State(
      relayID: "summer-idol",
      topic: "첫 사랑이 생각나는 노래 모음"
    )) {
      SongWorldCupFeature()
    })
  }
}
