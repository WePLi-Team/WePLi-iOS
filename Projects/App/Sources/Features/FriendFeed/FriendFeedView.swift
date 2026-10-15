import ComposableArchitecture
import SwiftUI

// REQ-079 · UI-13b — 커뮤니티 › 친구. 지금 듣는 중 줄 → 같은 곡 한 줄 → 친구 피드(반응) → 이번 주 친구들이 많이 들은 곡

struct FriendFeedView: View {
  let store: StoreOf<FriendFeedFeature>

  var body: some View {
    WithPerceptionTracking {
      Group {
        if let feed = self.store.feed {
          VStack(alignment: .leading, spacing: 0) {
            self.rail(feed.rail).padding(.top, 22)
            if let same = feed.sameSong {
              self.sameSong(same).padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 4)
            }
            VStack(spacing: 0) {
              ForEach(feed.feed) { row in
                FriendFeedRow(
                  row: row,
                  onPlay: { self.store.send(.playTapped(row.id)) },
                  onReact: { self.store.send(.reactionTapped(row.id, $0)) }
                )
              }
            }
            .padding(.top, 14)
            self.weekly(feed.weekly).padding(.horizontal, 20).padding(.top, 24)
          }
          .padding(.bottom, 40)
        } else if self.store.loadFailed {
          WePLiEmptyState(
            systemImage: "exclamationmark.triangle",
            // 원본에 오류 화면이 없어 빈 상태 형식을 따른 임시 문구 — 디자인 확인 필요
            title: "친구 소식을 불러오지 못했어요",
            message: "잠시 후 다시 시도해 주세요.",
            actionTitle: "다시 시도",
            action: { self.store.send(.retryButtonTapped) }
          )
          .padding(.vertical, 60)
        } else {
          ProgressView().tint(WePLiColor.textTertiary).frame(maxWidth: .infinity, minHeight: 240)
        }
      }
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private func rail(_ friends: [FriendListening]) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("지금 듣는 중").wepliFont(.headline).foregroundStyle(WePLiColor.textPrimary).padding(.horizontal, 20)
        .accessibilityAddTraits(.isHeader)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 14) {
          ForEach(friends) { friend in
            Button {
              self.store.send(.railTapped(friend.id))
            } label: {
              FriendRailItem(friend: friend)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 20)
      }
    }
  }

  private func sameSong(_ friend: FriendListening) -> some View {
    Button {
      self.store.send(.sameSongTapped)
    } label: {
      HStack(spacing: 8) {
        ListeningEqualizer()
        (Text(friend.name).fontWeight(.semibold) + Text("님과 지금 같은 곡을 듣는 중 · \(friend.title)"))
          .wepliFont(.footnote)
          .foregroundStyle(WePLiColor.accent)
          .lineLimit(1)
        Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).foregroundStyle(WePLiColor.accent)
      }
    }
    .buttonStyle(.plain)
    .accessibilityHint("\(friend.name)님에게 🎧 반응을 보내요")
  }

  private func weekly(_ songs: [FriendWeeklySong]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("이번 주 친구들이 많이 들은 곡").wepliFont(.headline).foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
        Button {
          self.store.send(.weeklyTapped(song.id))
        } label: {
          HStack(spacing: 12) {
            Text("\(index + 1)").wepliFont(.body, weight: .semibold).monospacedDigit().frame(width: 16)
            RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 2) {
              Text(song.title).wepliFont(.body).lineLimit(1)
              Text(song.artist).wepliFont(.footnote, weight: .light)
                .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
            }
            Spacer(minLength: 8)
            Text("친구 \(song.friendCount)명").wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
          }
          .foregroundStyle(WePLiColor.textPrimary)
          .frame(height: 60)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
  }
}
