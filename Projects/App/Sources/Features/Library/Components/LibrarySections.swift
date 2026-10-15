import SwiftUI

// UI-5c 세그먼트 · 상태 배지 · 세그먼트별 목록

/// 세그먼트 → 밑줄 탭(디자인 원칙 · DEC-009)
struct LibrarySegmentControl: View {
  let selected: LibrarySegment
  let onSelect: (LibrarySegment) -> Void

  var body: some View {
    WePLiUnderlineTabs(
      items: LibrarySegment.allCases,
      selected: self.selected,
      title: \.title,
      onSelect: self.onSelect
    )
  }
}

struct LibraryStatusBadge: View {
  let isLive: Bool

  var body: some View {
    Text(self.isLive ? "진행 중" : "완성")
      .wepliFont(.caption, weight: .semibold)
      .foregroundStyle(self.isLive ? WePLiColor.accent : WePLiColor.textTertiary)
      .padding(.horizontal, 8)
      .frame(height: 24)
      .background(self.isLive ? WePLiColor.accentStrong.opacity(0.16) : Color.white.opacity(0.08), in: Capsule())
  }
}

private struct Cover: View {
  var size: CGFloat
  var radius: CGFloat
  var systemImage = "music.note"

  var body: some View {
    RoundedRectangle(cornerRadius: self.radius)
      .fill(WePLiColor.imagePlaceholder)
      .frame(width: self.size, height: self.size)
      .overlay {
        Image(systemName: self.systemImage).font(.system(size: self.size * 0.3))
          .foregroundStyle(WePLiColor.textQuaternary)
      }
      .accessibilityHidden(true)
  }
}

struct LibraryPlaylistsSection: View {
  let playlists: [LibraryPlaylist]
  let onNew: () -> Void
  let onPlaylist: (LibraryPlaylist.ID) -> Void

