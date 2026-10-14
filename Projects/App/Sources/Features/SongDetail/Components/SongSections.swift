import SwiftUI

// UI-2d 3분할 카드 · 곡/앨범 정보 · 함께 들으면 좋은 곡 · 이 가수의 다른 앨범

struct SongActionBar: View {
  let song: SongDetail
  let onLike: () -> Void
  let onComments: () -> Void
  let onAddToPlaylist: () -> Void

  var body: some View {
    HStack(spacing: 0) {
      self.item(
        systemImage: self.song.isLiked ? "heart.fill" : "heart",
        title: SongCount.string(self.song.likeCount),
        tint: self.song.isLiked ? WePLiColor.highlight : WePLiColor.textMuted,
        label: "좋아요",
        action: self.onLike
      )
      .accessibilityAddTraits(self.song.isLiked ? .isSelected : [])
      Rectangle().fill(Color.white.opacity(0.08)).frame(width: 0.5, height: 32)
      self.item(
        systemImage: "bubble.left",
        title: SongCount.string(self.song.commentCount),
        tint: WePLiColor.textMuted,
        label: "댓글",
        action: self.onComments
      )
      Rectangle().fill(Color.white.opacity(0.08)).frame(width: 0.5, height: 32)
      self.item(
        systemImage: "text.badge.plus",
        title: "플리에 담기",
        tint: WePLiColor.textMuted,
        label: "플리에 담기",
        action: self.onAddToPlaylist
      )
    }
    .frame(height: 64)
    .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 18))
  }

  private func item(
    systemImage: String,
    title: String,
    tint: Color,
    label: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: systemImage)
          .font(.system(size: 19))
          .foregroundStyle(tint)
        Text(title)
          .wepliFont(.caption)
          .foregroundStyle(WePLiColor.textSecondary)
          .monospacedDigit()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label == title ? label : "\(label) \(title)")
  }
}

struct SongInfoCards: View {
  let song: SongDetail
  let onAlbum: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      self.card(title: "곡 정보") {
        self.row("작사", value: self.song.lyricist)
        self.divider
        self.row("작곡", value: self.song.composer)
        self.divider
        HStack(spacing: 6) {
          self.label("장르")
          ForEach(self.song.genres, id: \.self) { genre in
            Text(genre)
              .wepliFont(.footnote)
              .foregroundStyle(WePLiColor.textMuted)
              .padding(.horizontal, 10)
              .frame(height: 26)
              .background(WePLiColor.surface2, in: Capsule())
          }
          Spacer(minLength: 0)
        }
        .frame(height: 46)
      }
      self.card(title: "앨범 정보") {
        Button(action: self.onAlbum) {
          HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6).fill(WePLiColor.imagePlaceholder).frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 2) {
              Text(self.song.album.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
              Text(self.song.album.artist).wepliFont(.footnote).foregroundStyle(WePLiColor.textQuaternary)
            }
            Spacer()
            Image(systemName: "chevron.right")
              .font(.system(size: 13, weight: .semibold))
              .foregroundStyle(WePLiColor.textDisabled)
          }
          .frame(height: 68)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        self.divider
        self.row("발매일", value: self.song.album.releaseDate)
        self.divider
        self.row("유형", value: self.song.album.type)
      }
    }
  }

  private var divider: some View {
    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5)
  }

  private func label(_ text: String) -> some View {
    Text(text)
      .wepliFont(.subheadline)
      .foregroundStyle(WePLiColor.textQuaternary)
      .frame(width: 52, alignment: .leading)
  }

  private func row(_ title: String, value: String) -> some View {
    HStack(spacing: 6) {
      self.label(title)
      Text(value)
        .wepliFont(.body)
        .foregroundStyle(WePLiColor.textPrimary)
      Spacer(minLength: 0)
    }
    .frame(height: 46)
    .accessibilityElement(children: .combine)
  }

  private func card(title: String, @ViewBuilder content: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .wepliFont(.headline)
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      VStack(spacing: 0) { content() }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 18))
    }
  }
}

struct SongRelatedSections: View {
  let song: SongDetail
  let onSong: (SongDetail.RelatedSong.ID) -> Void
  let onAlbum: (SongDetail.OtherAlbum.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 28) {
      VStack(alignment: .leading, spacing: 6) {
        self.header("함께 들으면 좋은 곡")
        ForEach(self.song.related) { related in
          Button {
            self.onSong(related.id)
          } label: {
            HStack(spacing: 12) {
              RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 44, height: 44)
              VStack(alignment: .leading, spacing: 2) {
                Text(related.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
                Text(related.artist).wepliFont(.footnote).foregroundStyle(WePLiColor.textQuaternary)
              }
              Spacer(minLength: 0)
              Image(systemName: "ellipsis")
                .foregroundStyle(WePLiColor.tabInactiveGlass)
                .frame(width: 36, height: 44)
            }
            .frame(height: 60)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .padding(.horizontal, 20)
        }
      }
      VStack(alignment: .leading, spacing: 12) {
        self.header("이 가수의 다른 앨범")
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            ForEach(self.song.otherAlbums) { album in
              Button {
                self.onAlbum(album.id)
              } label: {
                VStack(alignment: .leading, spacing: 4) {
                  RoundedRectangle(cornerRadius: 10).fill(WePLiColor.imagePlaceholder).frame(width: 140, height: 140)
                  Text(album.title).wepliFont(.subheadline).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
                  Text(album.subtitle).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
                }
                .frame(width: 140, alignment: .leading)
              }
              .buttonStyle(.plain)
            }
          }
          .padding(.horizontal, 20)
        }
      }
    }
  }

  private func header(_ text: String) -> some View {
    Text(text)
      .wepliFont(.headline)
      .foregroundStyle(WePLiColor.textPrimary)
      .padding(.horizontal, 20)
      .accessibilityAddTraits(.isHeader)
  }
}

/// 「10,123」
enum SongCount {
  static func string(_ count: Int) -> String {
    count.formatted(.number.locale(Locale(identifier: "en_US")))
  }
}
