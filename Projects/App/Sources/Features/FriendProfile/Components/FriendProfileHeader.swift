import ComposableArchitecture
import SwiftUI

// UI-13g 머리 — 지금 듣는 곡 커버를 흐리게 깔고 검정으로 녹인다. 듣는 중이면 프로필 사진에 홀로그램 링.
// 이름 · 팔로우 칩 → 아이디 · 팔로워 · 팔로잉 → 지금 듣는 중 한 줄 → 소개 → 성향 배지 · 취향 일치 → 초대 · 명함 · 공유

struct FriendProfileHeader: View {
  let store: StoreOf<FriendProfileFeature>
  let profile: FriendProfile

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .center, spacing: 16) {
        FriendAvatar(isListening: self.profile.nowPlaying != nil, size: 84)
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 10) {
            Text(self.profile.name)
              .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 24, relativeTo: .title))
              .foregroundStyle(WePLiColor.textPrimary)
              .lineLimit(1)
            FriendFollowChip(isFollowing: self.profile.isFollowing) { self.store.send(.followTapped) }
          }
          self.countLine
          if let song = self.profile.nowPlaying {
            FriendNowPlayingLine(song: song) { self.store.send(.nowPlayingTapped) }
              .padding(.top, 2)
          }
        }
      }
      .zIndex(1)
      .overlay(alignment: .topLeading) {
        if self.store.isNowPlayingMenuOpen, let song = self.profile.nowPlaying {
          FriendNowPlayingMenu(store: self.store, song: song).offset(y: 94)
        }
      }
      Text(self.profile.bio)
        .wepliFont(.body, weight: .light)
        .foregroundStyle(WePLiColor.textMuted)
        .padding(.top, 16)
      self.badgeRow.padding(.top, 12)
      FriendProfileActions(store: self.store, profile: self.profile).padding(.top, 20)
    }
    .padding(EdgeInsets(top: 72, leading: 20, bottom: 30, trailing: 20))
    .background(alignment: .top) { FriendProfileBackdrop() }
  }

  /// 「@jisu.wav · 팔로워 128 · 팔로잉 96」 — 숫자만 굵다
  private var countLine: some View {
    let dot = Text(" · ").foregroundColor(WePLiColor.textDisabled)
    let number = { (value: Int) in
      Text("\(value)").font(WePLiFont.font(.footnote, weight: .semibold)).foregroundColor(WePLiColor.textPrimary)
    }
    let handle = Text(FriendProfileText.handle(self.profile.handle))
    return (handle + dot + Text("팔로워 ") + number(self.profile.followerCount) + dot + Text("팔로잉 ")
      + number(self.profile.followingCount))
      .wepliFont(.footnote, weight: .light)
      .foregroundStyle(WePLiColor.textSecondary)
      .lineLimit(1)
  }

  private var badgeRow: some View {
    HStack(spacing: 10) {
      if let persona = self.profile.persona {
        Text(persona)
          .wepliFont(.caption, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
          .padding(.horizontal, 11)
          .frame(height: 26)
          .background(WePLiColor.cardFace, in: Capsule())
          .overlay(Capsule().strokeBorder(WePLiColor.accentStrong.opacity(0.32), lineWidth: 1))
      }
      // 서로 팔로우한 사이에서만 보인다(DEC-023) — 누르면 취향 궁합(UI-6d)
      if let match = self.profile.visibleTasteMatch {
        Button {
          self.store.send(.tasteMatchTapped)
        } label: {
          (Text("나와 취향 ") + Text("\(match)%").font(WePLiFont.font(.footnote, weight: .semibold))
            .foregroundColor(WePLiColor.accent) + Text(" 일치"))
            .wepliFont(.footnote, weight: .light)
            .foregroundStyle(WePLiColor.textSecondary)
        }
        .buttonStyle(.plain)
        .accessibilityHint("취향 궁합 보기")
      }
    }
  }
}

/// 흐린 커버 자리 — 커버 이미지가 붙기 전까지 자리 표시 색을 검정으로 녹인다
private struct FriendProfileBackdrop: View {
  var body: some View {
    WePLiColor.imagePlaceholder
      .frame(height: 480)
      .overlay {
        LinearGradient(
          stops: [
            .init(color: .black.opacity(0.2), location: 0),
            .init(color: .black.opacity(0.66), location: 0.5),
            .init(color: .black.opacity(0.95), location: 0.84),
            .init(color: .black, location: 1),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
      }
      .opacity(0.5)
      .ignoresSafeArea(edges: .top)
      .accessibilityHidden(true)
  }
}

/// 프로필 사진 — 듣는 중이면 홀로그램 링(3pt)
struct FriendAvatar: View {
  let isListening: Bool
  let size: CGFloat

  var body: some View {
    ZStack {
      if self.isListening {
        Circle().fill(WePLiGradient.vsRing)
      }
      Circle()
        .fill(WePLiColor.imagePlaceholder)
        .overlay(Circle().strokeBorder(WePLiColor.background, lineWidth: 3))
        .padding(3)
    }
    .frame(width: self.size, height: self.size)
    .accessibilityHidden(true)
  }
}

/// 팔로잉(반투명 + 체크) ↔ 팔로우(그라디언트)
private struct FriendFollowChip: View {
  let isFollowing: Bool
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      HStack(spacing: 4) {
        if self.isFollowing {
          Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
        }
        Text(self.isFollowing ? "팔로잉" : "팔로우").wepliFont(.footnote, weight: .semibold)
      }
      .foregroundStyle(self.isFollowing ? WePLiColor.textMuted : WePLiColor.textOnCTA)
      .padding(.leading, self.isFollowing ? 10 : 12)
      .padding(.trailing, 12)
      .frame(height: 30)
      .background {
        if self.isFollowing {
          Capsule().fill(WePLiColor.secondaryButtonFill)
        } else {
          Capsule().fill(WePLiGradient.cta)
        }
      }
    }
    .buttonStyle(.plain)
    .animation(.easeOut(duration: 0.2), value: self.isFollowing)
  }
}
