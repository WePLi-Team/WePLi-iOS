import SwiftUI

// UI-13b — 지금 듣는 중 줄의 한 사람 · 친구 피드 한 줄

/// 재생 중이면 홀로그램 링, 멈췄으면 회색 링 + 흐리게. 아래에 듣는 곡 커버
struct FriendRailItem: View {
  let friend: FriendListening

  var body: some View {
    VStack(spacing: 7) {
      Circle().fill(WePLiColor.imagePlaceholder)
        .frame(width: 56, height: 56)
        .padding(2)
        .background(Circle().fill(Color.black))
        .padding(2)
        .background {
          if self.friend.isPlaying {
            Circle().fill(WePLiGradient.vsRing)
          } else {
            Circle().fill(Color.white.opacity(0.12))
          }
        }
        .overlay(alignment: .bottomTrailing) {
          RoundedRectangle(cornerRadius: 6).fill(WePLiColor.surface4).frame(width: 26, height: 26)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 2))
            .offset(x: 4, y: 2)
        }
      Text(self.friend.name).wepliFont(.caption).foregroundStyle(WePLiColor.textMuted).lineLimit(1)
    }
    .frame(width: 64)
    .opacity(self.friend.isPlaying ? 1 : 0.5)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      "\(self.friend.name), \(self.friend.isPlaying ? "지금 듣는 중" : "최근 들은 곡") \(self.friend.title)"
    )
  }
}

/// 친구 피드 한 줄 — 커버(친구 얼굴) · 「민수님이 지금 듣는 중 · 방금」 · 곡 · #가수 · ▶ · 반응 4개
struct FriendFeedRow: View {
  let row: FriendListening
  let onPlay: () -> Void
  let onReact: (FriendReaction) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 52, height: 52)
          .overlay(alignment: .bottomTrailing) {
            Circle().fill(WePLiColor.surface4).frame(width: 24, height: 24)
              .overlay(Circle().stroke(Color.black, lineWidth: 2))
              .offset(x: 6, y: 6)
          }
        VStack(alignment: .leading, spacing: 2) {
          Text(self.row.meta).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textTertiary)
          HStack(spacing: 6) {
            Text(self.row.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
            if self.row.isPlaying {
              ListeningEqualizer()
            }
          }
          Text("#\(self.row.artist)").wepliFont(.footnote, weight: .light).foregroundStyle(WePLiColor.accent)
        }
        .padding(.leading, 4)
        Spacer(minLength: 0)
        Button(action: self.onPlay) {
          Image(systemName: "play")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(WePLiColor.textMuted)
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(self.row.title) 음악 앱에서 열기")
      }
      .padding(.leading, 20)
      .padding(.trailing, 8)
      HStack(spacing: 2) {
        ForEach(FriendReaction.allCases, id: \.self) { reaction in
          self.reactionChip(reaction)
        }
      }
      .padding(.leading, 82)
    }
    .padding(.top, 10)
    .padding(.bottom, 6)
  }

  private func reactionChip(_ reaction: FriendReaction) -> some View {
    let isMine = self.row.myReaction == reaction
    let count = self.row.reactions[reaction] ?? 0
    return Button {
      self.onReact(reaction)
    } label: {
      HStack(spacing: 4) {
        Text(reaction.rawValue).font(.system(size: 14))
        if count > 0 {
          Text("\(count)")
            .wepliFont(.caption, weight: .semibold)
            .monospacedDigit()
            .foregroundStyle(isMine ? WePLiColor.accent : WePLiColor.textTertiary)
        }
      }
      .padding(.horizontal, 8)
      .frame(height: 30)
      .background(isMine ? WePLiColor.chipOn : .clear, in: Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(reaction.rawValue) \(count)")
    .accessibilityAddTraits(isMine ? [.isButton, .isSelected] : .isButton)
  }
}
