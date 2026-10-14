import SwiftUI

// UI-4d 알림 행 · 권한 카드

struct NotificationRow: View {
  let notification: AppNotification
  let onTap: () -> Void

  var body: some View {
    Button(action: self.onTap) {
      HStack(alignment: .top, spacing: 12) {
        self.thumbnail
        VStack(alignment: .leading, spacing: 4) {
          Text(self.notification.text)
            .wepliFont(.subheadline)
            // 「이번 주」 본문은 한 단계 어둡게(원본 #D8D8DD)
            .foregroundStyle(self.notification.group == .today ? WePLiColor.textPrimary : WePLiColor.textMuted)
            .fixedSize(horizontal: false, vertical: true)
          Text(self.notification.timeText)
            .wepliFont(.caption)
            .foregroundStyle(WePLiColor.textQuaternary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        if let action = self.notification.actionTitle {
          Text(action)
            .wepliFont(.footnote, weight: .semibold)
            .foregroundStyle(WePLiColor.accent)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(WePLiColor.accentStrong.opacity(0.16), in: Capsule())
            .frame(maxHeight: .infinity)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
      .background {
        if !self.notification.isRead {
          WePLiColor.accentStrong.opacity(0.06)
        }
      }
      .overlay(alignment: .topLeading) {
        if !self.notification.isRead {
          Circle()
            .fill(WePLiColor.accentStrong)
            .frame(width: 6, height: 6)
            .padding(.leading, 8)
            .padding(.top, 30)
            .accessibilityHidden(true)
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(self.accessibilityText)
  }

  private var thumbnail: some View {
    Group {
      if self.notification.kind.showsAvatar {
        Circle().fill(WePLiColor.surface4)
          .overlay {
            Image(systemName: "person.fill")
              .font(.system(size: 18))
              .foregroundStyle(WePLiColor.textQuaternary)
          }
      } else {
        RoundedRectangle(cornerRadius: 8).fill(WePLiColor.surface4)
          .overlay {
            Image(systemName: "music.note")
              .font(.system(size: 16))
              .foregroundStyle(WePLiColor.textQuaternary)
          }
      }
    }
    .frame(width: 44, height: 44)
    .accessibilityHidden(true)
  }

  private var accessibilityText: String {
    let state = self.notification.isRead ? "" : "읽지 않음, "
    return "\(state)\(self.notification.text), \(self.notification.timeText)"
  }
}

struct NotificationPermissionCard: View {
  let onEnable: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text("알림을 켜두세요")
          .wepliFont(.body, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
        Text("투표 마감과 순위 변동을 바로 알려드려요")
          .wepliFont(.footnote)
          .foregroundStyle(WePLiColor.textSecondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Button(action: self.onEnable) {
        Text("켜기")
          .wepliFont(.subheadline, weight: .semibold)
          .foregroundStyle(WePLiColor.textOnCTA)
          .padding(.horizontal, 16)
          .frame(height: 34)
          .background(WePLiColor.accent, in: Capsule())
      }
      .buttonStyle(.plain)
    }
    .padding(.leading, 16)
    .padding(.trailing, 14)
    .padding(.vertical, 14)
    .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 18))
  }
}
