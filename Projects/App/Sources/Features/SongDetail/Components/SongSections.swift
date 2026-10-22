import SwiftUI

// UI-2d v2 섹션 — 이 곡이 올라간 릴레이 · 곡 정보(구분선 목록) · 댓글 · 함께 들으면 좋은 곡 · 이 가수의 다른 앨범
// 원본 노트 02: 회색 상자 3개를 없애고 곡 · 앨범 정보는 구분선만 있는 한 목록으로 합쳤다.

/// 섹션 머리 — 18 SemiBold, 누르는 섹션은 오른쪽 화살표
struct SongSectionHeader: View {
  let title: String
  var subtitle: String?
  var action: (() -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      if let action = self.action {
        Button(action: action) { self.titleRow(showsArrow: true) }
          .buttonStyle(.plain)
      } else {
        self.titleRow(showsArrow: false)
      }
      if let subtitle = self.subtitle {
        Text(subtitle)
          .wepliFont(.caption, weight: .light)
          .foregroundStyle(WePLiColor.textTertiary)
      }
    }
    .padding(.horizontal, 20)
  }

  private func titleRow(showsArrow: Bool) -> some View {
    HStack(spacing: 2) {
      Text(self.title)
        .wepliFont(.headline)
        .foregroundStyle(WePLiColor.textPrimary)
      if showsArrow {
        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(WePLiColor.textMuted)
      }
    }
    .contentShape(Rectangle())
    .accessibilityAddTraits(.isHeader)
  }
}

/// 이 곡이 올라간 릴레이 — 지금 순위와 변동
struct SongRelaySection: View {
  let relays: [SongDetail.Relay]
  let onRelay: (SongDetail.Relay.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      SongSectionHeader(title: "이 곡이 올라간 릴레이", subtitle: self.subtitle)
      VStack(spacing: 0) {
        ForEach(self.relays) { relay in
          Button { self.onRelay(relay.id) } label: { self.row(relay) }
            .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 20)
    }
  }

  private var subtitle: String? {
    let live = self.relays.filter(\.isLive).count
    return live > 0 ? "\(live)개 릴레이에서 투표를 받고 있어요" : nil
  }

  private func row(_ relay: SongDetail.Relay) -> some View {
    HStack(spacing: 12) {
      RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 52, height: 52)
      VStack(alignment: .leading, spacing: 4) {
        Text(relay.title)
          .wepliFont(.body)
          .foregroundStyle(WePLiColor.textPrimary)
          .lineLimit(1)
        HStack(spacing: 4) {
          if relay.isLive {
            Circle().fill(WePLiGradient.vsRing).frame(width: 6, height: 6)
            Text("진행 중").foregroundStyle(WePLiColor.accent).fontWeight(.semibold)
          } else {
            Text("완성").foregroundStyle(WePLiColor.textQuaternary).fontWeight(.semibold)
          }
          Text("·").foregroundStyle(WePLiColor.textDisabled)
          Text(relay.tags).foregroundStyle(WePLiColor.textTertiary)
            .font(.custom(WePLiFont.Weight.light.postScriptName, size: 12))
        }
        .wepliFont(.caption, weight: .semibold)
        .lineLimit(1)
      }
      Spacer(minLength: 8)
      VStack(alignment: .trailing, spacing: 0) {
        (Text("\(relay.rank)").font(.custom(WePLiFont.Weight.bold.postScriptName, size: 18))
          + Text("위").font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 12)))
          .foregroundStyle(WePLiColor.textPrimary)
        self.change(relay.change)
          .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 11))
      }
      .monospacedDigit()
    }
    .frame(height: 64)
    .contentShape(Rectangle())
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private func change(_ change: SongRelayChange) -> some View {
    switch change {
    case let .up(count): Text("▲\(count)").foregroundStyle(WePLiColor.positive)
    case let .down(count): Text("▼\(count)").foregroundStyle(WePLiColor.highlight)
    case .same: Text("–").foregroundStyle(WePLiColor.textDisabled)
    case .final: Text("최종").foregroundStyle(WePLiColor.textQuaternary)
    }
  }
}

/// 곡 정보 — 작사 · 작곡 · 장르(#해시태그) · 앨범, 구분선만 있는 한 목록
struct SongInfoList: View {
  let song: SongDetail
  let onAlbum: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      SongSectionHeader(title: "곡 정보")
      VStack(spacing: 0) {
        self.row("작사") { self.value(self.song.lyricist) }
        self.divider
        self.row("작곡") { self.value(self.song.composer) }
        self.divider
        self.row("장르") {
          Text(self.song.genres.map { "#\($0)" }.joined(separator: " "))
            .wepliFont(.body)
            .foregroundStyle(WePLiColor.accent)
        }
        self.divider
        Button(action: self.onAlbum) {
          self.row("앨범") {
            HStack(spacing: 10) {
              RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 36, height: 36)
              VStack(alignment: .leading, spacing: 1) {
                Text(self.song.album.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
                Text("\(self.song.album.type) · \(self.song.album.releaseDate)")
                  .wepliFont(.caption, weight: .light)
                  .foregroundStyle(WePLiColor.textTertiary)
              }
              Spacer(minLength: 0)
              Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(WePLiColor.textDisabled)
            }
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 20)
    }
  }

