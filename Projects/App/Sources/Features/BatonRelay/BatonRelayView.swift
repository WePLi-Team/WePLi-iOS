import ComposableArchitecture
import SwiftUI

// REQ-035 · UI-8c — 바통 릴레이. 달리는 사람 8명 · 이어진 곡 · 내 차례(남은 시간 · 곡 · 다음 키워드) · 넘기기
// 링크로 막 들어왔으면 초대 받기(UI-11c)를 먼저 보여준다.

struct BatonRelayView: View {
  let store: StoreOf<BatonRelayFeature>

  var body: some View {
    WithPerceptionTracking {
      Group {
        if let relay = self.store.relay {
          if self.store.showsInvite {
            BatonInviteView(store: self.store, relay: relay)
          } else {
            self.chain(relay)
          }
        } else if self.store.loadFailed {
          VStack(spacing: 12) {
            // 원본에 없는 문구 — 디자인 확인 필요
            Text("바통 릴레이를 불러오지 못했어요").wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
            Button("다시 시도") { self.store.send(.retryButtonTapped) }
              .wepliFont(.subheadline, weight: .semibold)
              .foregroundStyle(WePLiColor.accent)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          ProgressView().tint(WePLiColor.textTertiary).frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
      .background(WePLiColor.background.ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
      .animation(.easeInOut(duration: 0.25), value: self.store.showsInvite)
      .wepliToast(Binding(get: { self.store.toast }, set: {
        if $0 == nil {
          self.store.send(.toastDismissed)
        }
      }))
      .onAppear { self.store.send(.onAppear) }
      .onDisappear { self.store.send(.onDisappear) }
    }
  }

  private func chain(_ relay: BatonRelay) -> some View {
    VStack(spacing: 0) {
      HStack {
        WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") { self.store.send(.closeTapped) }
        Spacer()
      }
      .padding(.horizontal, 16)
      .frame(height: 48)
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          VStack(alignment: .leading, spacing: 6) {
            Text("바통 릴레이 · 친구 \(relay.total)명").wepliFont(.footnote, weight: .semibold)
              .foregroundStyle(WePLiColor.accent)
            Text(relay.title).wepliFont(.title1).foregroundStyle(WePLiColor.textPrimary)
              .accessibilityAddTraits(.isHeader)
            Text("앞사람이 남긴 키워드를 이어받아 한 곡씩 더해요. 내 차례는 24시간이에요.")
              .wepliFont(.subheadline, weight: .light)
              .foregroundStyle(WePLiColor.textSecondary)
          }
          .padding(.horizontal, 20)
          .padding(.top, 4)
          BatonRunnerRow(relay: relay).padding(.horizontal, 20).padding(.top, 18)
          VStack(alignment: .leading, spacing: 0) {
            ForEach(relay.chain) { link in
              BatonLinkRow(link: link)
            }
            self.turnSection(relay)
          }
          .padding(.horizontal, 20)
          .padding(.top, 22)
        }
        .padding(.bottom, 140)
      }
      .overlay(alignment: .bottom) { self.passButton(relay) }
    }
  }

  @ViewBuilder
  private func turnSection(_ relay: BatonRelay) -> some View {
    switch relay.turn {
    case let .mine(endsAt):
      BatonMyTurn(
        relay: relay,
        remaining: BatonText.clock(from: self.store.now, to: endsAt),
        pickID: self.store.pickID,
        keyword: self.store.keyword,
        onPick: { self.store.send(.pickTapped($0)) },
        onKeyword: { self.store.send(.keywordTapped($0)) }
      )
    case let .passed(keyword):
      HStack(spacing: 12) {
        Circle().fill(WePLiColor.imagePlaceholder).frame(width: 40, height: 40)
        VStack(alignment: .leading, spacing: 2) {
          Text("\(relay.nextRunner)님에게 바통을 넘겼어요").wepliFont(.body, weight: .semibold)
            .foregroundStyle(WePLiColor.textPrimary)
          Text("다음 키워드 \(keyword) · 이어지면 알려드릴게요").wepliFont(.footnote).foregroundStyle(WePLiColor.textTertiary)
        }
      }
      .padding(.leading, 32)
      .padding(.vertical, 8)
    default:
      EmptyView()
    }
  }

  @ViewBuilder
  private func passButton(_ relay: BatonRelay) -> some View {
    if case .mine = relay.turn {
      WePLiPrimaryButton(
        title: self.store.canPass ? "\(relay.nextRunner)님에게 바통 넘기기" : "곡과 키워드를 골라주세요",
        isEnabled: self.store.canPass
      ) { self.store.send(.passTapped) }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .padding(.top, 40)
        .background(WePLiGradient.bottomFade.allowsHitTesting(false))
    }
  }
}

#Preview {
  NavigationStack {
    BatonRelayView(store: Store(initialState: BatonRelayFeature.State(relayID: "rainy-night")) { BatonRelayFeature() })
  }
}
