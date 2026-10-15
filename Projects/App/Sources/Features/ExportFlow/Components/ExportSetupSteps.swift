import ComposableArchitecture
import SwiftUI

// UI-14c 서비스 선택 · 14d 담기 설정 · 14e Apple Music 접근 허용 · 14g Spotify 연결

struct ExportServiceStep: View {
  let store: StoreOf<ExportFlowFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: 4) {
        VStack(alignment: .leading, spacing: 4) {
          Text("어디로 담을까요?").wepliFont(.title3).foregroundStyle(WePLiColor.textPrimary)
          Text("완성된 \(self.store.songs.count)곡을 최종 순위대로 담아요")
            .wepliFont(.footnote, weight: .light)
            .foregroundStyle(WePLiColor.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 10)
        ForEach(ExportService.allCases, id: \.self) { service in
          self.row(service, isLast: service == ExportService.allCases.last)
        }
        Spacer(minLength: 0)
        WePLiPrimaryButton(title: "다음") { self.store.send(.serviceNextTapped) }
          .padding(.horizontal, 8)
          .padding(.top, 14)
      }
      .padding(.horizontal, 8)
      .padding(.bottom, 24)
    }
  }

  private func row(_ service: ExportService, isLast: Bool) -> some View {
    let isSelected = self.store.service == service
    return Button {
      self.store.send(.serviceSelected(service))
    } label: {
      HStack(spacing: 14) {
        ExportServiceIcon(service: service)
        VStack(alignment: .leading, spacing: 2) {
          Text(service.name).wepliFont(.callout, weight: .medium).foregroundStyle(WePLiColor.textPrimary)
          Text(self.detail(service))
            .wepliFont(.caption, weight: .light)
            .foregroundStyle(self.isConnected(service) ? WePLiColor.accent : WePLiColor.textTertiary)
        }
        Spacer()
        if isSelected {
          ExportCheck()
        }
      }
      .padding(.leading, 14)
      .padding(.trailing, 18)
      .frame(height: 66)
      .contentShape(Rectangle())
      .overlay(alignment: .bottom) {
        if !isLast {
          ExportDivider().padding(.leading, 68).padding(.trailing, 18)
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
  }

  private func isConnected(_ service: ExportService) -> Bool {
    self.store.connected.contains(service)
  }

  private func detail(_ service: ExportService) -> String {
    if service == .otherApps {
      return "곡 목록을 복사해 옮겨요"
    }
    // 원본은 「연결됨 · 지난번에 담은 곳」 — 지난번 기록이 없을 때 문구는 원본에 없다
    if self.isConnected(service) {
      return service == self.store.service ? "연결됨 · 지난번에 담은 곳" : "연결됨"
    }
    return "처음 한 번 계정 연결이 필요해요"
  }
}

struct ExportSettingsStep: View {
  let store: StoreOf<ExportFlowFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        ExportSheetNavBar(leading: "이전", title: "담기 설정") { self.store.send(.backTapped) }
        ScrollView {
          VStack(alignment: .leading, spacing: 26) {
            self.header
            self.songChoice
            self.options
          }
          .padding(.horizontal, 20)
          .padding(.top, 14)
        }
        .scrollDismissesKeyboard(.interactively)
        WePLiPrimaryButton(
          title: "\(self.store.service.name)에 \(self.store.selectedSongs.count)곡 담기",
          isEnabled: !self.store.selectedSongs.isEmpty
        ) { self.store.send(.addTapped) }
          .padding(.horizontal, 20)
          .padding(.top, 12)
          .padding(.bottom, 40)
      }
    }
  }

  private var header: some View {
    HStack(spacing: 16) {
      ExportArtwork(size: 76, radius: 8)
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 6) {
          ExportServiceIcon(service: self.store.service, size: 18)
          Text(self.serviceLine).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textTertiary)
        }
        TextField("플레이리스트 이름", text: Binding(
          get: { self.store.name },
          set: { self.store.send(.nameChanged($0)) }
        ))
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.textPrimary)
        .tint(WePLiColor.accent)
        .frame(height: 34)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.25)).frame(height: 0.5) }
      }
    }
  }

  private var serviceLine: String {
    switch self.store.service {
    case .appleMusic: "Apple Music 보관함"
    // YouTube Music은 원본에 없다 — Spotify와 같은 형식
    default: "\(self.store.service.name) · 담기 전에 계정을 연결해요"
    }
  }

  private var songChoice: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("담을 곡").wepliFont(.body, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
      HStack(spacing: 8) {
        // 투표한 곡이 없으면 「내가 투표한 0곡」은 뺀다
        ForEach(
          ExportSelection.allCases.filter { $0 != .voted || self.store.votedCount > 0 },
          id: \.self
        ) { selection in
          WePLiChip(
            title: selection.title(total: self.store.songs.count, votedCount: self.store.votedCount),
            isOn: self.store.selection == selection
          ) { self.store.send(.selectionSelected(selection)) }
        }
      }
      Text(ExportText.summary(self.store.selectedSongs))
        .wepliFont(.footnote, weight: .light)
        .foregroundStyle(WePLiColor.textTertiary)
    }
  }

  private var options: some View {
    VStack(alignment: .leading, spacing: 0) {
      ExportToggleRow(
        title: "설명에 크레딧 넣기",
        detail: "WePLi 릴레이 · 추천 \(self.store.recommenderCount)명 · 링크",
        isOn: self.store.includesCredit
      ) { self.store.send(.creditToggled($0)) }
      if self.store.service == .appleMusic {
        Text(
          "Apple Music에서는 커버를 따로 올릴 수 없어, 담은 곡의 앨범 커버를 모은 이미지로 보여요. 보관함 플레이리스트는 나만 볼 수 있어요."
        )
        .wepliFont(.caption, weight: .light)
        .foregroundStyle(WePLiColor.textQuaternary)
        .padding(.top, 12)
      } else {
        ExportToggleRow(
          title: "위플리 커버 함께 올리기",
          detail: "릴레이 대표 이미지를 플리 커버로 써요",
          isOn: self.store.uploadsCover
        ) { self.store.send(.coverToggled($0)) }
        self.visibilityRow
      }
    }
  }

  /// 공개 범위 — 원본에 고르는 화면이 없어 「비공개」로만 담는다
  private var visibilityRow: some View {
    HStack {
      Text("공개 범위").wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
      Spacer()
      Text("비공개").wepliFont(.body, weight: .light).foregroundStyle(WePLiColor.textTertiary)
    }
    .frame(height: 56)
    .overlay(alignment: .bottom) { ExportDivider() }
  }
}

