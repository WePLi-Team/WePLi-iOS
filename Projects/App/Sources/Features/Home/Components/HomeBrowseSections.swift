import SwiftUI

// UI-12a 둘러보기 섹션 — 커뮤니티 인기글 · 위플리 인기 랭킹 · 추천 플리 · 테마별 플리 · Youtube Cover

/// 커뮤니티 인기글 — 제목 15 SemiBold · 본문 1줄 · 「작성자 · 좋아요 · 댓글」 · 썸네일 56
struct HomePopularPostsSection: View {
  let posts: [HomePopularPost]
  let onTap: (HomePopularPost.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HomeSectionHeader(title: "커뮤니티 인기글", subtitle: "오늘 댓글이 가장 많이 달린 글이에요")
      ForEach(self.posts) { post in
        Button {
          self.onTap(post.id)
        } label: {
          HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
              Text(post.title)
                .wepliFont(.body, weight: .semibold)
                .foregroundStyle(WePLiColor.textPrimary)
              Text(post.body)
                .wepliFont(.footnote, weight: .light)
                .foregroundStyle(WePLiColor.textSecondary)
              Text(post.meta)
                .wepliFont(.caption)
                .monospacedDigit()
                .foregroundStyle(WePLiColor.textQuaternary)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 56, height: 56)
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 10)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
  }
}

/// 위플리 인기 랭킹 — 원형 80 · 이름 12 Light #B5B5C0
struct HomePopularArtistsSection: View {
  let names: [String]
  let onTap: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HomeSectionHeader(title: "위플리 인기 랭킹", subtitle: "위플리 차트에서 인기가 많은 가수들을 모아봤어요")
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 12) {
          ForEach(self.names, id: \.self) { name in
            Button {
              self.onTap(name)
            } label: {
              VStack(spacing: 8) {
                Circle().fill(WePLiColor.imagePlaceholder).frame(width: 80, height: 80)
                Text(name)
                  .wepliFont(.caption, weight: .light)
                  .foregroundStyle(WePLiColor.textSecondary)
                  .lineLimit(1)
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

/// 위플리 추천 플레이리스트 — 커버 150(모서리 8) 뒤로 레코드판 130이 오른쪽으로 비친다(9b 모양)
struct HomeRecommendedPlaylistsSection: View {
  let playlists: [HomePlaylistCard]
  let onTap: (HomePlaylistCard.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HomeSectionHeader(title: "위플리 추천 플레이리스트", subtitle: "오늘 기분에 맞춰 위플리가 골랐어요")
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 20) {
          ForEach(self.playlists) { playlist in
            Button {
              self.onTap(playlist.id)
            } label: {
              VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .leading) {
                  Circle()
                    .fill(WePLiColor.surface1)
                    .frame(width: 130, height: 130)
                    .overlay(Circle().fill(WePLiColor.imagePlaceholder).frame(width: 94, height: 94))
                    .offset(x: 28)
                  RoundedRectangle(cornerRadius: 8)
                    .fill(WePLiColor.imagePlaceholder)
                    .frame(width: 150, height: 150)
                    .shadow(color: .black.opacity(0.5), radius: 8, x: 6)
                }
                .frame(width: 150, height: 150, alignment: .leading)
                Text(playlist.title)
                  .wepliFont(.footnote)
                  .foregroundStyle(WePLiColor.textPrimary)
                  .lineLimit(2)
                  .multilineTextAlignment(.leading)
              }
              .frame(width: 150, alignment: .leading)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 20)
        .padding(.trailing, 8)
      }
    }
  }
}

/// 테마별 플레이리스트 — 설명 없음, 136(모서리 12) · 제목 2줄
struct HomeThemePlaylistsSection: View {
  let playlists: [HomePlaylistCard]
  let onTap: (HomePlaylistCard.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HomeSectionHeader(title: "테마별 플레이리스트")
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 12) {
          ForEach(self.playlists) { playlist in
            Button {
              self.onTap(playlist.id)
            } label: {
              VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 12).fill(WePLiColor.imagePlaceholder).frame(width: 136, height: 136)
                Text(playlist.title)
                  .wepliFont(.footnote)
                  .foregroundStyle(.white)
                  .lineLimit(2)
                  .multilineTextAlignment(.leading)
              }
              .frame(width: 136, alignment: .leading)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 20)
      }
    }
  }
}

/// Youtube Cover — 「Youtube」 700 + 「Cover」 300 #A3A3A3, 썸네일 262×148(모서리 10)
struct HomeVideosSection: View {
  let videos: [HomeVideo]
  let onTap: (HomeVideo.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 6) {
        Text("Youtube").wepliFont(.headline, weight: .bold).foregroundStyle(WePLiColor.textPrimary)
        Text("Cover").wepliFont(.headline, weight: .light).foregroundStyle(WePLiColor.textTertiary)
        Image(systemName: "chevron.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(WePLiColor.textMuted)
          .frame(width: 18, height: 18)
          .padding(.leading, -4)
      }
      .padding(.horizontal, 20)
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(.isHeader)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 12) {
          ForEach(self.videos) { video in
            Button {
              self.onTap(video.id)
            } label: {
              VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 10)
                  .fill(WePLiColor.imagePlaceholder)
                  .frame(width: 262, height: 148)
                  .padding(.bottom, 4)
                Text(video.title)
                  .wepliFont(.subheadline, weight: .semibold)
                  .foregroundStyle(WePLiColor.textPrimary)
                Text(video.channel)
                  .wepliFont(.caption)
                  .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
              }
              .lineLimit(1)
              .frame(width: 262, alignment: .leading)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 20)
      }
    }
  }
}
