import SwiftUI

// UI-12a 「내 참여 · 사람」 섹션 — 내 추천곡(8a) · 투표 중 릴레이(9a) · 1위 예측(8d) · 친구(13) · 지금 듣는 중(13 집계)

/// 내 추천곡 · 지금 몇 위 — 줄 64, 오른쪽 순위 20 Bold + 「위」, 변동 ▲#A4FFFF · – #6B6B7C
struct HomeMyRecommendationsSection: View {
  let items: [HomeMyRecommendation]
  let isNewUser: Bool
  let onTap: (HomeMyRecommendation.ID) -> Void
  let onRecommendFirst: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HomeSectionHeader(
        title: "내 추천곡",
        subtitle: self.isNewUser ? "곡을 추천하면 순위가 여기 실시간으로 떠요" : "추천한 곡이 지금 몇 위인지 보여드려요"
      )
      if self.isNewUser {
        HomeNewUserPrompt(
          message: "지금 투표 중인 릴레이에 첫 곡을 추천해보세요.",
          button: "첫 곡 추천하기",
          action: self.onRecommendFirst
        )
      }
      VStack(spacing: 0) {
        ForEach(self.items) { item in
          Button {
            self.onTap(item.id)
          } label: {
            HStack(spacing: 12) {
              RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 48, height: 48)
              HomeSongText(title: item.title, artist: item.relayLine)
              VStack(alignment: .trailing, spacing: 1) {
                (Text("\(item.rank)").font(.custom(WePLiFont.Weight.bold.postScriptName, size: 20, relativeTo: .title3))
                  + Text("위").font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 13, relativeTo: .footnote)))
                  .monospacedDigit()
                  .foregroundStyle(WePLiColor.textPrimary)
                Text(item.change.text)
                  .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 11, relativeTo: .caption2))
                  .foregroundStyle(self.changeColor(item.change))
              }
            }
            .padding(.horizontal, 20)
            .frame(height: 64)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  private func changeColor(_ change: RankChange) -> Color {
    if case .up = change {
      return WePLiColor.positive
    }
    return WePLiColor.textDisabled
  }
}

