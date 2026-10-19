import ComposableArchitecture
import SwiftUI

// REQ-110 · UI-7a — 공지 · 이벤트. 밑줄 탭, 「중요」 고정 · 안 읽음 점(공지), 배너 카드(이벤트), 상세 · 목록으로

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
        if self.store.tab == .event {
          LazyVStack(spacing: 24) {
            ForEach(self.store.list) { notice in
              EventCard(notice: notice) { self.store.send(.noticeTapped(notice.id)) }
            }
          }
          .padding(.horizontal, 20)
          .padding(.top, 18)
          .padding(.bottom, 40)
        } else {
          LazyVStack(spacing: 0) {
            ForEach(self.store.list) { notice in
              NoticeRow(notice: notice) { self.store.send(.noticeTapped(notice.id)) }
            }
          }
        }
      }
    }
  }

  private func detail(_ notice: Notice) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      NoticeMeta(notice: notice, isDetail: true)
      Text(notice.title).wepliFont(.title2).foregroundStyle(WePLiColor.textPrimary)
      if notice.hasImage {
        RoundedRectangle(cornerRadius: 12).fill(WePLiColor.surface1).frame(height: 168)
          .overlay { RoundedRectangle(cornerRadius: 8).fill(WePLiColor.imagePlaceholder).padding(.vertical, 24).padding(
            .horizontal,
            60
          ) }
          .accessibilityHidden(true)
      }
      Text(notice.body).wepliFont(.body).lineSpacing(6).foregroundStyle(WePLiColor.textMuted)
      VStack(spacing: 10) {
        if let banner = notice.eventAction, let title = banner.action {
          self.eventButton(title, url: banner.actionURL)
        }
        ExportSecondaryButton(title: "목록으로") { self.store.send(.backToListTapped) }
      }
      .padding(.top, 10)
    }
    .padding(.horizontal, 20)
    .padding(.top, 18)
    .padding(.bottom, 40)
  }

  /// 진행 중 이벤트 버튼 — 미결정: 여는 곳(원본에는 동작이 없다)
  @ViewBuilder
  private func eventButton(_ title: String, url: URL?) -> some View {
    if let url {
      Link(destination: url) {
        Text(title)
          .wepliFont(.callout, weight: .semibold)
          .foregroundStyle(WePLiColor.textOnCTA)
          .frame(maxWidth: .infinity)
          .frame(height: 52)
          .background(WePLiGradient.cta, in: Capsule())
      }
    }
  }
}

#Preview {
  NavigationStack {
    NoticesView(store: Store(initialState: NoticesFeature.State()) { NoticesFeature() })
  }
}
