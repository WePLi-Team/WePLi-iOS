import ComposableArchitecture
import SwiftUI

// REQ-060 · UI-1d — 커뮤니티 피드 · REQ-079 · UI-13b 친구 탭

struct CommunityFeedView: View {
  @Perception.Bindable var store: StoreOf<CommunityFeedFeature>

  var body: some View {
    WithPerceptionTracking {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
          self.header
          if self.store.segment == .friends {
            FriendFeedView(store: self.store.scope(state: \.friends, action: \.friends))
          } else {
            self.content
          }
        }
      }
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .wepliToast(self.store.friends.toast) { self.store.send(.friends(.toastDismissed)) }
      .sheet(item: self.$store.scope(state: \.appeal, action: \.appeal)) { appealStore in
        AppealView(store: appealStore).wepliSheetStyle(detents: [.large])
      }
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 8) {
        Spacer()
        WePLiIconButton(systemName: "bell", accessibilityLabel: "알림") {
          self.store.send(.notificationButtonTapped)
        }
        // 글쓰기 FAB를 내비게이션 오른쪽 위 버튼으로 옮김(UI-1d 노트)
        Button {
          self.store.send(.composeButtonTapped)
        } label: {
          Image(systemName: "square.and.pencil")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(WePLiColor.textOnCTA)
            .frame(width: WePLiIconButton.size, height: WePLiIconButton.size)
            .background(WePLiColor.accent, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("글쓰기")
      }
      .frame(height: 48)
      .padding(.horizontal, 16)

      Text("커뮤니티")
        .wepliFont(.screenTitle)
        .foregroundStyle(WePLiColor.textPrimary)
        .padding(.horizontal, 20)
        .padding(.top, 2)
        .padding(.bottom, 14)
        .accessibilityAddTraits(.isHeader)
      // UI-13b — 제목 아래 밑줄 탭. 게시글은 지금 피드(1d) 그대로
      WePLiUnderlineTabs(items: CommunitySegment.allCases, selected: self.store.segment, title: \.title) {
        self.store.send(.segmentSelected($0))
      }
      .padding(.horizontal, 20)
    }
  }

  @ViewBuilder private var content: some View {
    if self.store.isLoading, self.store.posts.isEmpty {
      VStack(spacing: 12) {
        ForEach(0 ..< 4, id: \.self) { _ in
          WePLiSongRowSkeleton()
        }
      }
      .padding(.horizontal, 20)
      .wepliPulse()
    } else if self.store.loadFailed, self.store.posts.isEmpty {
      // 원본에 오류 화면이 없어 빈 상태 형식을 따른 임시 문구 — 디자인 확인 필요
      WePLiEmptyState(
        systemImage: "exclamationmark.triangle",
        title: "게시글을 불러오지 못했어요",
        message: "잠시 후 다시 시도해 주세요.",
        actionTitle: "다시 시도",
        action: { self.store.send(.retryButtonTapped) }
      )
      .padding(.vertical, 60)
    } else {
      if let hidden = self.store.hiddenMine {
        HiddenPostNotice(
          post: hidden,
          onOpen: { self.store.send(.hiddenNoticeTapped) },
          onAppeal: { self.store.send(.hiddenAppealTapped) },
          onPolicy: { self.store.send(.hiddenPolicyTapped) }
        )
        .padding(.top, 14)
      }
      CommunityStoryRow(stories: self.store.stories) { self.store.send(.storyTapped($0)) }
      if self.store.posts.isEmpty {
        WePLiEmptyState.feed { self.store.send(.composeButtonTapped) }
          .padding(.vertical, 60)
      } else {
        ForEach(self.store.posts) { post in
          CommunityPostCard(
            post: post,
            onLike: { self.store.send(.likeTapped(post.id)) },
            onSave: { self.store.send(.saveTapped(post.id)) },
            onAuthor: { self.store.send(.authorTapped(post.author)) }
          )
          .contentShape(Rectangle())
          .onTapGesture { self.store.send(.postTapped(post.id)) }
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    CommunityFeedView(store: Store(initialState: CommunityFeedFeature.State()) { CommunityFeedFeature() })
  }
}
