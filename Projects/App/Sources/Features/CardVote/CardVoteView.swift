import ComposableArchitecture
import SwiftUI

// REQ-033 · UI-3b — 카드 투표

struct CardVoteView: View {
  @Perception.Bindable var store: StoreOf<CardVoteFeature>

  /// 드래그 위치는 화면 상태다(리듀서에는 투표 결과만 보낸다)
  @State private var offset: Double = 0
  @State private var isFlying = false

  @Environment(\.accessibilityReduceMotion)
  private var reduceMotion

  var body: some View {
    WithPerceptionTracking {
      ZStack {
        self.background
        if self.store.isDone {
          self.doneView
        } else if let current = self.store.current {
          self.voting(current)
        } else if self.store.loadFailed {
          // 원본에 오류 화면이 없어 임시 문구 — 디자인 확인 필요
          Text("투표할 곡을 불러오지 못했어요")
            .wepliFont(.callout, weight: .semibold)
            .foregroundStyle(WePLiColor.textPrimary)
        } else {
          ProgressView().tint(WePLiColor.textTertiary)
        }
      }
      .safeAreaInset(edge: .top, spacing: 0) { self.navigationBar }
      .toolbar(.hidden, for: .navigationBar)
      .wepliToast(self.$store.toast)
      .onAppear { self.store.send(.onAppear) }
    }
  }

  // MARK: 배경 · 내비게이션