  private var divider: some View {
    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5)
  }

  private func value(_ text: String) -> some View {
    Text(text).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
  }

  private func row(_ title: String, @ViewBuilder content: () -> some View) -> some View {
    HStack(spacing: 16) {
      Text(title)
        .wepliFont(.subheadline, weight: .light)
        .foregroundStyle(WePLiColor.textTertiary)
        .frame(width: 52, alignment: .leading)
      content()
      Spacer(minLength: 0)
    }
    .frame(minHeight: 48)
    .accessibilityElement(children: .combine)
  }
}

/// 댓글 923 — 미리보기 두 개
struct SongCommentSection: View {
  let count: Int
  let comments: [SongDetail.Comment]
  let onComments: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      SongSectionHeader(title: "댓글 \(SongCount.string(self.count))", action: self.onComments)
      VStack(alignment: .leading, spacing: 18) {
        ForEach(self.comments) { comment in
          self.row(comment)
        }
      }
      .padding(.horizontal, 20)
    }
  }

  private func row(_ comment: SongDetail.Comment) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Circle().fill(WePLiColor.imagePlaceholder).frame(width: 32, height: 32).accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 4) {
        Text(comment.author).font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 13))
          .foregroundColor(WePLiColor.textPrimary)
          + Text(" · \(comment.time)").font(.custom(WePLiFont.Weight.light.postScriptName, size: 13))
          .foregroundColor(WePLiColor.textQuaternary)
        Text(comment.body)
          .wepliFont(.subheadline, weight: .light)
          .lineSpacing(3)
          .foregroundStyle(WePLiColor.textMuted)
        Text("좋아요 \(SongCount.string(comment.likeCount)) · 답글")
          .wepliFont(.caption)
          .foregroundStyle(WePLiColor.textQuaternary)
      }
    }
    .accessibilityElement(children: .combine)
  }
}

/// 함께 들으면 좋은 곡 · 이 가수의 다른 앨범
struct SongRelatedSections: View {
  let song: SongDetail
  let onSong: (SongDetail.RelatedSong.ID) -> Void
  let onPlay: (SongDetail.RelatedSong.ID) -> Void
  let onAlbum: (SongDetail.OtherAlbum.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 36) {
      VStack(alignment: .leading, spacing: 8) {
        SongSectionHeader(title: "함께 들으면 좋은 곡", subtitle: "이 곡과 같은 릴레이에 자주 오른 곡이에요")
        VStack(spacing: 0) {
          ForEach(self.song.related) { related in
            self.relatedRow(related)
          }
        }
        .padding(.horizontal, 20)
      }
      VStack(alignment: .leading, spacing: 14) {
        SongSectionHeader(title: "이 가수의 다른 앨범")
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(alignment: .top, spacing: 12) {
            ForEach(self.song.otherAlbums) { album in
              Button {
                self.onAlbum(album.id)
              } label: {
                VStack(alignment: .leading, spacing: 8) {
                  RoundedRectangle(cornerRadius: 8).fill(WePLiColor.imagePlaceholder).frame(width: 136, height: 136)
                  VStack(alignment: .leading, spacing: 2) {
                    Text(album.title).wepliFont(.footnote).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
                    Text(album.subtitle).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textTertiary)
                  }
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

  private func relatedRow(_ related: SongDetail.RelatedSong) -> some View {
    HStack(spacing: 12) {
      Button {
        self.onSong(related.id)
      } label: {
        HStack(spacing: 12) {
          RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 48, height: 48)
          VStack(alignment: .leading, spacing: 2) {
            Text(related.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
            Text(related.artist).wepliFont(.footnote, weight: .light).foregroundStyle(Color.white.opacity(0.7))
          }
          Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      Button {
        self.onPlay(related.id)
      } label: {
        Image(systemName: "play.fill")
          .font(.system(size: 13))
          .foregroundStyle(WePLiColor.textMuted)
          .frame(width: 36, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("\(related.title) 미리듣기")
      Button {
        self.onSong(related.id)
      } label: {
        Image(systemName: "ellipsis")
          .foregroundStyle(WePLiColor.tabInactiveGlass)
          .frame(width: 36, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("\(related.title) 더보기")
    }
    .frame(height: 60)
  }
}

/// 「10,123」
enum SongCount {
  static func string(_ count: Int) -> String {
    count.formatted(.number.locale(Locale(identifier: "en_US")))
  }
}
