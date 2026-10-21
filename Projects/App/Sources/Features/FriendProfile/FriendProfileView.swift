import ComposableArchitecture
import SwiftUI

// REQ-079 · UI-13g · DEC-010 · DEC-020 — 친구 프로필 B안. 머리 → 밑줄 탭(게시글 · 플레이리스트 · 릴레이 · 들은 음악).
// 오른쪽 위 ··· 에서 공유 · 링크 복사 · 차단 · 신고. 차단하면 머리 · 탭 대신 「차단한 사용자예요」

struct FriendProfileView: View {
  let store: StoreOf<FriendProfileFeature>

  var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        WePLiColor.background.ignoresSafeArea()
        self.content()
        self.navigationBar
        if self.store.overlay == .blockConfirm, let profile = self.store.profile {
          FriendBlockDialog(
            name: profile.name,
            onCancel: { self.store.send(.menu(.blockCancelled)) },
            onBlock: { self.store.send(.menu(.blockConfirmed)) }
          )
          .transition(.opacity)
        }
      }
      .animation(.easeOut(duration: 0.2), value: self.store.overlay)
      .animation(.easeOut(duration: 0.2), value: self.store.isBlocked)
      .toolbar(.hidden, for: .navigationBar)
      .modifier(FriendProfileSheets(store: self.store))
      .wepliToast(Binding(get: { self.store.toast }, set: {
        if $0 == nil {
          self.store.send(.toastDismissed)
        }
      }))
      .onAppear { self.store.send(.onAppear) }
    }
  }

  @ViewBuilder
  private func content() -> some View {
    if let profile = self.store.profile {
      if self.store.isBlocked {
        FriendBlockedView(name: profile.name) { self.store.send(.menu(.unblockTapped)) }
      } else {
        self.profileScroll(profile)
      }
    } else if self.store.loadFailed {
      VStack(spacing: 12) {
        // 원본에 없는 문구 — 디자인 확인 필요
        Text("프로필을 불러오지 못했어요").wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
        Button("다시 시도") { self.store.send(.retryButtonTapped) }
          .wepliFont(.subheadline, weight: .semibold)
          .foregroundStyle(WePLiColor.accent)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      ProgressView().tint(WePLiColor.textTertiary).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  private func profileScroll(_ profile: FriendProfile) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        FriendProfileHeader(store: self.store, profile: profile).zIndex(1)
        WePLiUnderlineTabs(
          items: FriendProfileTab.allCases,
          selected: self.store.tab,
          title: \.title
        ) { self.store.send(.tabSelected($0)) }
          .padding(.horizontal, 20)
        FriendProfileTabContent(store: self.store, profile: profile)
      }
      .padding(.bottom, 60)
      // 지금 듣는 중 메뉴가 열려 있으면 어디를 눌러도 닫는다(메뉴 안 버튼도 동작한 뒤 닫힘)
      .simultaneousGesture(
        TapGesture().onEnded { self.store.send(.nowPlayingMenuDismissed) },
        including: self.store.isNowPlayingMenuOpen ? .all : .subviews
      )
    }
  }

  /// 뒤로 · ··· — 글래스 원형 44, 차단 화면에서도 그대로 보인다
  private var navigationBar: some View {
    HStack {
      WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") { self.store.send(.backButtonTapped) }
      Spacer()
      if self.store.profile != nil {
        WePLiIconButton(systemName: "ellipsis", accessibilityLabel: "더보기") { self.store.send(.menu(.moreTapped)) }
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
  }
}

/// ··· 메뉴 · 신고 · 접수 안내 · 이미 신고함 시트 — 하나만 뜬다. 차단 확인은 시트가 아니라 가운데 창
private struct FriendProfileSheets: ViewModifier {
  let store: StoreOf<FriendProfileFeature>

  func body(content: Content) -> some View {
    content.sheet(item: Binding(
      get: { self.store.overlay == .blockConfirm ? nil : self.store.overlay },
      set: {
        if $0 == nil {
          self.store.send(.menu(.dismissed))
        }
      }
    )) { overlay in
      if let profile = self.store.profile {
        switch overlay {
        case .menu: FriendProfileMenuSheet(store: self.store, profile: profile)
        case .report: FriendReportSheet(store: self.store, name: profile.name)
        case .reportDone: FriendReportDoneSheet(store: self.store, name: profile.name)
        case .reportExisting:
          if let report = profile.myReport {
            FriendReportExistingSheet(store: self.store, name: profile.name, report: report)
          }
        case .blockConfirm: EmptyView()
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    FriendProfileView(store: Store(initialState: FriendProfileFeature.State(userID: "jisoo")) {
      FriendProfileFeature()
    })
  }
}
