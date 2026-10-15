import ComposableArchitecture
import SwiftUI

// REQ-110 · UI-7a — 공지 · 이벤트. 밑줄 탭(DEC-009 — 원본의 세그먼트 대신), 「중요」 고정, 안 읽음 점, 상세 · 목록으로

struct NoticesView: View {
  let store: StoreOf<NoticesFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        self.navigationBar
        if let notice = self.store.selected {
          ScrollView { self.detail(notice) }
        } else if self.store.notices != nil {
          self.listView
        } else if self.store.loadFailed {
          self.failed
        } else {
          Spacer()
          ProgressView().tint(WePLiColor.textTertiary)
          Spacer()
        }
      }
      .background(WePLiColor.background.ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private var navigationBar: some View {
    ZStack {
      Text(self.store.selected.map(\.kind.title) ?? "공지사항")
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      HStack {
        WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") { self.store.send(.backButtonTapped) }
        Spacer()
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
  }

  private var failed: some View {
    VStack(spacing: 12) {
      Spacer()
      // 원본에 없는 문구 — 디자인 확인 필요
      Text("공지사항을 불러오지 못했어요").wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
      Button("다시 시도") { self.store.send(.retryButtonTapped) }
        .wepliFont(.subheadline, weight: .semibold)
        .foregroundStyle(WePLiColor.accent)
      Spacer()
    }
  }

  private var listView: some View {
    VStack(spacing: 0) {
      WePLiUnderlineTabs(items: Notice.Kind.allCases, selected: self.store.tab, title: \.title) {
        self.store.send(.tabSelected($0))
      }
      .padding(.horizontal, 20)
      .padding(.top, 12)
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(self.store.list) { notice in
            self.row(notice)
          }
        }
      }
    }
  }

  private func row(_ notice: Notice) -> some View {
    Button {
      self.store.send(.noticeTapped(notice.id))
    } label: {
      HStack(spacing: 12) {
        if notice.hasImage {
          RoundedRectangle(cornerRadius: 8).fill(WePLiColor.imagePlaceholder).frame(width: 64, height: 48)
        }
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            self.badges(notice)
            Text(notice.title).wepliFont(.body, weight: .medium).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
          }
          Text(notice.dateText).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
        }
        Spacer(minLength: 8)
        if notice.isUnread {
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

  private func badges(_ notice: Notice) -> some View {
    HStack(spacing: 6) {
      if notice.isPinned {
        NoticeBadge(title: "중요")
      }
      if let status = notice.eventStatus {
        NoticeBadge(title: status.title, isDimmed: status == .ended)
      }
    }
  }

  private func detail(_ notice: Notice) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 6) {
        self.badges(notice)
        Text(notice.dateText).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
      }
      Text(notice.title).wepliFont(.title2).foregroundStyle(WePLiColor.textPrimary)
      if notice.hasImage {
        RoundedRectangle(cornerRadius: 16).fill(WePLiColor.imagePlaceholder).frame(height: 180)
      }
      Text(notice.body).wepliFont(.body).lineSpacing(6).foregroundStyle(WePLiColor.textMuted)
      Button {
        self.store.send(.backToListTapped)
      } label: {
        Text("목록으로")
          .wepliFont(.body, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(WePLiColor.disabledFill, in: Capsule())
      }
      .buttonStyle(.plain)
      .padding(.top, 10)
    }
    .padding(.horizontal, 20)
    .padding(.top, 18)
    .padding(.bottom, 40)
  }
}

/// 「중요」 · 「진행 중」 · 「종료」 — 원본의 분홍 「중요」는 DEC-009(분홍은 좋아요 · 급상승만)에 따라 라벤더로 그린다
private struct NoticeBadge: View {
  let title: String
  var isDimmed = false

  var body: some View {
    Text(self.title)
      .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 11, relativeTo: .caption2))
      .foregroundStyle(self.isDimmed ? WePLiColor.textQuaternary : WePLiColor.accent)
      .padding(.horizontal, 6)
      .frame(height: 20)
      .background(self.isDimmed ? WePLiColor.chipOff : WePLiColor.chipOn, in: RoundedRectangle(cornerRadius: 4))
  }
}

#Preview {
  NavigationStack {
    NoticesView(store: Store(initialState: NoticesFeature.State()) { NoticesFeature() })
  }
}
