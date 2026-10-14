import SwiftUI

// UI-5b 본문 — 인기곡 Top 5 · 앨범(가로) · 위플리에서 함께 듣는 곳 · 함께 많이 듣는 아티스트(가로). 섹션 간격 32

struct ArtistPopularSongs: View {
  let songs: [ArtistDetail.Song]
  let onHeader: () -> Void
  let onSong: (ArtistDetail.Song.ID) -> Void
  let onMenu: (ArtistDetail.Song.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Button(action: self.onHeader) {
        HStack(spacing: 2) {
          ArtistSectionTitle(text: "인기곡")
          Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(WePLiColor.textMuted)
        }
      }
      .buttonStyle(.plain)

      ForEach(Array(self.songs.enumerated()), id: \.element.id) { index, song in
        HStack(spacing: 12) {
          Button {
            self.onSong(song.id)
          } label: {
            HStack(spacing: 12) {
              ArtistArtwork(size: 48, radius: 4)
              Text("\(index + 1)")
                .wepliFont(.body, weight: .semibold)
                .foregroundStyle(WePLiColor.textPrimary.opacity(0.8))
                .frame(width: 16)
              VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                  .wepliFont(.body)
                  .foregroundStyle(WePLiColor.textPrimary)
                Text(song.subtitle)
                  .wepliFont(.footnote, weight: .light)
                  .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
              }
              .lineLimit(1)
              .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)

          Button {
            self.onMenu(song.id)
          } label: {
            HStack(spacing: 3) {
              ForEach(0 ..< 3, id: \.self) { _ in
                Circle().fill(WePLiColor.tabInactiveGlass).frame(width: 4, height: 4)
              }
            }
            .frame(width: 36, height: 44)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .padding(.trailing, -8)
          .accessibilityLabel("\(song.title) 더보기")
        }
        .frame(height: 62)
      }
    }
  }
}

struct ArtistAlbums: View {
  let albums: [ArtistDetail.Album]
  let onAlbum: (ArtistDetail.Album.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ArtistSectionTitle(text: "앨범")
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 12) {
          ForEach(self.albums) { album in
            Button {
              self.onAlbum(album.id)
            } label: {
              VStack(alignment: .leading, spacing: 8) {
                ArtistArtwork(size: 140, radius: 12)
                VStack(alignment: .leading, spacing: 2) {
                  Text(album.title)
                    .wepliFont(.subheadline)
                    .foregroundStyle(WePLiColor.textPrimary)
                  Text(album.meta)
                    .wepliFont(.caption)
                    .foregroundStyle(WePLiColor.textQuaternary)
                }
                .lineLimit(1)
              }
              .frame(width: 140, alignment: .leading)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 20)
      }
      .padding(.horizontal, -20)
    }
  }
}

struct ArtistPlaces: View {
  let artist: ArtistDetail
  let onPlace: (ArtistDetail.Place.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        ArtistSectionTitle(text: "위플리에서 함께 듣는 곳")
        Text("\(self.artist.id)의 곡이 담긴 플레이리스트와 게시글이에요")
          .wepliFont(.caption, weight: .light)
          .foregroundStyle(WePLiColor.textTertiary)
      }
      VStack(spacing: 0) {
        ForEach(Array(self.artist.places.enumerated()), id: \.element.id) { index, place in
          Button {
            self.onPlace(place.id)
          } label: {
            HStack(spacing: 12) {
              ArtistArtwork(size: 52, radius: 8)
              VStack(alignment: .leading, spacing: 2) {
                Text(place.title)
                  .wepliFont(.body, weight: .medium)
                  .foregroundStyle(WePLiColor.textPrimary)
                Text(self.artist.meta(for: place))
                  .wepliFont(.footnote)
                  .foregroundStyle(WePLiColor.textQuaternary)
              }
              .lineLimit(1)
              .frame(maxWidth: .infinity, alignment: .leading)
              Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(WePLiColor.textDisabled)
            }
            .frame(height: 72)
            .overlay(alignment: .bottom) {
              if index < self.artist.places.count - 1 {
                Rectangle().fill(WePLiColor.disabledFill).frame(height: 0.5)
              }
            }
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.vertical, 4)
      .padding(.horizontal, 14)
      .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
  }
}

struct ArtistRelated: View {
  let names: [String]
  let onArtist: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      ArtistSectionTitle(text: "함께 많이 듣는 아티스트")
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 12) {
          ForEach(self.names, id: \.self) { name in
            Button {
              self.onArtist(name)
            } label: {
              VStack(spacing: 8) {
                Circle()
                  .fill(WePLiColor.surface4)
                  .frame(width: 72, height: 72)
                  .overlay {
                    Image(systemName: "person.fill")
                      .font(.system(size: 26))
                      .foregroundStyle(WePLiColor.textQuaternary)
                  }
                Text(name)
                  .wepliFont(.caption, weight: .light)
                  .foregroundStyle(WePLiColor.textSecondary)
                  .lineLimit(1)
                  .frame(width: 80)
              }
              .frame(width: 80)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 20)
      }
      .padding(.horizontal, -20)
    }
  }
}

private struct ArtistSectionTitle: View {
  let text: String

  var body: some View {
    Text(self.text)
      .wepliFont(.headline)
      .foregroundStyle(WePLiColor.textPrimary)
      .accessibilityAddTraits(.isHeader)
  }
}

/// 앨범 아트 자리 표시 — 아트 URL이 생기면 Kingfisher로 바꾼다
private struct ArtistArtwork: View {
  let size: CGFloat
  let radius: CGFloat

  var body: some View {
    RoundedRectangle(cornerRadius: self.radius)
      .fill(WePLiColor.surface4)
      .frame(width: self.size, height: self.size)
      .overlay {
        Image(systemName: "music.note")
          .font(.system(size: self.size * 0.3, weight: .light))
          .foregroundStyle(WePLiColor.textQuaternary)
      }
      .accessibilityHidden(true)
  }
}
