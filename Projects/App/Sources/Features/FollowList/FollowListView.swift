import ComposableArchitecture
import SwiftUI

// REQ-074 · UI-10c — 팔로워 · 팔로잉

struct FollowListView: View {
  let store: StoreOf<FollowListFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        self.navigationBar
        self.segment
          .padding(.horizontal, 20)
          .padding(.top, 8)
        HStack(spacing: 8) {
          Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundStyle(WePLiColor.textQuaternary)
          TextField("이름으로 찾기", text: Binding(get: { self.store.query }, set: { self.store.send(.queryChanged($0)) }))
            .wepliFont(.body)
            .foregroundStyle(WePLiColor.textPrimary)
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(WePLiColor.surface2, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
        ScrollView {
          LazyVStack(spacing: 0) {
            ForEach(self.store.visibleUsers) { user in
              FollowUserRow(
                user: user,
                tab: self.store.tab,
                onTap: { self.store.send(.userTapped(user.id)) },
                onFollow: { self.store.send(.followButtonTapped(user.id)) }
              )
            }
          }
        }
        .scrollDismissesKeyboard(.interactively)
      }
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private var navigationBar: some View {
    ZStack {
      Text(self.store.userName).wepliFont(.button).foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      HStack {
        WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") { self.store.send(.backButtonTapped) }
        Spacer()
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
  }

  private var segment: some View {
    HStack(spacing: 0) {
      self.segmentItem(.followers, title: "팔로워 \(CountFormatter.string(self.store.lists?.followerCount ?? 0))")
      self.segmentItem(.following, title: "팔로잉 \(CountFormatter.string(self.store.lists?.followingCount ?? 0))")
    }
    .padding(2)
    .frame(height: 36)
    .background(WePLiColor.surface2, in: RoundedRectangle(cornerRadius: 10))
  }

  private func segmentItem(_ tab: FollowListFeature.Tab, title: String) -> some View {
    let isOn = self.store.tab == tab
    return Button {
      self.store.send(.tabSelected(tab))
    } label: {
      Text(title)
        .wepliFont(.subheadline, weight: isOn ? .semibold : .regular)
        .foregroundStyle(isOn ? WePLiColor.textPrimary : WePLiColor.textTertiary)
        .monospacedDigit()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
          if isOn {
            RoundedRectangle(cornerRadius: 8).fill(WePLiColor.segmentSelected)
          }
        }
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
  }
}

struct FollowUserRow: View {
  let user: FollowUser
  let tab: FollowListFeature.Tab
  let onTap: () -> Void
  let onFollow: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Button(action: self.onTap) {
        HStack(spacing: 12) {
          AvatarPlaceholder(name: self.user.name).frame(width: 44, height: 44)
          VStack(alignment: .leading, spacing: 1) {
            Text(self.user.name).wepliFont(.body, weight: .medium).foregroundStyle(WePLiColor.textPrimary)
            Text(self.subtitle).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      Button(action: self.onFollow) {
        Text(self.user.isFollowing ? "팔로잉" : self.callToAction)
          .wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(self.user.isFollowing ? WePLiColor.textPrimary : WePLiColor.textOnCTA)
          .padding(.horizontal, 14)
          .frame(height: 32)
          .background(self.user.isFollowing ? WePLiColor.surface2 : WePLiColor.accent, in: Capsule())
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 20)
    .frame(height: 66)
  }

  /// 팔로워 탭에서 나를 팔로우하는 사람은 「· 나를 팔로우」를 붙인다
  private var subtitle: String {
    self.tab == .followers && self.user.followsMe ? "\(self.user.persona.name) · 나를 팔로우" : self.user.persona.name
  }

  /// 팔로워 탭은 「맞팔로우」, 팔로잉 탭은 「팔로우」
  private var callToAction: String {
    self.tab == .followers ? "맞팔로우" : "팔로우"
  }
}

#Preview {
  NavigationStack {
    FollowListView(store: Store(initialState: FollowListFeature.State(userName: "김동")) { FollowListFeature() })
  }
}