  private var background: some View {
    ZStack {
      WePLiColor.background
      // 현재 곡 앨범 아트 블러(60) — 사진이 붙기 전까지 라벤더 빛으로 대신한다
      Circle()
        .fill(WePLiColor.accentChip.opacity(0.55))
        .frame(width: 560, height: 560)
        .blur(radius: 60)
        .offset(x: -40, y: -200)
      LinearGradient(
        stops: [
          .init(color: .black.opacity(0.35), location: 0),
          .init(color: .black.opacity(0.6), location: 0.5),
          .init(color: .black, location: 0.85),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    }
    .ignoresSafeArea()
    .accessibilityHidden(true)
  }

  private var navigationBar: some View {
    ZStack {
      Text("노래 투표하기")
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      HStack {
        WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") {
          self.store.send(.backButtonTapped)
        }
        Spacer()
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
  }

  // MARK: 진행 화면

  private func voting(_ current: VoteCandidate) -> some View {
    VStack(spacing: 0) {
      self.header(current)
      self.cardStack(current)
        .padding(.top, 22)
      Spacer(minLength: 16)
      self.voteButtons
      Text("카드를 좌우로 밀어도 투표할 수 있어요")
        .wepliFont(.caption)
        .foregroundStyle(WePLiColor.textDisabled)
        .padding(.top, 12)
    }
    .padding(.horizontal, 24)
    .padding(.top, 8)
    .padding(.bottom, 16)
  }

  private func header(_ current: VoteCandidate) -> some View {
    VStack(spacing: 0) {
      Text(self.store.topic)
        .wepliFont(.footnote)
        .foregroundStyle(WePLiColor.textTertiary)
      Text("이 곡, 주제와 어울리나요?")
        .wepliFont(.title2, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
        .padding(.top, 4)
      HStack(spacing: 8) {
        Text("\(self.store.index + 1) / \(self.store.candidates.count)")
          .wepliFont(.footnote, weight: .bold)
          .foregroundStyle(WePLiColor.accent)
          .monospacedDigit()
        Text("·")
          .wepliFont(.footnote)
          .foregroundStyle(WePLiColor.textDisabled)
        Text("총 \(CardVoteCount.string(current.voteCount))표 획득")
          .wepliFont(.footnote)
          .foregroundStyle(WePLiColor.textSecondary)
      }
      .padding(.top, 12)
    }
  }

  private func cardStack(_ current: VoteCandidate) -> some View {
    ZStack(alignment: .top) {
      if self.store.next != nil {
        // 뒤 카드는 아트만, 위로 살짝 비친다(UI-3b 2026-10-15)
        VoteArt()
          .scaleEffect(0.92)
          .offset(y: -16)
          .opacity(0.3)
          .accessibilityHidden(true)
      }
      VoteCard(
        candidate: current,
        onPlay: { self.store.send(.playTapped(current.id)) },
        fitsOpacity: self.stampOpacity(.fits),
        missOpacity: self.stampOpacity(.doesNotFit)
      )
      .offset(x: self.offset)
      .rotationEffect(.degrees(self.reduceMotion ? 0 : CardSwipe.rotation(for: self.offset)))
      .gesture(self.dragGesture)
      .id(current.id)
      .accessibilityAction(named: "주제와 어울려요") { self.vote(.fits) }
      .accessibilityAction(named: "별로인 것 같아요") { self.vote(.doesNotFit) }
    }
  }

  private var voteButtons: some View {
    HStack(spacing: 12) {
      Button {
        self.vote(.doesNotFit)
      } label: {
        HStack(spacing: 6) {
          Image(systemName: "hand.thumbsdown")
            .foregroundStyle(WePLiColor.textMuted)
          Text("별로인 것 같아요")
            .foregroundStyle(WePLiColor.textPrimary)
        }
        .wepliFont(.body, weight: .semibold)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .wepliGlass(in: Capsule())
      }
      .buttonStyle(.plain)
      Button {
        self.vote(.fits)
      } label: {
        Label("주제와 어울려요!", systemImage: "hand.thumbsup")
          .wepliFont(.body, weight: .semibold)
          .foregroundStyle(WePLiColor.textOnCTA)
          .frame(maxWidth: .infinity)
          .frame(height: 56)
          .background(Capsule().fill(WePLiGradient.cta))
      }
      .buttonStyle(.plain)
    }
    .disabled(self.isFlying)
  }

  private var dragGesture: some Gesture {
    DragGesture()
      .onChanged { value in
        guard !self.isFlying else { return }
        self.offset = value.translation.width
      }
      .onEnded { _ in
        guard !self.isFlying else { return }
        if let choice = CardSwipe.choice(forReleasedOffset: self.offset) {
          self.vote(choice)
        } else {
          withAnimation(.easeOut(duration: 0.24)) { self.offset = 0 }
        }
      }
  }

  /// 카드를 ±460으로 날린 뒤 0.24초 후 다음 카드로 (UI-3b)
  private func vote(_ choice: VoteChoice) {
    guard !self.isFlying else { return }
    self.isFlying = true
    withAnimation(.easeOut(duration: 0.24)) {
      self.offset = choice == .fits ? CardSwipe.flyOutDistance : -CardSwipe.flyOutDistance
    }
    Task { @MainActor in
      try? await Task.sleep(for: CardSwipe.advanceDelay)
      self.store.send(.voted(choice))
      self.offset = 0
      self.isFlying = false
    }
  }

  private func stampOpacity(_ choice: VoteChoice) -> Double {
    CardSwipe.stampOpacity(for: self.offset, toward: choice)
  }

  // MARK: 완료 화면

  private var doneView: some View {
    VStack(spacing: 12) {
      Image(systemName: "checkmark")
        .font(.system(size: 30, weight: .bold))
        .foregroundStyle(WePLiColor.textOnCTA)
        .frame(width: 76, height: 76)
        .background(WePLiColor.accent, in: Circle())
        .padding(.bottom, 8)
        .accessibilityHidden(true)
      Text("투표를 마쳤어요")
        .wepliFont(.title2, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
      Text("주제와 어울린다고 고른 곡은 \(self.store.fitsCount)곡이에요.\n남은 시간 동안 순위가 계속 바뀌어요.")
        .wepliFont(.body)
        .foregroundStyle(WePLiColor.textSecondary)
        .multilineTextAlignment(.center)
      VStack(spacing: 4) {
        WePLiPrimaryButton(title: "릴레이리스트로 돌아가기") { self.store.send(.returnToRelayButtonTapped) }
        Button("처음부터 다시 보기") { self.store.send(.restartButtonTapped) }
          .wepliFont(.body, weight: .medium)
          .foregroundStyle(WePLiColor.textTertiary)
          .frame(height: 48)
      }
      .padding(.top, 36)
    }
    .padding(.horizontal, 24)
  }
}

/// 「16,225」
enum CardVoteCount {
  static func string(_ count: Int) -> String {
    count.formatted(.number.locale(Locale(identifier: "en_US")))
  }
}

#Preview {
  NavigationStack {
    CardVoteView(store: Store(initialState: CardVoteFeature.State(relayID: "r", topic: "첫 사랑이 생각나는 노래 모음")) {
      CardVoteFeature()
    })
  }
}
