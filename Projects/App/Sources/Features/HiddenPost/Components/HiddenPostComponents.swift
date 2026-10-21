import SwiftUI

// UI-17c · UI-7e — 가려진 내 글 카드 · 진행 상황 · 커뮤니티 맨 위 안내 카드

/// 글쓴이에게만 보이는 원래 글 — 위아래 가는 선만 두고 카드 바탕은 없다
struct HiddenPostCard: View {
  let post: HiddenPost

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 10) {
        AvatarPlaceholder(name: self.post.author).frame(width: 32, height: 32)
        VStack(alignment: .leading, spacing: 2) {
          Text(self.post.author).wepliFont(.subheadline, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
          Text("\(HiddenPostText.day(self.post.postedAt)) · 나에게만 보여요")
            .wepliFont(.caption, weight: .light)
            .foregroundStyle(WePLiColor.textQuaternary)
        }
      }
      Text(self.post.title).wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
      Text(self.post.body)
        .wepliFont(.subheadline, weight: .light)
        .foregroundStyle(WePLiColor.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
      if let song = self.post.song {
        HStack(spacing: 12) {
          RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 48, height: 48)
          VStack(alignment: .leading, spacing: 2) {
            Text(song.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
            Text(song.artist).wepliFont(.footnote, weight: .light).foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
          }
        }
        .accessibilityElement(children: .combine)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 20)
    .padding(.vertical, 18)
    .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5) }
    .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5) }
  }
}

/// 진행 상황 — 10pt 점 · 1.5pt 선. 지난 단계 라벤더, 지금 단계 보조 강조색, 다음 단계 흐리게
struct HiddenPostTimeline: View {
  let steps: [AppealStep]

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(self.steps) { step in
        HStack(alignment: .top, spacing: 12) {
          VStack(spacing: 0) {
            Circle().fill(self.dot(step.phase)).frame(width: 10, height: 10).padding(.top, 5)
            if step.id != self.steps.last?.id {
              Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1.5).frame(minHeight: 22)
            }
          }
          .frame(width: 14)
          VStack(alignment: .leading, spacing: 2) {
            Text(step.title)
              .wepliFont(.body, weight: .semibold)
              .foregroundStyle(step.phase == .upcoming ? WePLiColor.textDisabled : WePLiColor.textPrimary)
            Text(step.detail).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textQuaternary)
          }
          .padding(.bottom, 14)
        }
        .accessibilityElement(children: .combine)
      }
    }
  }

  private func dot(_ phase: AppealStep.Phase) -> Color {
    switch phase {
    case .done: WePLiColor.accent
    case .current: WePLiColor.accentStrong
    // 원본 #3A3A44 — 가장 가까운 토큰
    case .upcoming: WePLiColor.surface4
    }
  }
}

/// 커뮤니티 맨 위 7e 안내 카드 — 누르면 내 가려진 글(17c). 원본의 분홍 경고 아이콘은 DEC-009에 따라 라벤더로
struct HiddenPostNotice: View {
  let post: HiddenPost
  let onOpen: () -> Void
  let onAppeal: () -> Void
  let onPolicy: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Button(action: self.onOpen) {
        VStack(alignment: .leading, spacing: 8) {
          HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
              .font(.system(size: 16, weight: .medium))
              .foregroundStyle(WePLiColor.accent)
              .accessibilityHidden(true)
            Text("내 게시글 1개가 가려졌어요").wepliFont(.body, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
          }
          Text("‘\(self.post.title)’가 신고 검토 중이에요. 결과는 24시간 안에 알려드려요.")
            .wepliFont(.footnote)
            .foregroundStyle(WePLiColor.textMuted)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      HStack(spacing: 14) {
        Button("이의 신청하기", action: self.onAppeal)
          .wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(WePLiColor.accent)
        Button("운영정책 보기", action: self.onPolicy)
          .wepliFont(.footnote)
          .foregroundStyle(WePLiColor.textTertiary)
      }
      .frame(minHeight: 32)
    }
    .padding(.horizontal, 16)
    .padding(.top, 14)
    .padding(.bottom, 8)
    .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 18))
    .padding(.horizontal, 16)
    .padding(.bottom, 10)
  }
}
