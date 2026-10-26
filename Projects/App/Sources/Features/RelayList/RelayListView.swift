import ComposableArchitecture
import SwiftUI

// REQ-030 · UI-10a — 릴레이 탭 첫 화면

struct RelayListView: View {
  let store: StoreOf<RelayListFeature>

  var body: some View {
    WithPerceptionTracking {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          self.header
          RelayFilterChips(selected: self.store.filter) { self.store.send(.filterSelected($0)) }
            .padding(.bottom, 6)
          self.content
        }
      }
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .onAppear { self.store.send(.onAppear) }
      .onDisappear { self.store.send(.onDisappear) }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Spacer()
        Button {
          self.store.send(.openRelayButtonTapped)
        } label: {
          Label("릴레이 열기", systemImage: "plus")
            .wepliFont(.body, weight: .semibold)
            .foregroundStyle(WePLiColor.textOnCTA)
            .padding(.leading, 12)
            .padding(.trailing, 16)
            .frame(height: 44)
            .background(WePLiColor.accent, in: Capsule())
        }
        .buttonStyle(.plain)
      }
      .frame(height: 48)
      .padding(.horizontal, 16)

      Text("릴레이")
        .wepliFont(.screenTitle)
        .foregroundStyle(WePLiColor.textPrimary)
        .padding(.horizontal, 20)
        .padding(.top, 2)
        .padding(.bottom, 14)
        .accessibilityAddTraits(.isHeader)
    }
  }

  @ViewBuilder private var content: some View {
    if self.store.isLoading, self.store.relays.isEmpty {
      VStack(spacing: 12) {
        ForEach(0 ..< 4, id: \.self) { _ in
          WePLiSongRowSkeleton()
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 12)
      .wepliPulse()
    } else if self.store.loadFailed {
      // 원본에 오류 화면이 없어 빈 상태 형식을 따른 임시 문구 — 디자인 확인 필요
      WePLiEmptyState(
        systemImage: "exclamationmark.triangle",
        title: "릴레이를 불러오지 못했어요",
        message: "잠시 후 다시 시도해 주세요.",
        actionTitle: "다시 시도",
        action: { self.store.send(.retryButtonTapped) }
      )
      .padding(.vertical, 60)
    } else if self.store.sections.isEmpty {
      VStack(spacing: 8) {
        Text("아직 참여한 릴레이가 없어요")
          .wepliFont(.callout, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
        Text("진행 중인 릴레이에 곡을 추천해 보세요")
          .wepliFont(.subheadline)
          .foregroundStyle(WePLiColor.textQuaternary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 60)
      .padding(.horizontal, 20)
    } else {
      let sections = self.store.sections
      if let featured = sections.featured {
        Button {
          self.store.send(.relayTapped(featured.id))
        } label: {
          RelayFeaturedCard(relay: featured, now: self.store.now)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
      }
      // 행은 SwiftUI가 body 밖에서 그리므로 store 값은 미리 읽어 둔다
      let now = self.store.now
      ForEach(sections.list) { relay in
        Button {
          self.store.send(.relayTapped(relay.id))
        } label: {
          RelayRow(relay: relay, now: now)
        }
        .buttonStyle(.plain)
      }
    }
  }
}

#Preview {
  NavigationStack {
    RelayListView(store: Store(initialState: RelayListFeature.State()) { RelayListFeature() })
  }
}