/// 14e — 시스템 알림은 한 번 거절하면 다시 띄울 수 없어, 무엇을 하는지 먼저 설명하고 「계속」에서 띄운다
struct ExportPermissionStep: View {
  let store: StoreOf<ExportFlowFeature>

  private static let points = [
    "보관함에 위플리 플레이리스트를 새로 만들어요",
    "마감까지 순위가 바뀌면 그 플리만 고쳐요",
    "다른 플레이리스트나 듣기 기록은 건드리지 않아요",
  ]

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 18) {
        Spacer(minLength: 0)
        ExportServiceIcon(service: .appleMusic, size: 64)
        Text("Apple Music 보관함에 담으려면\n접근 허용이 필요해요")
          .wepliFont(.title3)
          .multilineTextAlignment(.center)
          .foregroundStyle(WePLiColor.textPrimary)
        VStack(alignment: .leading, spacing: 12) {
          ForEach(Self.points, id: \.self) { point in
            HStack(alignment: .top, spacing: 10) {
              ExportCheck(size: 18).padding(.top, 1)
              Text(point).wepliFont(.subheadline, weight: .light).foregroundStyle(WePLiColor.textMuted)
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        Spacer(minLength: 0)
        VStack(spacing: 4) {
          WePLiPrimaryButton(title: "계속", isEnabled: !self.store.isConnecting) {
            self.store.send(.connectTapped)
          }
          ExportTextButton(title: "나중에") { self.store.send(.laterTapped) }
        }
        .padding(.top, 6)
      }
      .padding(.horizontal, 24)
      .padding(.top, 30)
      .padding(.bottom, 24)
    }
  }
}
