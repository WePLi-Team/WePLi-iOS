import SwiftUI

// UI-17e 세 상태 — 날짜는 서버 값을 Asia/Seoul 날짜로(DEC-004)

struct AccountPendingContent: View {
  let pending: PendingDeletion
  let isRestoring: Bool
  let onRestore: () -> Void
  let onLeave: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 14) {
        AccountLogo(height: 19.6).padding(.bottom, 6)
        Text("탈퇴를 신청한\n계정이에요").wepliFont(.title1).foregroundStyle(WePLiColor.textPrimary)
          .accessibilityAddTraits(.isHeader)
        Text(self.dates).wepliFont(.body, weight: .light).foregroundStyle(WePLiColor.textSecondary).lineSpacing(4)
      }
      .padding(.top, 88)
      VStack(alignment: .leading, spacing: 12) {
        Text("지금 되살리면 그대로 돌아와요").wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(WePLiColor.textQuaternary)
        ForEach(self.pending.keeps, id: \.self) { keep in
          HStack(spacing: 10) {
            WePLiSelectionCheck(isOn: true, size: 18)
            Text(keep).wepliFont(.body).foregroundStyle(WePLiColor.textMuted)
          }
        }
      }
      .padding(.top, 44)
      Spacer()
      VStack(spacing: 4) {
        WePLiPrimaryButton(title: "계정 되살리기", isEnabled: !self.isRestoring, action: self.onRestore)
        Button("탈퇴 그대로 두고 나가기", action: self.onLeave)
          .wepliFont(.body)
          .foregroundStyle(WePLiColor.textQuaternary)
          .frame(height: 44)
          .buttonStyle(.plain)
      }
      .padding(.bottom, 8)
    }
    .padding(.horizontal, 32)
  }

  /// 「10월 21일에 탈퇴를 신청했어요. / **11월 4일**에 모든 정보가 삭제돼요.」
  private var dates: AttributedString {
    var deletes = AttributedString(AccountText.day(self.pending.deletesAt))
    deletes.font = .custom(WePLiFont.Weight.semibold.postScriptName, size: 15, relativeTo: .body)
    deletes.foregroundColor = WePLiColor.textPrimary
    return AttributedString("\(AccountText.day(self.pending.requestedAt))에 탈퇴를 신청했어요.\n") + deletes
      + AttributedString("에 모든 정보가 삭제돼요.")
  }
}

struct AccountRestoredContent: View {
  let onHome: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      Spacer()
      AccountLogo(height: 28.7).padding(.bottom, 8)
      Text("다시 만나서 반가워요").wepliFont(.title2, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      Text("탈퇴 신청을 취소했어요.\n추천한 곡과 명함이 모두 그대로예요.")
        .wepliFont(.body, weight: .light)
        .foregroundStyle(WePLiColor.textSecondary)
        .lineSpacing(4)
      ExportSecondaryButton(title: "홈으로", action: self.onHome).padding(.top, 30)
      Spacer()
    }
    .multilineTextAlignment(.center)
    .padding(.horizontal, 32)
  }
}

struct AccountBlockedContent: View {
  let block: RejoinBlock
  let onPolicy: () -> Void
  let onHelp: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 14) {
        AccountLogo(height: 19.6).padding(.bottom, 6)
        Text("아직 다시 가입할 수\n없어요").wepliFont(.title1).foregroundStyle(WePLiColor.textPrimary)
          .accessibilityAddTraits(.isHeader)
        Text(self.message).wepliFont(.body, weight: .light).foregroundStyle(WePLiColor.textSecondary).lineSpacing(4)
      }
      .padding(.top, 88)
      VStack(spacing: 0) {
        self.row("제한 사유", self.block.reason, accent: false)
        AccountSeparator()
        self.row("다시 가입 가능", "\(AccountText.day(self.block.rejoinAt))부터", accent: true)
      }
      .padding(.top, 36)
      Spacer()
      VStack(spacing: 4) {
        ExportSecondaryButton(title: "운영정책 보기", action: self.onPolicy)
        Button("고객센터에 문의하기", action: self.onHelp)
          .wepliFont(.body)
          .foregroundStyle(WePLiColor.accent)
          .frame(height: 44)
          .buttonStyle(.plain)
      }
      .padding(.bottom, 8)
    }
    .padding(.horizontal, 32)
  }

  /// 「… 제한이 끝나는 **11월 2일**부터 같은 Apple 계정으로 다시 가입할 수 있어요.」 — 수단 이름은 가입한 수단
  private var message: AttributedString {
    var day = AttributedString(AccountText.day(self.block.rejoinAt))
    day.font = .custom(WePLiFont.Weight.semibold.postScriptName, size: 15, relativeTo: .body)
    day.foregroundColor = WePLiColor.textPrimary
    return AttributedString("이용 제한 기간에 탈퇴한 계정이에요. 제한이 끝나는 ") + day
      + AttributedString("부터 같은 \(self.block.provider.name) 계정으로 다시 가입할 수 있어요.")
  }

  private func row(_ label: String, _ value: String, accent: Bool) -> some View {
    HStack {
      Text(label).wepliFont(.body).foregroundStyle(WePLiColor.textTertiary)
      Spacer()
      Text(value)
        .wepliFont(.body, weight: accent ? .semibold : nil)
        .foregroundStyle(accent ? WePLiColor.accent : WePLiColor.textPrimary)
    }
    .frame(height: 52)
    .accessibilityElement(children: .combine)
  }
}
