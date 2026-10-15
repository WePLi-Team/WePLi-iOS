import SwiftUI

// UI-14b 구성 요소 — 히어로 500 · 동작 줄 4칸 · 내 추천곡 결과 · 최종 순위 · 댓글 · 다음 릴레이 · 비슷한 완성 플리

struct CompletedPlaylistHero: View {
  let playlist: CompletedPlaylist
  let onExport: () -> Void
  let onPlayAll: () -> Void

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      // 미결정 — 커버 사진이 아직 없어 이미지 자리 색
      WePLiColor.imagePlaceholder
      VStack(spacing: 0) {
        LinearGradient(colors: [.black.opacity(0.6), .black.opacity(0)], startPoint: .top, endPoint: .bottom)
          .frame(height: 170)
        Spacer(minLength: 0)
        LinearGradient(
          stops: [
            .init(color: .black.opacity(0.01), location: 0),
            .init(color: .black.opacity(0.1), location: 0.2163),
            .init(color: .black.opacity(0.2), location: 0.4471),
            .init(color: .black.opacity(0.5932), location: 0.66),
            .init(color: .black, location: 1),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: 360)
      }
      VStack(alignment: .leading, spacing: 18) {
        VStack(alignment: .leading, spacing: 6) {
          Text("RelayList · 완성")
            .wepliFont(.footnote, weight: .semibold)
            .foregroundStyle(WePLiColor.accent)
          Text(self.playlist.title)
            .wepliFont(.title1)
            .foregroundStyle(WePLiColor.textPrimary)
            .accessibilityAddTraits(.isHeader)
          Text(self.playlist.stats)
            .wepliFont(.subheadline, weight: .light)
            .foregroundStyle(WePLiColor.textMuted)
        }
        HStack(spacing: 10) {
          Button(action: self.onExport) {
            Text(self.playlist.exportTitle)
              .wepliFont(.body, weight: .semibold)
              .foregroundStyle(WePLiColor.textOnCTA)
              .frame(maxWidth: .infinity)
              .frame(height: 50)
              .background(Capsule().fill(WePLiGradient.cta))
          }
          .buttonStyle(.plain)
          Button(action: self.onPlayAll) {
            HStack(spacing: 7) {
              Image(systemName: "play.fill").font(.system(size: 11))
              Text("전체듣기").wepliFont(.subheadline, weight: .semibold)
            }
            .foregroundStyle(WePLiColor.textPrimary)
            .padding(.horizontal, 18)
            .frame(height: 50)
            .background(WePLiColor.secondaryButtonFill, in: Capsule())
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 24)
    }
    .frame(height: 500)
    .clipped()
  }
}

/// 좋아요(켜면 #FE82DB, 수 +1) · 댓글 · 공유 · 저장(켜면 #C8CFFF · 「저장됨」)
struct CompletedPlaylistActions: View {
  let playlist: CompletedPlaylist
  let onLike: () -> Void
  let onComments: () -> Void
  let onShare: () -> Void
  let onSave: () -> Void

  var body: some View {
    HStack(spacing: 0) {
      self.cell(
        systemName: self.playlist.isLiked ? "heart.fill" : "heart",
        label: self.playlist.likeCount.formatted(.number.locale(Locale(identifier: "en_US"))),
        tint: self.playlist.isLiked ? WePLiColor.highlight : nil,
        accessibility: self.playlist.isLiked ? "좋아요 취소" : "좋아요",
        action: self.onLike
      )
      self.cell(
        systemName: "bubble.left",
        label: "\(self.playlist.commentCount)",
        accessibility: "댓글",
        action: self.onComments
      )
      self.cell(systemName: "square.and.arrow.up", label: "공유", accessibility: "공유", action: self.onShare)
      self.cell(
        systemName: self.playlist.isSaved ? "bookmark.fill" : "bookmark",
        label: self.playlist.isSaved ? "저장됨" : "저장",
        tint: self.playlist.isSaved ? WePLiColor.accent : nil,
        accessibility: self.playlist.isSaved ? "저장 취소" : "저장",
        action: self.onSave
      )
    }
    .padding(.horizontal, 8)
    .padding(.top, 20)
  }

  private func cell(
    systemName: String,
    label: String,
    tint: Color? = nil,
    accessibility: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: systemName)
          .font(.system(size: 21))
          .foregroundStyle(tint ?? WePLiColor.textMuted)
          .frame(width: 25, height: 25)
        Text(label)
          .wepliFont(.caption, weight: .light)
          .monospacedDigit()
          .foregroundStyle(tint ?? WePLiColor.textTertiary)
      }
      .frame(maxWidth: .infinity)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(accessibility)
  }
}

/// 「내 추천곡 EASY가 최종 4위에 올랐어요」 + 「1위 예측 적중 · 예언자 +1」
struct CompletedPlaylistMyResult: View {
  let song: CompletedPlaylist.Song
  let rank: Int
  let predictionResult: String?

  var body: some View {
    HStack(spacing: 12) {
      Circle().fill(WePLiColor.imagePlaceholder).frame(width: 36, height: 36)
      VStack(alignment: .leading, spacing: 2) {
        (Text("내 추천곡 ")
          + Text(self.song.title).font(.custom(
            WePLiFont.Weight.semibold.postScriptName,
            size: 14,
            relativeTo: .subheadline
          ))
          .foregroundColor(WePLiColor.accent)
          + Text("가 최종 \(self.rank)위에 올랐어요"))
          .wepliFont(.subheadline)
          .foregroundStyle(WePLiColor.textPrimary)
        if let predictionResult = self.predictionResult {
          Text(predictionResult)
            .wepliFont(.caption, weight: .light)
            .foregroundStyle(WePLiColor.positive)
        }
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 26)
    .accessibilityElement(children: .combine)
  }
}

/// 최종 순위 — 줄 64: 아트 48 → 순위 → 곡명 · 가수(내 곡은 #C8CFFF) → 추천한 사람 아바타 22 → ···
struct CompletedPlaylistRanking: View {
  let playlist: CompletedPlaylist
  let onSong: (CompletedPlaylist.Song.ID) -> Void
  let onMore: (CompletedPlaylist.Song.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HomeSectionHeader(title: "최종 순위", subtitle: self.playlist.rankingMeta)
        .padding(.top, 34)
        .padding(.bottom, 8)
      ForEach(Array(self.playlist.ranking.enumerated()), id: \.element.id) { index, song in
        HStack(spacing: 12) {
          Button {
            self.onSong(song.id)
          } label: {
            HStack(spacing: 12) {
              RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 48, height: 48)
              Text("\(index + 1)")
                .wepliFont(.body, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(WePLiColor.textPrimary)
                .frame(width: 18)
              VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                  .wepliFont(.body)
                  .foregroundStyle(song.isMine ? WePLiColor.accent : WePLiColor.textPrimary)
                Text(song.artist)
                  .wepliFont(.footnote, weight: .light)
                  .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
              }
              .lineLimit(1)
              .frame(maxWidth: .infinity, alignment: .leading)
              Circle()
                .fill(WePLiColor.surface2)
                .frame(width: 22, height: 22)
                .accessibilityLabel("추천한 사람 \(song.recommender)")
            }
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          HomeMoreButton(label: "\(song.title) 더보기") { self.onMore(song.id) }
        }
        .padding(.leading, 20)
        .padding(.trailing, 8)
        .frame(height: 64)
      }
      Text("\(self.playlist.songCount)곡 모두 보기")
        .wepliFont(.subheadline)
        .foregroundStyle(WePLiColor.textQuaternary)
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }
  }
}
