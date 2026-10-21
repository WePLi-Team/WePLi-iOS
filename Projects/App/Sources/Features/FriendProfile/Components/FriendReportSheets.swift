import ComposableArchitecture
import SwiftUI

// UI-17d · DEC-029 — 신고 시트(13g 보완). 사유 5개 중 하나, 「기타」면 사유 입력칸(필수 · 200자)
// → 「신고를 접수했어요」(바로 차단). 같은 사람을 다시 신고하면 「이미 신고했어요」와 신고한 날 · 사유 · 진행 상태

/// 신고 — 고른 줄만 라벤더 + 체크, 「기타」 밑에 사유 입력칸
struct FriendReportSheet: View {
  let store: StoreOf<FriendProfileFeature>
  let name: String

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text("신고하기").wepliFont(.title3).foregroundStyle(WePLiColor.textPrimary)
        Text(FriendProfileText.reportSubtitle(self.name))
          .wepliFont(.footnote, weight: .light)
          .foregroundStyle(WePLiColor.textTertiary)
      }
      .padding(EdgeInsets(top: 6, leading: 8, bottom: 0, trailing: 8))
      VStack(spacing: 0) {
        ForEach(ReportReason.allCases, id: \.self) { reason in
          self.reasonRow(reason)
        }
        if self.store.reportReason == .other {
          self.detailField
        }
      }
      .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
      Text(FriendProfileText.reportNotice)
        .wepliFont(.caption, weight: .light)
        .foregroundStyle(WePLiColor.textQuaternary)
        .padding(.horizontal, 8)
      Spacer(minLength: 0)
      WePLiPrimaryButton(title: "신고하기", isEnabled: self.store.canSubmitReport) {
        self.store.send(.menu(.reportSubmitted))
      }
    }
    .padding(EdgeInsets(top: 20, leading: 12, bottom: 24, trailing: 12))
    .animation(.easeOut(duration: 0.2), value: self.store.reportReason)
    .wepliSheetStyle(detents: [.large])
  }

  private func reasonRow(_ reason: ReportReason) -> some View {
    let isOn = self.store.reportReason == reason
    return Button {
      self.store.send(.menu(.reasonSelected(reason)))
    } label: {
      HStack(spacing: 10) {
        Text(reason.title)
          .wepliFont(.callout)
          .foregroundStyle(isOn ? WePLiColor.accent : WePLiColor.textPrimary)
        Spacer()
        WePLiSelectionCheck(isOn: isOn)
      }
      .padding(.horizontal, 18)
      .frame(height: 50)
      .contentShape(Rectangle())
      .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5) }
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
  }

  /// 「기타」 사유 — 높이 76, 글자 수 오른쪽
  private var detailField: some View {
    VStack(alignment: .trailing, spacing: 4) {
      TextField(
        FriendProfileText.reportDetailPlaceholder,
        text: Binding(get: { self.store.reportDetail }, set: { self.store.send(.menu(.reportDetailChanged($0))) }),
        axis: .vertical
      )
      .wepliFont(.body)
      .foregroundStyle(WePLiColor.textPrimary)
      .lineLimit(3, reservesSpace: true)
      .frame(minHeight: 76, alignment: .topLeading)
      .accessibilityLabel("신고 사유")
      Text("\(self.store.reportDetail.count)/\(FriendProfileText.reportDetailLimit)")
        .wepliFont(.caption)
        .monospacedDigit()
        .foregroundStyle(WePLiColor.textDisabled)
    }
    .padding(EdgeInsets(top: 12, leading: 18, bottom: 10, trailing: 18))
  }
}

/// 신고를 접수했어요 — 체크 · 안내 2줄 · 차단하기(이미 차단했으면 숨김) · 닫기
struct FriendReportDoneSheet: View {
  let store: StoreOf<FriendProfileFeature>
  let name: String

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "checkmark")
        .font(.system(size: 34, weight: .semibold))
        .foregroundStyle(WePLiColor.accent)
        .frame(width: 40, height: 40)
        .accessibilityHidden(true)
      Text(FriendProfileText.reportDoneTitle).wepliFont(.title3).foregroundStyle(WePLiColor.textPrimary)
      Text(FriendProfileText.reportDoneDetail)
        .wepliFont(.subheadline, weight: .light)
        .foregroundStyle(WePLiColor.textSecondary)
        .multilineTextAlignment(.center)
      VStack(spacing: 10) {
        FriendReportActions(store: self.store, name: self.name)
        Button("닫기") { self.store.send(.menu(.dismissed)) }
          .wepliFont(.body)
          .foregroundStyle(WePLiColor.accent)
          .frame(maxWidth: .infinity)
          .frame(height: 40)
          .buttonStyle(.plain)
      }
      .padding(.top, 14)
    }
    .padding(EdgeInsets(top: 30, leading: 20, bottom: 24, trailing: 20))
    .wepliSheetStyle(detents: [.height(340)])
  }
}

/// 이미 신고했어요 — 신고한 날 · 사유 · 진행 상태, 차단하기, 내 문의 내역에서 보기
struct FriendReportExistingSheet: View {
  let store: StoreOf<FriendProfileFeature>
  let name: String
  let report: FriendReport

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(FriendProfileText.reportExistingTitle).wepliFont(.title3).foregroundStyle(WePLiColor.textPrimary)
        Text(FriendProfileText.reportExistingDetail)
          .wepliFont(.subheadline, weight: .light)
          .foregroundStyle(WePLiColor.textSecondary)
      }
      .padding(EdgeInsets(top: 6, leading: 8, bottom: 0, trailing: 8))
      VStack(spacing: 0) {
        self.infoRow("신고한 날", FriendProfileText.reportDate(self.report.date))
        self.infoRow("사유", self.report.reason.title)
        self.infoRow("진행 상태", self.report.status.title, isStatus: true)
      }
      .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
      VStack(spacing: 10) {
        FriendReportActions(store: self.store, name: self.name)
        Button("내 문의 내역에서 보기") { self.store.send(.menu(.reportHistoryTapped)) }
          .wepliFont(.body)
          .foregroundStyle(WePLiColor.accent)
          .frame(maxWidth: .infinity)
          .frame(height: 40)
          .buttonStyle(.plain)
      }
      .padding(.top, 4)
      Spacer(minLength: 0)
    }
    .padding(EdgeInsets(top: 20, leading: 12, bottom: 24, trailing: 12))
    .wepliSheetStyle(detents: [.height(420)])
  }

  private func infoRow(_ label: String, _ value: String, isStatus: Bool = false) -> some View {
    HStack {
      Text(label).wepliFont(.body).foregroundStyle(WePLiColor.textTertiary)
      Spacer()
      Text(value)
        .wepliFont(.body, weight: isStatus ? .semibold : .regular)
        .foregroundStyle(isStatus ? WePLiColor.accent : WePLiColor.textPrimary)
    }
    .padding(.horizontal, 18)
    .frame(height: 50)
    .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5) }
    .accessibilityElement(children: .combine)
  }
}

/// 「{이름} 님 차단하기」 — 차단 확인 창으로. 이미 차단했으면 보이지 않는다
private struct FriendReportActions: View {
  let store: StoreOf<FriendProfileFeature>
  let name: String

  var body: some View {
    if !self.store.isBlocked {
      ExportSecondaryButton(title: FriendProfileText.reportBlock(self.name)) {
        self.store.send(.menu(.reportBlockTapped))
      }
    }
  }
}