  var body: some View {
    VStack(spacing: 0) {
      Button(action: self.onNew) {
        HStack(spacing: 14) {
          RoundedRectangle(cornerRadius: 12)
            .fill(WePLiColor.accentStrong.opacity(0.14))
            .frame(width: 60, height: 60)
            .overlay { Image(systemName: "plus").foregroundStyle(WePLiColor.accent) }
          Text("새 플레이리스트").wepliFont(.callout, weight: .medium).foregroundStyle(WePLiColor.textPrimary)
          Spacer()
        }
        .frame(height: 76)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      ForEach(self.playlists) { playlist in
        Button {
          self.onPlaylist(playlist.id)
        } label: {
          HStack(spacing: 14) {
            Cover(size: 60, radius: 12, systemImage: "music.note.list")
            VStack(alignment: .leading, spacing: 2) {
              Text(playlist.title).wepliFont(.callout, weight: .medium).foregroundStyle(WePLiColor.textPrimary)
              Text(playlist.subtitle).wepliFont(.footnote).foregroundStyle(WePLiColor.textQuaternary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
              .foregroundStyle(WePLiColor.textDisabled)
          }
          .frame(height: 76)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 12)
  }
}

struct LibraryRelaysSection: View {
  let library: Library
  let now: Date
  let onContinue: (LibraryLiveRelay.ID) -> Void
  let onRelay: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if self.library.liveRelays.isEmpty, self.library.completedRelays.isEmpty {
        // UI-10a 빈 상태 문구
        VStack(spacing: 8) {
          Text("아직 참여한 릴레이가 없어요").wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
          Text("진행 중인 릴레이에 곡을 추천해 보세요").wepliFont(.subheadline).foregroundStyle(WePLiColor.textQuaternary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
      }
      ForEach(self.library.liveRelays) { relay in
        self.liveCard(relay)
      }
      ForEach(self.library.completedRelays) { relay in
        Button {
          self.onRelay(relay.id)
        } label: {
          HStack(spacing: 12) {
            Cover(size: 52, radius: 10, systemImage: "music.note.list")
            VStack(alignment: .leading, spacing: 2) {
              Text(relay.title).wepliFont(.body, weight: .medium).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
              Text(relay.subtitle).wepliFont(.footnote).foregroundStyle(WePLiColor.textQuaternary).lineLimit(1)
            }
            Spacer(minLength: 0)
            LibraryStatusBadge(isLive: false)
          }
          .padding(.horizontal, 4)
          .frame(height: 72)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 16)
  }

  private func liveCard(_ relay: LibraryLiveRelay) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Button {
        self.onRelay(relay.id)
      } label: {
        HStack(spacing: 12) {
          Cover(size: 52, radius: 10, systemImage: "music.note.list")
          VStack(alignment: .leading, spacing: 2) {
            Text(relay.title).wepliFont(.body, weight: .semibold).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
            Text("완성까지 \(RemainingTimeFormatter.string(from: self.now, to: relay.endsAt))")
              .wepliFont(.footnote)
              .foregroundStyle(WePLiColor.textQuaternary)
              .monospacedDigit()
          }
          Spacer(minLength: 0)
          LibraryStatusBadge(isLive: true)
        }
      }
      .buttonStyle(.plain)
      HStack(spacing: 8) {
        self.stat(title: "내 추천곡", value: relay.myRecommendations)
        self.stat(title: "투표", value: relay.voteProgress)
      }
      Button {
        self.onContinue(relay.id)
      } label: {
        Text("이어서 투표하기")
          .wepliFont(.body, weight: .semibold)
          .foregroundStyle(WePLiColor.textOnCTA)
          .frame(maxWidth: .infinity)
          .frame(height: 42)
          .background(Capsule().fill(WePLiGradient.cta))
      }
      .buttonStyle(.plain)
    }
    .padding(14)
    .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 18))
  }

  private func stat(title: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
      Text(value).wepliFont(.body, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(WePLiColor.surface2, in: RoundedRectangle(cornerRadius: 12))
    .accessibilityElement(children: .combine)
  }
}

struct LibraryLikesSection: View {
  let library: Library
  let onSong: (String) -> Void
  let onPost: (LibrarySavedPost.ID) -> Void
  let onBrowse: () -> Void

  var body: some View {
    if self.library.likedSongs.isEmpty, self.library.savedPosts.isEmpty {
      WePLiEmptyState.library(onBrowseHome: self.onBrowse)
        .padding(.vertical, 60)
    } else {
      VStack(alignment: .leading, spacing: 6) {
        if !self.library.likedSongs.isEmpty {
          self.header("좋아요한 곡")
          ForEach(self.library.likedSongs, id: \.title) { song in
            Button {
              self.onSong(song.title)
            } label: {
              HStack(spacing: 12) {
                Cover(size: 48, radius: 4)
                VStack(alignment: .leading, spacing: 1) {
                  Text(song.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
                  Text(song.artist).wepliFont(.footnote, weight: .light)
                    .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
                }
                Spacer()
                Image(systemName: "heart.fill").foregroundStyle(WePLiColor.highlight).accessibilityLabel("좋아요함")
              }
              .frame(height: 62)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
          }
        }
        if !self.library.savedPosts.isEmpty {
          self.header("저장한 게시글").padding(.top, 18)
          ForEach(self.library.savedPosts) { post in
            Button {
              self.onPost(post.id)
            } label: {
              HStack(spacing: 12) {
                AvatarCircle(name: post.author)
                VStack(alignment: .leading, spacing: 1) {
                  Text(post.title).wepliFont(.body, weight: .medium).foregroundStyle(WePLiColor.textPrimary)
                    .lineLimit(1)
                  Text(post.subtitle).wepliFont(.footnote).foregroundStyle(WePLiColor.textQuaternary)
                }
                Spacer()
                Image(systemName: "bookmark.fill").foregroundStyle(WePLiColor.textPrimary).accessibilityLabel("저장함")
              }
              .frame(height: 66)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 20)
    }
  }

  private func header(_ text: String) -> some View {
    Text(text).wepliFont(.subheadline, weight: .semibold).foregroundStyle(WePLiColor.textQuaternary)
      .accessibilityAddTraits(.isHeader)
  }
}

/// 40pt 원형 아바타 자리 표시
private struct AvatarCircle: View {
  let name: String

  var body: some View {
    Circle().fill(WePLiColor.imagePlaceholder).frame(width: 40, height: 40)
      .overlay {
        Text(self.name.prefix(1).uppercased()).wepliFont(.subheadline, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary.opacity(0.85))
      }
      .accessibilityHidden(true)
  }
}
