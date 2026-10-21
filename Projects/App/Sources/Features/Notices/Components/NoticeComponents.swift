import SwiftUI

// UI-7a 부품 — 공지 줄 · 이벤트 배너 카드 · 메타 줄(「중요」 · 상태 · 날짜)
// 원본의 분홍 「중요」 알약은 갱신본에서 라벤더 글자로 바뀌었다(DEC-009와 같음)

struct NoticeRow: View {
  let notice: Notice
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            if self.notice.isPinned {
              NoticePinnedLabel()
            }
            Text(self.notice.title)
              .wepliFont(.body, weight: .medium)
              .foregroundStyle(WePLiColor.textPrimary)
              .lineLimit(1)
          }
          Text(self.notice.dateText).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textQuaternary)
        }
        Spacer(minLength: 8)
        if self.notice.isUnread {
          Circle().fill(WePLiColor.accentStrong).frame(width: 7, height: 7).accessibilityLabel("읽지 않음")
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
      .contentShape(Rectangle())
      .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5) }
    }
    .buttonStyle(.plain)
  }
}

/// 이벤트 배너 카드 — 배너 104(왼쪽 글 · 오른쪽 이미지) + 상태 · 기간. 종료는 흐리게
struct EventCard: View {
  let notice: Notice
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      VStack(alignment: .leading, spacing: 10) {
        self.banner
        NoticeMeta(notice: self.notice, isDetail: false)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .opacity(self.notice.eventStatus == .ended ? 0.55 : 1)
    .accessibilityElement(children: .combine)
  }

  private var banner: some View {
    HStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 2) {
        Text(self.notice.banner?.kicker ?? "").wepliFont(.caption).foregroundStyle(WePLiColor.textPrimary)
        Text(self.notice.banner?.head ?? self.notice.title)
          .wepliFont(.callout, weight: .semibold)
          .foregroundStyle(Color.white)
          .lineLimit(2)
      }
      .padding(.leading, 18)
      .frame(maxWidth: .infinity, alignment: .leading)
      // 이벤트 이미지 — 에셋이 붙기 전까지 자리 표시
      RoundedRectangle(cornerRadius: 8)
        .fill(WePLiColor.imagePlaceholder)
        .frame(width: 116)
        .padding(.vertical, 10)
        .padding(.trailing, 14)
        .accessibilityHidden(true)
    }
    .frame(height: 104)
    .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 12))
  }
}

/// 「중요」 · 진행 중 점 · 상태 · 「·」 · 날짜
struct NoticeMeta: View {
  let notice: Notice
  let isDetail: Bool

  var body: some View {
    HStack(spacing: 6) {
      if self.notice.isPinned {
        NoticePinnedLabel()
      }
      if let status = self.notice.eventStatus {
        if status == .ongoing, !self.isDetail {
          Circle().fill(WePLiGradient.vsRing).frame(width: 6, height: 6).accessibilityHidden(true)
        }
        Text(status.title)
          .wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(status == .ongoing ? WePLiColor.accent : WePLiColor.textQuaternary)
        Text("·").wepliFont(.footnote).foregroundStyle(WePLiColor.textDisabled)
      }
      Text(self.notice.dateText)
        .wepliFont(self.isDetail ? .caption : .footnote, weight: .light)
        .monospacedDigit()
        .foregroundStyle(self.isDetail ? WePLiColor.textQuaternary : WePLiColor.textTertiary)
    }
  }
}

private struct NoticePinnedLabel: View {
  var body: some View {
    Text("중요").wepliFont(.footnote, weight: .bold).foregroundStyle(WePLiColor.accent)
  }
}
