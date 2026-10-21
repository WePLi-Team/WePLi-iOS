import ComposableArchitecture
import SwiftUI

// UI-13g · DEC-020 — ··· 메뉴 시트 · 차단 확인 창 · 차단한 사용자 화면 · 신고 시트

/// ··· 메뉴 — 프로필 공유하기 · 프로필 링크 복사 / 차단하기(차단했으면 차단 해제) · 신고하기
struct FriendProfileMenuSheet: View {
  let store: StoreOf<FriendProfileFeature>
  let profile: FriendProfile

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 12) {
        FriendAvatar(isListening: false, size: 40)
        VStack(alignment: .leading, spacing: 0) {
          Text(self.profile.name).wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
          Text(FriendProfileText.handle(self.profile.handle))
            .wepliFont(.footnote, weight: .light)
            .foregroundStyle(WePLiColor.textTertiary)
        }
        Spacer()
      }
      .padding(EdgeInsets(top: 6, leading: 8, bottom: 4, trailing: 8))
      FriendMenuGroup {
        if let url = FriendProfileText.link(self.profile) {
          ShareLink(item: url) { FriendMenuRow(title: "프로필 공유하기") }
        }
        Button { self.store.send(.menu(.copyLinkTapped)) } label: { FriendMenuRow(title: "프로필 링크 복사") }
      }
      FriendMenuGroup {
        // 차단한 뒤에는 메뉴에서도 풀 수 있게 한다(원본은 같은 메뉴를 다시 보임)
        if self.store.isBlocked {
          Button { self.store.send(.menu(.unblockTapped)) } label: { FriendMenuRow(title: "차단 해제") }
        } else {
          Button { self.store.send(.menu(.blockTapped)) } label: {
            FriendMenuRow(title: "차단하기", isDestructive: true)
          }
        }
        Button { self.store.send(.menu(.reportTapped)) } label: {
          FriendMenuRow(title: "신고하기", isDestructive: true)
        }
      }
      Spacer(minLength: 0)
    }
    .buttonStyle(.plain)
    .padding(EdgeInsets(top: 20, leading: 12, bottom: 24, trailing: 12))
    .wepliSheetStyle(detents: [.height(330)])
  }
}

private struct FriendMenuGroup<Content: View>: View {
  @ViewBuilder let content: Content

  var body: some View {
    VStack(spacing: 0) { self.content }
      .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
  }
}

private struct FriendMenuRow: View {
  let title: String
  var isDestructive = false

  var body: some View {
    Text(self.title)
      .wepliFont(.button, weight: .regular)
      .foregroundStyle(self.isDestructive ? WePLiColor.destructive : WePLiColor.textPrimary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 18)
      .frame(height: 52)
      .contentShape(Rectangle())
      .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5) }
  }
}

/// 차단 확인 — 바뀌는 것 3줄 · 취소 · 차단(빨강)
struct FriendBlockDialog: View {
  let name: String
  let onCancel: () -> Void
  let onBlock: () -> Void

  var body: some View {
    ZStack {
      Color.black.opacity(0.5).ignoresSafeArea().onTapGesture(perform: self.onCancel)
      VStack(alignment: .leading, spacing: 14) {
        Text(FriendProfileText.blockTitle(self.name)).wepliFont(.headline).foregroundStyle(WePLiColor.textPrimary)
        VStack(alignment: .leading, spacing: 8) {
          ForEach(FriendProfileText.blockLines, id: \.self) { line in
            Text(line).wepliFont(.subheadline, weight: .light).foregroundStyle(WePLiColor.textSecondary)
          }
        }
        HStack(spacing: 10) {
          self.button("취소", fill: WePLiColor.secondaryButtonFill, action: self.onCancel)
          self.button("차단", fill: WePLiColor.destructive, action: self.onBlock)
        }
        .padding(.top, 4)
      }
      .padding(EdgeInsets(top: 24, leading: 20, bottom: 18, trailing: 20))
      .frame(width: 310)
      .wepliGlass(in: RoundedRectangle(cornerRadius: 28))
      .accessibilityAddTraits(.isModal)
    }
  }

  private func button(_ title: String, fill: Color, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title)
        .wepliFont(.callout, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(fill, in: Capsule())
    }
    .buttonStyle(.plain)
  }
}

/// 차단한 사용자 — 머리 · 탭 대신 보인다. 뒤로 · ··· 는 그대로
struct FriendBlockedView: View {
  let name: String
  let onUnblock: () -> Void

  var body: some View {
    VStack(spacing: 8) {
      Text("차단한 사용자예요").wepliFont(.headline).foregroundStyle(WePLiColor.textPrimary)
      Text(FriendProfileText.blockedDetail(self.name))
        .wepliFont(.subheadline, weight: .light)
        .foregroundStyle(WePLiColor.textTertiary)
        .multilineTextAlignment(.center)
      Button(action: self.onUnblock) {
        Text("차단 해제")
          .wepliFont(.subheadline, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
          .padding(.horizontal, 18)
          .frame(height: 40)
          .background(WePLiColor.secondaryButtonFill, in: Capsule())
      }
      .buttonStyle(.plain)
      .padding(.top, 14)
    }
    .padding(.horizontal, 40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

/// 신고 — 사유 5개 중 하나(고른 줄만 라벤더 + 체크) · 안내 · 신고하기
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
      }
      .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
      Text(FriendProfileText.reportNotice)
        .wepliFont(.caption, weight: .light)
        .foregroundStyle(WePLiColor.textQuaternary)
        .padding(.horizontal, 8)
      Spacer(minLength: 0)
      WePLiPrimaryButton(title: "신고하기", isEnabled: self.store.reportReason != nil) {
        self.store.send(.menu(.reportSubmitted))
      }
    }
    .padding(EdgeInsets(top: 20, leading: 12, bottom: 24, trailing: 12))
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
      .frame(height: 52)
      .contentShape(Rectangle())
      .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5) }
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
  }
}
