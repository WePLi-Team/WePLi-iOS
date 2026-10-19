import SwiftUI

// MARK: - PlaylistSection

struct PlaylistSection: View {
  let title: String
  let playlists: [Playlist]
  let onPlaylistTapped: (Playlist) -> Void
  let onSeeAllTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // 헤더
      Button(action: onSeeAllTapped) {
        HStack(spacing: 4) {
          Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Color(hex: "F0F0F0"))

          Image(systemName: "chevron.right")
            .font(.system(size: 12))
            .foregroundColor(Color(hex: "D8D8DD"))
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)

      // 플레이리스트 목록
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(playlists) { playlist in
            PlaylistItemView(playlist: playlist)
              .onTapGesture { onPlaylistTapped(playlist) }
          }
        }
        .padding(.horizontal, 20)
      }
    }
  }
}

// MARK: - PlaylistItemView

struct PlaylistItemView: View {
  let playlist: Playlist

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // 커버 이미지 (플레이스홀더)
      RoundedRectangle(cornerRadius: 12)
        .fill(
          LinearGradient(
            colors: [Color.purple.opacity(0.6), Color.pink.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 136, height: 136)

      // 제목
      Text(playlist.title)
        .font(.system(size: 13, weight: .light))
        .foregroundColor(.white)
        .lineLimit(2)
        .frame(width: 136, alignment: .leading)
        .padding(.top, 12)
    }
  }
}
