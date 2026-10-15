import SwiftUI

// UI-14b 아래쪽 — 댓글 미리보기 · 호스트의 다음 릴레이(알림 받기) · 비슷한 완성 플리

struct CompletedPlaylistComments: View {
  let count: Int
  let comments: [CompletedPlaylist.Comment]
  let onOpen: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Button(action: self.onOpen) {
        HStack(spacing: 2) {
          Text("댓글 \(self.count)")
            .wepliFont(.headline)
            .foregroundStyle(WePLiColor.textPrimary)
          Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(WePLiColor.textMuted)
            .frame(width: 18, height: 18)
        }
      }
      .buttonStyle(.plain)
      .accessibilityAddTraits(.isHeader)
      ForEach(self.comments) { comment in
        HStack(alignment: .top, spacing: 12) {
          Circle().fill(WePLiColor.imagePlaceholder).frame(width: 34, height: 34)
          VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
              Text(comment.author).wepliFont(.footnote, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
              Text(comment.timeText).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textQuaternary)
            }
            Text(comment.text)
              .wepliFont(.subheadline, weight: .light)
              .foregroundStyle(WePLiColor.textMuted)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          VStack(spacing: 2) {
            Image(systemName: "heart").font(.system(size: 13)).foregroundStyle(WePLiColor.tabInactiveGlass)
            Text("\(comment.likeCount)")
              .font(.custom(WePLiFont.Weight.regular.postScriptName, size: 11, relativeTo: .caption2))
              .foregroundStyle(WePLiColor.textQuaternary)
          }
          .frame(width: 28)
          .padding(.top, 2)
          .accessibilityLabel("좋아요 \(comment.likeCount)")
        }
      }
      Button(action: self.onOpen) {
        Text("댓글 남기기")
          .wepliFont(.subheadline, weight: .light)
          .foregroundStyle(WePLiColor.textQuaternary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 16)
          .frame(height: 44)
          .background(WePLiColor.chipOff, in: Capsule())
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 20)
    .padding(.top, 38)
  }
}

struct CompletedPlaylistNextRelay: View {
  let host: String
  let relay: CompletedPlaylist.NextRelay
  let isAlertOn: Bool
  let onAlert: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      VStack(alignment: .leading, spacing: 4) {
        Text("\(self.host)의 다음 릴레이")
          .wepliFont(.headline)
          .foregroundStyle(WePLiColor.textPrimary)
          .accessibilityAddTraits(.isHeader)
        Text("이번 릴레이 호스트가 준비 중이에요")
          .wepliFont(.caption, weight: .light)
          .foregroundStyle(WePLiColor.textTertiary)
      }
      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 52, height: 52)
        VStack(alignment: .leading, spacing: 2) {
          Text(self.relay.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
          Text(self.relay.meta)
            .wepliFont(.footnote, weight: .light)
            .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
        Button(action: self.onAlert) {
          Text(self.isAlertOn ? "알림 받는 중" : "알림 받기")
            .wepliFont(.footnote, weight: .semibold)
            .foregroundStyle(self.isAlertOn ? WePLiColor.accent : WePLiColor.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(self.isAlertOn ? WePLiColor.chipOn : WePLiColor.secondaryButtonFill, in: Capsule())
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 38)
  }
}

struct CompletedPlaylistSimilar: View {
  let playlists: [SimilarPlaylist]
  let onTap: (SimilarPlaylist.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HomeSectionHeader(title: "비슷한 완성 플리", subtitle: "이 플리에 좋아요한 사람들이 많이 들었어요")
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 12) {
          ForEach(self.playlists) { playlist in
            Button {
              self.onTap(playlist.id)
            } label: {
              VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 136, height: 136)
                Text(playlist.title)
                  .wepliFont(.footnote, weight: .light)
                  .foregroundStyle(WePLiColor.textPrimary)
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
    .padding(.top, 38)
  }
}
