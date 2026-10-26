import ComposableArchitecture
import SwiftUI

// REQ-050 · UI-14l — 지금 순위로 먼저 담기. 3단계 흐름(지금 → 마감 전 → 마감)과 자동 반영 스위치

struct LiveExportView: View {
  @Perception.Bindable var store: StoreOf<LiveExportFeature>

  @Dependency(\.date.now)
  private var now

  var body: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: 6) {
        VStack(alignment: .leading, spacing: 4) {
          Text("지금 순위로 먼저 담아 둘까요?").wepliFont(.title3).foregroundStyle(WePLiColor.textPrimary)
          Text("마감까지 \(ExportText.untilDeadline(from: self.now, to: self.store.endsAt)) · 지금 TOP \(self.count)를 담아요")
            .wepliFont(.footnote, weight: .light)
            .foregroundStyle(WePLiColor.textTertiary)
        }
        .padding(.vertical, 12)
        self.timeline
        ExportToggleRow(
          title: "마감까지 순위 자동 반영",
          isOn: self.store.autoSync
        ) { self.store.send(.autoSyncToggled($0)) }
        self.serviceRow
        Spacer(minLength: 0)
        WePLiPrimaryButton(
          title: "\(self.store.service.name)에 먼저 담기",
          isEnabled: !self.store.isExporting && !self.store.songs.isEmpty
        ) { self.store.send(.exportTapped) }
          .padding(.top, 10)
      }
      .padding(.horizontal, 20)
      .padding(.top, 20)
      .padding(.bottom, 24)
      .wepliToast(self.store.toast) { self.store.send(.toastDismissed) }
    }
  }

  private var count: Int {
    self.store.songs.count
  }

  private var timeline: some View {
    let isOn = self.store.autoSync
    return VStack(alignment: .leading, spacing: 0) {
      LiveExportStep(
        dot: .now,
        title: "지금 · 현재 TOP \(self.count)를 담아요",
        detail: ExportText.liveTop(self.store.songs.map(\.title)),
        hasLine: true
      )
      LiveExportStep(
        dot: .live,
        title: "마감 전 · 순위가 바뀌면 반영해요",
        detail: "새로 들어온 곡은 넣고, 밀려난 곡은 빼요",
        hasLine: true
      )
      .opacity(isOn ? 1 : 0.35)
      LiveExportStep(
        dot: .end,
        title: isOn ? "마감 · 최종 \(self.count)곡으로 고정돼요" : "마감 · 지금 담은 \(self.count)곡이 그대로 남아요",
        detail: isOn ? "이후로는 바뀌지 않아요" : "최종 순위와 달라질 수 있어요",
        hasLine: false
      )
    }
    .animation(.easeOut(duration: 0.2), value: isOn)
  }

  private var serviceRow: some View {
    Button {
      self.store.send(.serviceTapped)
    } label: {
      HStack(spacing: 8) {
        Text("담을 곳").wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
        Spacer()
        ExportServiceIcon(service: self.store.service, size: 22)
        Text(self.store.service.name).wepliFont(.body, weight: .light).foregroundStyle(WePLiColor.textTertiary)
        Image(systemName: "chevron.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(WePLiColor.textDisabled)
      }
      .frame(height: 52)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

/// 흐름 한 단계 — 점 · 세로선 · 제목 · 설명
private struct LiveExportStep: View {
  enum Dot {
    case now
    case live
    case end
  }

  let dot: Dot
  let title: String
  let detail: String
  let hasLine: Bool

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(spacing: 4) {
        self.dotView().frame(width: 10, height: 10).padding(.top, 5)
        if self.hasLine {
          Rectangle().fill(Color.white.opacity(0.14)).frame(width: 1.5).frame(minHeight: 22)
        }
      }
      .frame(width: 12)
      VStack(alignment: .leading, spacing: 2) {
        Text(self.title).wepliFont(.body, weight: .medium).foregroundStyle(WePLiColor.textPrimary)
        Text(self.detail).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textTertiary)
      }
      .padding(.bottom, 16)
    }
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private func dotView() -> some View {
    switch self.dot {
    case .now: Circle().fill(WePLiColor.accent)
    case .live: Circle().fill(WePLiGradient.vsRing)
    case .end: Circle().fill(WePLiColor.textDisabled)
    }
  }
}

#Preview {
  Color.black.sheet(isPresented: .constant(true)) {
    LiveExportView(store: Store(initialState: LiveExportFeature.State(
      relayID: "cafe-bgm",
      title: "손님들이 물어보는 카페 BGM",
      endsAt: Date().addingTimeInterval(2 * 86400 + 4 * 3600),
      songs: ExportSample.songs
    )) {
      LiveExportFeature()
    })
    .wepliSheetStyle(detents: [.large])
  }
}
