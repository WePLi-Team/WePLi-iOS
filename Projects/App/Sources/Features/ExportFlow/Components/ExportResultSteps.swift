import ComposableArchitecture
import SwiftUI

// UI-14k 담기 완료 · 14o 곡 목록으로 옮기기

struct ExportDoneStep: View {
  let store: StoreOf<ExportFlowFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        HStack {
          WePLiIconButton(systemName: "xmark", accessibilityLabel: "닫기") { self.store.send(.closeTapped) }
          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        Spacer(minLength: 0)
        self.summary
        Spacer(minLength: 0)
        self.actions
      }
    }
  }

  private var summary: some View {
    VStack(spacing: 0) {
      ExportArtwork(size: 210, radius: 14)
        .shadow(color: .black.opacity(0.55), radius: 30, y: 24)
        .overlay(alignment: .bottomTrailing) {
          ExportServiceIcon(service: self.store.service, size: 46).offset(x: 10, y: 10)
        }
      Text("\(self.store.service.name)에 담았어요")
        .wepliFont(.title2, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
        .padding(.top, 34)
      Text("\(self.store.addedCount)곡 · ‘\(self.store.name)’")
        .wepliFont(.subheadline, weight: .light)
        .multilineTextAlignment(.center)
        .foregroundStyle(WePLiColor.textSecondary)
        .padding(.top, 8)
      if self.store.service == .appleMusic {
        Text("보관함 › 플레이리스트에서 찾을 수 있어요")
          .wepliFont(.caption, weight: .light)
          .foregroundStyle(WePLiColor.textQuaternary)
          .padding(.top, 4)
      }
    }
    .padding(.horizontal, 24)
  }

  private var actions: some View {
    VStack(spacing: 10) {
      ExportToggleRow(
        title: "다음 릴레이부터 자동으로 담기",
        detail: "추천하거나 투표한 릴레이가 완성되면 바로",
        isOn: self.store.autoExport
      ) { self.store.send(.autoExportToggled($0)) }
        .padding(.bottom, 8)
      WePLiPrimaryButton(title: "\(self.store.service.name)에서 열기") { self.store.send(.openInServiceTapped) }
      // 원본에 공유 대상이 없다 — 위플리 릴레이 링크를 보낸다(BusinessCard · SongShare와 같은 임시 주소)
      ShareLink(item: ExportText.relayLink(self.store.relayID)) {
        Text("친구에게 공유")
          .wepliFont(.body, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(WePLiColor.secondaryButtonFill, in: Capsule())
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 40)
  }
}

struct ExportCopyListStep: View {
  let store: StoreOf<ExportFlowFeature>

  var body: some View {
    WithPerceptionTracking {
      let lines = self.store.listFormat.lines(self.store.selectedSongs)
      VStack(alignment: .leading, spacing: 0) {
        ExportSheetNavBar(leading: "닫기", title: "곡 목록으로 옮기기") { self.store.send(.backTapped) }
        VStack(alignment: .leading, spacing: 16) {
          Text(
            "멜론 · 지니 · FLO · VIBE는 다른 앱이 플레이리스트를 만들 수 있는 공개 연동이 없어요. 목록을 복사해 각 앱에서 검색해 담을 수 있어요."
          )
          .wepliFont(.subheadline, weight: .light)
          .foregroundStyle(WePLiColor.textSecondary)
          HStack(spacing: 8) {
            ForEach(ExportListFormat.allCases, id: \.self) { format in
              WePLiChip(title: format.title, isOn: self.store.listFormat == format) {
                self.store.send(.listFormatSelected(format))
              }
            }
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        ScrollView {
          VStack(alignment: .leading, spacing: 12) {
            ForEach(lines, id: \.self) { line in
              Text(line).wepliFont(.body, weight: .light).monospacedDigit().foregroundStyle(WePLiColor.textMuted)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 20)
          .padding(.vertical, 18)
        }
        self.buttons(text: lines.joined(separator: "\n"))
      }
    }
  }

  private func buttons(text: String) -> some View {
    HStack(spacing: 10) {
      WePLiPrimaryButton(
        title: self.store.isCopied ? "복사했어요" : "\(self.store.selectedSongs.count)곡 목록 복사"
      ) { self.store.send(.copyTapped) }
      ShareLink(item: text) {
        Image(systemName: "square.and.arrow.up")
          .font(.system(size: 19, weight: .medium))
          .foregroundStyle(WePLiColor.textPrimary)
          .frame(width: 54, height: 54)
          .background(WePLiColor.secondaryButtonFill, in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("공유")
    }
    .padding(.horizontal, 20)
    .padding(.top, 12)
    .padding(.bottom, 40)
  }
}
