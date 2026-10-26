import ComposableArchitecture
import SwiftUI

// REQ-050 · UI-11b — 음악 서비스: 연결 · 기본으로 담을 곳 · 완성되면 자동으로 담기 · 내보낸 플레이리스트

struct MusicServicesView: View {
  let store: StoreOf<MusicServicesFeature>

  var body: some View {
    WithPerceptionTracking {
      ScrollView {
        if let settings = self.store.settings {
          VStack(alignment: .leading, spacing: 24) {
            self.section("연결") {
              ForEach(Array(settings.connections.enumerated()), id: \.element.id) { index, connection in
                self.connectionRow(connection, isLast: index == settings.connections.count - 1)
              }
            }
            self.section("기본으로 담을 곳") {
              ForEach(settings.destinations) { connection in
                self.defaultRow(connection, isSelected: settings.defaultService == connection.service.exportService)
              }
            }
            self.autoExport(settings.autoExport)
            if !settings.exported.isEmpty {
              self.section("내보낸 플레이리스트") {
                ForEach(settings.exported) { row in
                  self.exportedRow(row)
                }
              }
            }
          }
          .padding(.horizontal, 16)
          .padding(.top, 18)
          .padding(.bottom, 60)
        } else if self.store.loadFailed {
          self.failed
        } else {
          ProgressView().tint(WePLiColor.textTertiary).frame(maxWidth: .infinity, minHeight: 300)
        }
      }
      .safeAreaInset(edge: .top, spacing: 0) { self.navigationBar }
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .wepliToast(self.store.toast) { self.store.send(.toastDismissed) }
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private var navigationBar: some View {
    ZStack {
      Text("음악 서비스").wepliFont(.button).foregroundStyle(WePLiColor.textPrimary).accessibilityAddTraits(.isHeader)
      HStack {
        WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") { self.store.send(.backButtonTapped) }
        Spacer()
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
    .background(WePLiColor.background)
  }

  private var failed: some View {
    VStack(spacing: 12) {
      // 원본에 오류 화면이 없어 임시 문구 — 디자인 확인 필요
      Text("음악 서비스 설정을 불러오지 못했어요")
        .wepliFont(.callout, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
      Button("다시 시도") { self.store.send(.retryButtonTapped) }
        .wepliFont(.subheadline, weight: .semibold)
        .foregroundStyle(WePLiColor.accent)
    }
    .frame(maxWidth: .infinity, minHeight: 300)
  }

  private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .wepliFont(.footnote)
        .foregroundStyle(WePLiColor.textQuaternary)
        .padding(.horizontal, 16)
        .accessibilityAddTraits(.isHeader)
      VStack(spacing: 0) { content() }
        .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 20))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
  }

  private func connectionRow(_ connection: MusicServiceConnection, isLast: Bool) -> some View {
    HStack(spacing: 12) {
      MusicConnectionIcon(service: connection.service)
      VStack(alignment: .leading, spacing: 2) {
        Text(connection.service.name).wepliFont(.body, weight: .medium).foregroundStyle(WePLiColor.textPrimary)
        Text(connection.status).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
      }
      Spacer(minLength: 8)
      self.connectionButton(connection)
    }
    .padding(.leading, 12)
    .padding(.trailing, 16)
    .frame(height: 64)
    .overlay(alignment: .bottom) {
      if !isLast {
        ExportDivider().padding(.leading, 62)
      }
    }
  }

  private func connectionButton(_ connection: MusicServiceConnection) -> some View {
    let isConnected = connection.isConnected
    return Button {
      self.store.send(isConnected ? .disconnectTapped(connection.service) : .connectTapped(connection.service))
    } label: {
      Text(isConnected ? "연결 해제" : "연결하기")
        .wepliFont(.footnote, weight: .semibold)
        .foregroundStyle(isConnected ? WePLiColor.textTertiary : WePLiColor.textOnCTA)
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(isConnected ? WePLiColor.disabledFill : WePLiColor.accent, in: Capsule())
    }
    .buttonStyle(.plain)
    .disabled(self.store.connecting != nil)
    .accessibilityLabel("\(connection.service.name) \(isConnected ? "연결 해제" : "연결하기")")
  }

  private func defaultRow(_ connection: MusicServiceConnection, isSelected: Bool) -> some View {
    Button {
      if let service = connection.service.exportService {
        self.store.send(.defaultSelected(service))
      }
    } label: {
      HStack {
        Text(connection.service.name).wepliFont(.body)
          .foregroundStyle(isSelected ? WePLiColor.accent : WePLiColor.textPrimary)
        Spacer()
        if isSelected {
          ExportCheck(size: 20)
        }
      }
      .padding(.horizontal, 16)
      .frame(height: 50)
      .contentShape(Rectangle())
      .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5) }
    }
    .buttonStyle(.plain)
    // 연결된 서비스만 고를 수 있다
    .opacity(connection.isConnected ? 1 : 0.35)
    .disabled(!connection.isConnected)
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
  }

  private func autoExport(_ isOn: Bool) -> some View {
    Toggle(isOn: Binding(get: { isOn }, set: { self.store.send(.autoExportToggled($0)) })) {
      VStack(alignment: .leading, spacing: 2) {
        Text("완성되면 자동으로 담기").wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
        Text("곡을 추천하거나 투표한 릴레이가 끝나면 바로 담아요")
          .wepliFont(.caption)
          .foregroundStyle(WePLiColor.textQuaternary)
      }
    }
    .tint(WePLiColor.accent)
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .frame(minHeight: 62)
    .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 20))
  }

  private func exportedRow(_ row: ExportedPlaylistRow) -> some View {
    Button {
      self.store.send(.exportedTapped(row.id))
    } label: {
      HStack(spacing: 12) {
        ExportArtwork(size: 40, radius: 8)
        VStack(alignment: .leading, spacing: 2) {
          Text(row.title).wepliFont(.subheadline).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
          Text("\(row.service.name) · \(row.dateText)").wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
        }
        Spacer(minLength: 8)
        Text(row.state.title)
          .wepliFont(.caption, weight: .semibold)
          .foregroundStyle(row.state == .syncing ? WePLiColor.accent : WePLiColor.textQuaternary)
      }
      .padding(.leading, 12)
      .padding(.trailing, 16)
      .frame(height: 64)
      .contentShape(Rectangle())
      .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5) }
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  NavigationStack {
    MusicServicesView(store: Store(initialState: MusicServicesFeature.State()) {
      MusicServicesFeature()
    })
  }
}

/// 서비스 아이콘 38 — 로고 에셋이 붙기 전까지 자리 표시(Last.fm은 지금 듣는 중 표시)
private struct MusicConnectionIcon: View {
  let service: MusicConnectionService

  var body: some View {
    if let exportService = self.service.exportService {
      ExportServiceIcon(service: exportService, size: 38)
    } else {
      RoundedRectangle(cornerRadius: 38 * 0.25)
        .fill(WePLiColor.surface4)
        .frame(width: 38, height: 38)
        .overlay {
          Image(systemName: "dot.radiowaves.left.and.right")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(WePLiColor.textMuted)
        }
        .accessibilityHidden(true)
    }
  }
}
