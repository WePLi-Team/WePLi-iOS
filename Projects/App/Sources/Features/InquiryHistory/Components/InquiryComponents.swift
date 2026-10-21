import SwiftUI

// UI-17a 부품 — 내비게이션 바 · 문의 한 줄(7b와 같이 씀) · 상세 머리 · 진행 기록 · 답변 대기 안내

/// 뒤로 44 · 가운데 제목 17/600 · 높이 48
struct InquiryNavBar: View {
  let title: String
  let onBack: () -> Void

  var body: some View {
    ZStack {
      Text(self.title)
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      HStack {
        WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로", action: self.onBack)
        Spacer()
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
  }
}

/// 종류 · 제목 · 「유형 · 날짜」, 오른쪽 상태 글자와 읽지 않은 점
struct InquiryListRow: View {
  let inquiry: Inquiry
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          InquiryKindLabel(inquiry: self.inquiry)
          Text(self.inquiry.title)
            .wepliFont(.body, weight: .medium)
            .foregroundStyle(WePLiColor.textPrimary)
            .lineLimit(1)
          Text(self.inquiry.meta).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textQuaternary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        HStack(spacing: 8) {
          Text(self.inquiry.status.title)
            .wepliFont(.footnote, weight: .semibold)
            .foregroundStyle(self.inquiry.status == .waiting ? WePLiColor.textQuaternary : WePLiColor.accent)
          if self.inquiry.showsUnreadDot {
            Circle().fill(WePLiColor.accentStrong).frame(width: 7, height: 7)
              .accessibilityLabel("읽지 않음")
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
      .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5) }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isButton)
  }
}

/// 「1:1 문의」 #8E8E99 · 「이의 신청 결과」 #9DABFF
struct InquiryKindLabel: View {
  let inquiry: Inquiry

  var body: some View {
    Text(self.inquiry.kindTitle)
      .wepliFont(.caption, weight: .semibold)
      .foregroundStyle(self.inquiry.isAppealResult ? WePLiColor.accentStrong : WePLiColor.textQuaternary)
  }
}

/// 상세 머리 — 종류 · 제목 22/600 · 「유형 · 날짜」
struct InquiryDetailHeader: View {
  let inquiry: Inquiry

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      InquiryKindLabel(inquiry: self.inquiry)
      Text(self.inquiry.title)
        .wepliFont(.title2, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
        .lineSpacing(8)
        .accessibilityAddTraits(.isHeader)
      Text(self.inquiry.meta).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textQuaternary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// 진행 기록 — 점 10 · 연결선 1.5(라벤더 30%), 지난 단계는 모두 라벤더
struct InquiryTimeline: View {
  let steps: [InquiryStep]

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(self.steps) { step in
        HStack(alignment: .top, spacing: 12) {
          VStack(spacing: 0) {
            Circle().fill(WePLiColor.accent).frame(width: 10, height: 10).padding(.top, 5)
            if step.id != self.steps.last?.id {
              Rectangle().fill(WePLiColor.accent.opacity(0.3)).frame(width: 1.5).frame(minHeight: 22)
            }
          }
          .frame(width: 14)
          VStack(alignment: .leading, spacing: 2) {
            Text(step.title).wepliFont(.body, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
            Text(step.dateText).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textQuaternary)
          }
          .padding(.bottom, 14)
        }
        .accessibilityElement(children: .combine)
      }
    }
  }
}

/// 답변 대기 — 홀로그램 점 · 「운영팀이 확인하고 있어요」
struct InquiryWaitingNote: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 8) {
        Circle().fill(WePLiGradient.vsRing).frame(width: 7, height: 7).accessibilityHidden(true)
        Text("운영팀이 확인하고 있어요").wepliFont(.body, weight: .semibold).foregroundStyle(WePLiColor.accent)
      }
      Text("보통 24시간 안에 답변해요. 답변이 오면 알림으로 알려드려요.")
        .wepliFont(.footnote, weight: .light)
        .foregroundStyle(WePLiColor.textTertiary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.top, 20)
    .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.1)).frame(height: 0.5) }
    .accessibilityElement(children: .combine)
  }
}

/// 작은 보조 버튼 — 높이 40 · 14/600 · 좌우 18
struct InquirySmallButton: View {
  let title: String
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      Text(self.title)
        .wepliFont(.subheadline, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
        .padding(.horizontal, 18)
        .frame(height: 40)
        .background(WePLiColor.secondaryButtonFill, in: Capsule())
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
  }
}