/// 지금 투표 중인 릴레이 — 커버 68(모서리 12) · 제목 16 · 태그 · 「● 5시간 12분 남음 · 1,284명」
struct HomeVotingRelaysSection: View {
  let relays: [HomeVotingRelay]
  let now: Date
  let onTap: (HomeVotingRelay.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HomeSectionHeader(title: "지금 투표 중인 릴레이", subtitle: "마감이 가까운 순서예요")
      ForEach(self.relays) { relay in
        Button {
          self.onTap(relay.id)
        } label: {
          HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12).fill(WePLiColor.imagePlaceholder).frame(width: 68, height: 68)
            VStack(alignment: .leading, spacing: 4) {
              Text(relay.title)
                .wepliFont(.callout, weight: .semibold)
                .foregroundStyle(WePLiColor.textPrimary)
              Text(relay.tags)
                .wepliFont(.caption)
                .foregroundStyle(WePLiColor.textTertiary)
              HStack(spacing: 6) {
                Circle().fill(WePLiColor.accent).frame(width: 6, height: 6)
                Text(
                  "\(HomeText.shortRemaining(from: self.now, to: relay.endsAt)) 남음 · \(HomeText.count(relay.participantCount))명"
                )
              }
              .wepliFont(.caption)
              .monospacedDigit()
              .foregroundStyle(WePLiColor.accent)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
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

/// 1위 예측 — 한 번만 고름. 고르면 비율 · 막대가 나온다(막대는 0.5초, 줄마다 0.06초 늦게)
struct HomePredictionSection: View {
  let prediction: HomePrediction
  let onPick: (HomePrediction.Option.ID) -> Void

  @Environment(\.accessibilityReduceMotion)
  private var reduceMotion

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HomeSectionHeader(title: "1위 예측", subtitle: self.prediction.subtitle)
      Text(self.prediction.question)
        .wepliFont(.body, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
        .padding(EdgeInsets(top: 8, leading: 20, bottom: 2, trailing: 20))
      VStack(spacing: 0) {
        ForEach(Array(self.prediction.options.enumerated()), id: \.element.id) { index, option in
          self.row(option, index: index)
        }
      }
    }
  }

  private func row(_ option: HomePrediction.Option, index: Int) -> some View {
    let isPicked = self.prediction.pickedID != nil
    let isSelected = self.prediction.pickedID == option.id
    return Button {
      self.onPick(option.id)
    } label: {
      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 44, height: 44)
        VStack(alignment: .leading, spacing: 7) {
          HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(option.title)
              .wepliFont(.body)
              .foregroundStyle(isSelected ? WePLiColor.accent : WePLiColor.textPrimary)
              .lineLimit(1)
            Spacer(minLength: 0)
            Text("\(option.percent)%")
              .wepliFont(.caption, weight: .light)
              .monospacedDigit()
              .foregroundStyle(WePLiColor.textTertiary)
              .opacity(isPicked ? 1 : 0)
          }
          GeometryReader { proxy in
            ZStack(alignment: .leading) {
              Capsule().fill(Color.white.opacity(0.08))
              Capsule()
                .fill(isSelected ? WePLiColor.accent : Color.white.opacity(0.28))
                .frame(width: isPicked ? proxy.size.width * CGFloat(option.percent) / 100 : 0)
            }
          }
          .frame(height: 3)
          .opacity(isPicked ? 1 : 0)
          .animation(
            self.reduceMotion ? .easeOut(duration: 0.3)
              : .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.5).delay(Double(index) * 0.06),
            value: option.percent
          )
        }
        self.indicator(isSelected: isSelected)
      }
      .padding(.horizontal, 20)
      .frame(height: 60)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(isPicked)
    .animation(.easeOut(duration: 0.3), value: isPicked)
    .accessibilityLabel(isPicked ? "\(option.title), \(option.percent)%" : option.title)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  private func indicator(isSelected: Bool) -> some View {
    ZStack {
      if isSelected {
        Circle().fill(WePLiColor.accent)
        Image(systemName: "checkmark")
          .font(.system(size: 10, weight: .heavy))
          .foregroundStyle(WePLiColor.textOnCTA)
      } else {
        Circle().strokeBorder(Color.white.opacity(0.22), lineWidth: 1.5)
      }
    }
    .frame(width: 22, height: 22)
  }
}

/// 친구가 지금 듣는 중 — 가로, 칸 72 · 아바타 68(듣는 중이면 홀로그램 링) · 커버 배지 26
struct HomeFriendsSection: View {
  let friends: [HomeFriendListening]
  let isNewUser: Bool
  let onTap: (HomeFriendListening.ID) -> Void
  let onFindFriends: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HomeSectionHeader(
        title: "친구가 지금 듣는 중",
        subtitle: self.isNewUser
          ? "팔로우한 친구가 듣는 곡이 여기 보여요"
          : "친구 \(self.friends.filter(\.isLive).count)명이 지금 듣고 있어요"
      )
      if self.isNewUser {
        HomeNewUserPrompt(
          message: "친구를 팔로우하면 지금 듣는 곡을 바로 볼 수 있어요.",
          button: "친구 찾기",
          action: self.onFindFriends
        )
      } else {
        self.list
      }
    }
  }

  private var list: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(alignment: .top, spacing: 14) {
        ForEach(self.friends) { friend in
          Button {
            self.onTap(friend.id)
          } label: {
            self.item(friend)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 20)
    }
  }

  private func item(_ friend: HomeFriendListening) -> some View {
    VStack(spacing: 8) {
      ZStack {
        Circle().fill(WePLiGradient.vsRing).opacity(friend.isLive ? 1 : 0)
        Circle()
          .fill(WePLiColor.imagePlaceholder)
          .frame(width: 62, height: 62)
          .overlay(Circle().strokeBorder(WePLiColor.background, lineWidth: 2))
          .opacity(friend.isLive ? 1 : 0.55)
      }
      .frame(width: 68, height: 68)
      .overlay(alignment: .bottomTrailing) {
        RoundedRectangle(cornerRadius: 4)
          .fill(WePLiColor.surface2)
          .frame(width: 26, height: 26)
          .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
          .offset(x: 2, y: 2)
      }
      VStack(spacing: 1) {
        Text(friend.name)
          .wepliFont(.caption, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
        Text(friend.line)
          .font(.custom(WePLiFont.Weight.light.postScriptName, size: 11, relativeTo: .caption2))
          .foregroundStyle(friend.isLive ? WePLiColor.textTertiary : WePLiColor.textDisabled)
      }
      .lineLimit(1)
      .frame(width: 72)
    }
    .frame(width: 72)
    .accessibilityElement(children: .combine)
  }
}

/// 지금 위플리에서 듣는 중 — 「● 1,284명이 듣고 있어요 · 실시간」, 곡마다 「N명」
struct HomeLiveListeningSection: View {
  let live: HomeLiveListening
  let onTap: (HomeLiveListening.Song.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      VStack(alignment: .leading, spacing: 4) {
        HomeSectionHeader(title: "지금 위플리에서 듣는 중")
        HStack(spacing: 6) {
          Circle().fill(WePLiGradient.vsRing).frame(width: 6, height: 6)
          Text("\(HomeText.count(self.live.total))명이 듣고 있어요 · 실시간")
            .wepliFont(.caption, weight: .light)
            .monospacedDigit()
            .foregroundStyle(WePLiColor.textTertiary)
            .contentTransition(.numericText())
        }
        .padding(.horizontal, 20)
      }
      VStack(spacing: 0) {
        ForEach(self.live.songs) { song in
          Button {
            self.onTap(song.id)
          } label: {
            HStack(spacing: 12) {
              RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 48, height: 48)
              HomeSongText(title: song.title, artist: song.artist)
              Text("\(song.listeners)명")
                .wepliFont(.footnote, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(WePLiColor.accent)
                .contentTransition(.numericText())
            }
            .padding(.horizontal, 20)
            .frame(height: 60)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
      }
    }
    .animation(.easeInOut(duration: 0.24), value: self.live)
  }
}
