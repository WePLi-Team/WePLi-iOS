import SwiftUI

// UI-3d 헤더 · 아티스트 · 수록곡

struct PlaylistHeader: View {
  let playlist: PlaylistDetail
  let isIntroductionExpanded: Bool
  let onPlay: () -> Void
  let onShuffle: () -> Void
  let onIntroduction: () -> Void

  var body: some View {
    VStack(spacing: 14) {
      RoundedRectangle(cornerRadius: 16)
        .fill(WePLiColor.surface4)
        .frame(width: 220, height: 220)
        .overlay {
          Image(systemName: "music.note.list")
            .font(.system(size: 46, weight: .light))
            .foregroundStyle(WePLiColor.textQuaternary)
        }
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.55), radius: 30, y: 24)
        .accessibilityHidden(true)

      Text(self.playlist.title)
        .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 21, relativeTo: .title2))
        .foregroundStyle(WePLiColor.textPrimary)
        .multilineTextAlignment(.center)
        .padding(.top, 6)

      HStack(spacing: 8) {
        Circle()
          .fill(WePLiColor.surface1)
          .frame(width: 22, height: 22)
          .overlay {
            Text("W")
              .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 10))
              .foregroundStyle(WePLiColor.textPrimary)
          }
          .accessibilityHidden(true)
        Text(self.playlist.curator)
          .wepliFont(.subheadline, weight: .semibold)
          .foregroundStyle(WePLiColor.accent)
      }

      Text(self.playlist.info)
        .wepliFont(.footnote)
        .foregroundStyle(WePLiColor.textQuaternary)

      HStack(spacing: 10) {
        Button(action: self.onPlay) {
          Label("재생", systemImage: "play.fill")
            .wepliFont(.callout, weight: .semibold)
            .foregroundStyle(WePLiColor.textOnCTA)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Capsule().fill(WePLiGradient.cta))
        }
        .buttonStyle(.plain)
        Button(action: self.onShuffle) {
          Label("셔플", systemImage: "shuffle")
            .wepliFont(.callout, weight: .semibold)
            .foregroundStyle(WePLiColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(WePLiColor.secondaryButtonFill, in: Capsule())
        }
        .buttonStyle(.plain)
      }
      .padding(.top, 4)

      // 긴 소개글은 두 줄로 줄이고 「더보기」로 펼친다(UI-3d 노트 02)
      Button(action: self.onIntroduction) {
        VStack(alignment: .leading, spacing: 4) {
          Text(self.playlist.introduction)
            .wepliFont(.subheadline)
            .foregroundStyle(WePLiColor.textSecondary)
            .lineLimit(self.isIntroductionExpanded ? nil : 2)
            .multilineTextAlignment(.leading)
          if !self.isIntroductionExpanded {
            Text("더보기")
              .wepliFont(.subheadline, weight: .semibold)
              .foregroundStyle(WePLiColor.textPrimary)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .buttonStyle(.plain)
      .accessibilityHint(self.isIntroductionExpanded ? "소개글 접기" : "소개글 펼치기")
    }
    .padding(.horizontal, 20)
    .padding(.top, 108)
    .background(alignment: .top) {
      ZStack {
        Circle()
          .fill(WePLiColor.accentChip.opacity(0.6))
          .frame(width: 520, height: 520)
          .blur(radius: 60)
          .offset(x: -40, y: -60)
        LinearGradient(
          stops: [
            .init(color: .black.opacity(0.1), location: 0),
            .init(color: .black.opacity(0.55), location: 0.55),
            .init(color: .black, location: 1),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
      }
      .frame(height: 600)
      .clipped()
      .accessibilityHidden(true)
    }
  }
}

struct PlaylistArtistSection: View {
  let artists: [PlaylistDetail.Artist]
  let onArtist: (PlaylistDetail.Artist.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("아티스트")
        .wepliFont(.headline)
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 12) {
          ForEach(self.artists) { artist in
            Button {
              self.onArtist(artist.id)
            } label: {
              VStack(spacing: 8) {
                Circle().fill(WePLiColor.surface4).frame(width: 72, height: 72)
                  .overlay {
                    Image(systemName: "person.fill")
                      .font(.system(size: 26))
                      .foregroundStyle(WePLiColor.textQuaternary)
                  }
                Text(artist.name)
                  .wepliFont(.caption, weight: .light)
                  .foregroundStyle(WePLiColor.textSecondary)
                  .lineLimit(1)
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

struct PlaylistTrackSection: View {
  let playlist: PlaylistDetail
  let onTrack: (PlaylistDetail.Track.ID) -> Void
  let onMore: (PlaylistDetail.Track.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        Text("수록곡")
          .wepliFont(.headline)
          .foregroundStyle(WePLiColor.textPrimary)
        Text("\(self.playlist.totalTrackCount)")
          .wepliFont(.body, weight: .semibold)
          .foregroundStyle(WePLiColor.accentStrong)
      }
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(.isHeader)
      ForEach(self.playlist.tracks) { track in
        HStack(spacing: 12) {
          Button {
            self.onTrack(track.id)
          } label: {
            HStack(spacing: 12) {
              RoundedRectangle(cornerRadius: 4).fill(WePLiColor.surface4).frame(width: 48, height: 48)
              VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                  .wepliFont(.body)
                  .foregroundStyle(WePLiColor.textPrimary)
                  .lineLimit(1)
                Text(track.artist)
                  .wepliFont(.footnote, weight: .light)
                  .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
                  .lineLimit(1)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          Button {
            self.onMore(track.id)
          } label: {
            Image(systemName: "ellipsis")
              .foregroundStyle(WePLiColor.tabInactiveGlass)
              .frame(width: 36, height: 44)
          }
          .buttonStyle(.plain)
          .padding(.trailing, -8)
          .accessibilityLabel("\(track.title) 더보기")
        }
        .frame(height: 62)
      }
    }
  }
}
