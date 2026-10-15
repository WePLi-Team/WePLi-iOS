import ComposableArchitecture
import SwiftUI

// REQ-031 · UI-3c — 릴레이리스트 상세 · 상태

struct RelayDetailView: View {
  let store: StoreOf<RelayDetailFeature>

  enum Metric {
    static let coverHeight: CGFloat = 410
    static let rowHeight: CGFloat = 52
    static let buttonHeight: CGFloat = 54
  }

  var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        ScrollView {
          if let detail = self.store.detail, let display = self.store.displayState {
            VStack(alignment: .leading, spacing: 0) {
              RelayDetailHeader(detail: detail, display: display, now: self.store.now)
              VStack(alignment: .leading, spacing: 36) {
                if display == .completed {
                  self.completedActions
                }
                self.ranking(detail: detail, display: display)
              }
              .padding(.horizontal, 20)
              .padding(.top, 24)
            }
            .padding(.bottom, 150)
          } else if self.store.loadFailed {
            self.failure
          } else {
            ProgressView()
              .tint(WePLiColor.textTertiary)
              .frame(maxWidth: .infinity, minHeight: 400)
          }
        }
        .ignoresSafeArea(edges: .top)

        self.topButtons
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        if let display = self.store.displayState {
          self.bottomButtons(display)
        }
      }
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .onAppear { self.store.send(.onAppear) }
      .onDisappear { self.store.send(.onDisappear) }
    }
  }

  // MARK: 위 · 아래 고정

  private var topButtons: some View {
    HStack {
      WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") {
        self.store.send(.backButtonTapped)
      }
      Spacer()
      WePLiIconButton(systemName: "square.and.arrow.up", accessibilityLabel: "공유") {
        self.store.send(.shareButtonTapped)
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
  }

  private func bottomButtons(_ display: RelayDisplayState) -> some View {
    // 너비 비율: 진행 중 1 : 1.5, 완성 1 : 1.3 (UI-3c)
    GeometryReader { proxy in
      let spacing: CGFloat = 10
      let available = proxy.size.width - spacing
      HStack(spacing: spacing) {
        switch display {
        case .empty:
          WePLiPrimaryButton(title: "노래 추천하기") { self.store.send(.recommendButtonTapped) }
        case .live:
          RelayGlassButton(title: "노래 추천", systemImage: "plus") { self.store.send(.recommendButtonTapped) }
            .frame(width: available / 2.5)
          WePLiPrimaryButton(title: "투표하기") { self.store.send(.voteButtonTapped) }
        case .completed:
          RelayGlassButton(title: "내 플리에 담기", systemImage: "text.badge.plus") {
            self.store.send(.addToMyPlaylistButtonTapped)
          }
          .frame(width: available / 2.3)
          WePLiPrimaryButton(title: "전체 듣기") { self.store.send(.playAllButtonTapped) }
        }
      }
    }
    .frame(height: Metric.buttonHeight)
    .padding(.horizontal, 20)
    .padding(.top, 12)
    .padding(.bottom, 8)
    .background(alignment: .bottom) {
      LinearGradient(
        stops: [.init(color: .black.opacity(0), location: 0), .init(color: .black.opacity(0.9), location: 0.55)],
        startPoint: .top,
        endPoint: .bottom
      )
      .frame(height: 150)
      .ignoresSafeArea(edges: .bottom)
      .allowsHitTesting(false)
    }
  }

  // MARK: 완성 — 위쪽 「전체 재생 · 내 음악 앱으로」(2026-10-15 갱신)

  private var completedActions: some View {
    HStack(spacing: 10) {
      Button {
        self.store.send(.playAllButtonTapped)
      } label: {
        Label("전체 재생", systemImage: "play.fill")
          .wepliFont(.callout, weight: .semibold)
          .foregroundStyle(WePLiColor.textOnCTA)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(Capsule().fill(WePLiGradient.cta))
      }
      .buttonStyle(.plain)
      Button {
        self.store.send(.exportButtonTapped)
      } label: {
        Text("내 음악 앱으로")
          .wepliFont(.callout, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(WePLiColor.secondaryButtonFill, in: Capsule())
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: 순위

  private func ranking(detail: RelayDetail, display: RelayDisplayState) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .firstTextBaseline, spacing: 10) {
        Text(display == .completed ? "최종 순위" : "현재 곡 순위")
          .wepliFont(.headline)
          .foregroundStyle(WePLiColor.textPrimary)
          .accessibilityAddTraits(.isHeader)
        Text("총 \(display == .empty ? 0 : detail.participantCount)명 참여")
          .wepliFont(.caption, weight: .light)
          .foregroundStyle(WePLiColor.textSecondary)
      }
      if display == .empty || detail.ranking.isEmpty {
        RelayEmptySongsCard()
      } else {
        VStack(spacing: 12) {
          ForEach(detail.ranking) { song in
            RankedSongRow(song: song) { self.store.send(.songPlayTapped(song.id)) }
          }
        }
      }
    }
  }

  private var failure: some View {
    // 원본에 오류 화면이 없어 임시 문구 — 디자인 확인 필요
    VStack(spacing: 12) {
      Text("릴레이리스트를 불러오지 못했어요")
        .wepliFont(.callout, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
      Button("다시 시도") { self.store.send(.retryButtonTapped) }
        .wepliFont(.body, weight: .semibold)
        .foregroundStyle(WePLiColor.accent)
    }
    .frame(maxWidth: .infinity, minHeight: 400)
  }
}

#Preview {
  NavigationStack {
    RelayDetailView(store: Store(initialState: RelayDetailFeature.State(relayID: "first-love")) {
      RelayDetailFeature()
    })
  }
}
