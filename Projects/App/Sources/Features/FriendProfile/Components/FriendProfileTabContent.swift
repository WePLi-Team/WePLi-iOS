import ComposableArchitecture
import SwiftUI

// UI-13g 탭 — 게시글(커뮤니티) · 플레이리스트 · 릴레이(추천한 곡과 결과) · 들은 음악

struct FriendProfileTabContent: View {
  let store: StoreOf<FriendProfileFeature>
  let profile: FriendProfile

  var body: some View {
    switch self.store.tab {
    case .posts: self.posts
    case .playlists: self.playlists
    case .relays: self.relays
    case .listened: FriendListenedTab(store: self.store, profile: self.profile)
    }
  }

  private var posts: some View {
    LazyVStack(spacing: 0) {
      ForEach(self.profile.posts) { post in
        FriendPostRow(post: post) {
          self.store.send(.postTapped(post.id))
        } onLike: {
          self.store.send(.postLikeTapped(post.id))
        }
      }
    }
  }

  private var playlists: some View {
    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 20) {
      ForEach(self.profile.playlists) { playlist in
        Button {
          self.store.send(.playlistTapped(playlist.id))
        } label: {
          VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 12).fill(WePLiColor.imagePlaceholder).aspectRatio(1, contentMode: .fit)
            Text(playlist.title)
              .wepliFont(.footnote)
              .foregroundStyle(WePLiColor.textPrimary)
              .lineLimit(2)
              .multilineTextAlignment(.leading)
            Text("\(playlist.songCount)곡 · 좋아요 \(playlist.likeCount)")
              .wepliFont(.caption, weight: .light)
              .foregroundStyle(WePLiColor.textTertiary)
          }
        }
        .buttonStyle(.plain)
      }
    }
    .padding(EdgeInsets(top: 20, leading: 20, bottom: 0, trailing: 20))
  }

  private var relays: some View {
    VStack(spacing: 0) {
      ForEach(self.profile.relays) { relay in
        Button {
          self.store.send(.relayTapped(relay.id))
        } label: {
          HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12).fill(WePLiColor.imagePlaceholder).frame(width: 68, height: 68)
            VStack(alignment: .leading, spacing: 3) {
              Text(relay.title).wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
              Text("추천한 곡 · \(relay.recommended)")
                .wepliFont(.caption, weight: .light)
                .foregroundStyle(WePLiColor.textTertiary)
              Text(relay.result)
                .wepliFont(.caption, weight: .semibold)
                .foregroundStyle(relay.isLive ? WePLiColor.accent : WePLiColor.textPrimary)
            }
            .lineLimit(1)
            Spacer(minLength: 0)
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 10)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.top, 10)
  }
}

/// 게시글 한 줄 — 본문 3줄 · 첨부 곡 · 좋아요(분홍) · 댓글 · 시간
private struct FriendPostRow: View {
  let post: FriendPost
  let onTap: () -> Void
  let onLike: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Button(action: self.onTap) {
        VStack(alignment: .leading, spacing: 12) {
          Text(self.post.text)
            .wepliFont(.body)
            .foregroundStyle(WePLiColor.textPrimary)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
          if let song = self.post.song {
            HStack(spacing: 12) {
              RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 44, height: 44)
              VStack(alignment: .leading, spacing: 2) {
                Text(song.title).wepliFont(.subheadline).foregroundStyle(WePLiColor.textPrimary)
                Text("#\(song.artist)").wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.accent)
              }
              .lineLimit(1)
              Spacer(minLength: 0)
            }
          }
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      self.meta
    }
    .padding(EdgeInsets(top: 18, leading: 20, bottom: 16, trailing: 20))
    .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5) }
  }

  private var meta: some View {
    HStack(spacing: 14) {
      Button(action: self.onLike) {
        HStack(spacing: 4) {
          Image(systemName: self.post.isLiked ? "heart.fill" : "heart").font(.system(size: 14))
          Text("\(self.post.likeCount)").monospacedDigit()
        }
        .foregroundStyle(self.post.isLiked ? WePLiColor.highlight : WePLiColor.textTertiary)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("좋아요 \(self.post.likeCount)")
      .accessibilityAddTraits(self.post.isLiked ? .isSelected : [])
      HStack(spacing: 4) {
        Image(systemName: "bubble.left").font(.system(size: 14))
        Text("\(self.post.commentCount)")
      }
      .accessibilityElement(children: .combine)
      Spacer()
      Text(self.post.timeText)
    }
    .wepliFont(.caption, weight: .light)
    .foregroundStyle(WePLiColor.textTertiary)
  }
}

/// 들은 음악 — 최근 곡 · 둘 다 자주 듣는 가수(최근 한 달)
private struct FriendListenedTab: View {
  let store: StoreOf<FriendProfileFeature>
  let profile: FriendProfile

  var body: some View {
    VStack(alignment: .leading, spacing: 32) {
      VStack(spacing: 0) {
        ForEach(self.profile.recent) { track in
          Button {
            self.store.send(.recentTapped(track.id))
          } label: {
            HStack(spacing: 12) {
              RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 48, height: 48)
              VStack(alignment: .leading, spacing: 2) {
                Text(track.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
                Text("\(track.artist) · \(track.timeText)")
                  .wepliFont(.footnote, weight: .light)
                  .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
              }
              .lineLimit(1)
              Spacer(minLength: 0)
              Image(systemName: "play.circle").font(.system(size: 24, weight: .light))
                .foregroundStyle(WePLiColor.textMuted)
                .frame(width: 44, height: 44)
            }
            .padding(.leading, 20)
            .padding(.trailing, 8)
            .frame(height: 60)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
      }
      if !self.profile.sharedArtists.isEmpty {
        self.artists
      }
    }
    .padding(.top, 16)
  }

  private var artists: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text("둘 다 자주 듣는 가수").wepliFont(.headline).foregroundStyle(WePLiColor.textPrimary)
        Text("최근 한 달 기록이에요").wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textTertiary)
      }
      .padding(.horizontal, 20)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(self.profile.sharedArtists, id: \.self) { name in
            Button {
              self.store.send(.artistTapped(name))
            } label: {
              VStack(spacing: 8) {
                Circle().fill(WePLiColor.imagePlaceholder).frame(width: 80, height: 80)
                Text(name).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textSecondary).lineLimit(1)
              }
              .frame(width: 84)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 20)
      }
    }
  }
}
