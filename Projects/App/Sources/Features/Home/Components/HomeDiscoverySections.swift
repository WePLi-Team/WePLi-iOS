import SwiftUI

// UI-12a 「발견 · 내 취향」 섹션 — 오늘의 플리 · 시간대 추천 · 내 최애 가수 · Fa♥orite · 커뮤니티 인기글 · 인기 랭킹 · 추천 플리 · 테마별 플리 · Youtube Cover

/// 새 사용자 안내 — 한 줄(14 Light #B5B5C0) + 36 알약 버튼
struct HomeNewUserPrompt: View {
  var message: String?
  let button: String
  let action: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if let message = self.message {
        Text(message)
          .wepliFont(.subheadline, weight: .light)
          .foregroundStyle(WePLiColor.textSecondary)
      }
      Button(action: self.action) {
        Text(self.button)
          .wepliFont(.subheadline, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
          .padding(.horizontal, 16)
          .frame(height: 36)
          .background(WePLiColor.secondaryButtonFill, in: Capsule())
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 20)
    .padding(.top, 4)
  }
}

/// 오늘의 플리 — 300×140 카드(흐린 배경 + 검정 55%) · 아트 92 · 「#가수」 · 제목 3줄
struct HomeTodayPicksSection: View {
  let picks: [HomeTodayPick]
  /// 머리 → 오늘의 한 곡(UI-6c · DEC-012)
  let onOpen: () -> Void
  let onTap: (HomeTodayPick.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HomeSectionHeader(title: "오늘의 플리", subtitle: "매일 아침 위플리가 고른 곡이에요", onTap: self.onOpen)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(self.picks) { pick in
            Button {
              self.onTap(pick.id)
            } label: {
              HStack(alignment: .top, spacing: 20) {
                RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 92, height: 92)
                VStack(alignment: .leading, spacing: 6) {
                  Text(pick.artistTag)
                    .wepliFont(.footnote)
                    .foregroundStyle(WePLiColor.accent)
                    .lineLimit(1)
                  Text(pick.title)
                    .wepliFont(.callout, weight: .semibold)
                    .foregroundStyle(WePLiColor.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                }
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
              }
              .padding(.leading, 20)
              .padding(.trailing, 18)
              .padding(.top, 24)
              .frame(width: 300, height: 140, alignment: .topLeading)
              // 미결정 — 원본은 앨범 아트를 흐리게(30) 깔고 검정 55%를 덮는다. 아트가 붙으면 바꾼다
              .background(WePLiColor.surface1)
              .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 20)
      }
    }
  }
}

/// 시간대 추천 — 제목은 지금 시각에 따라, 300 폭 칸에 3곡씩 가로로
struct HomeTimeOfDaySection: View {
  let columns: [[HomeChartSong]]
  let hour: Int
  let onTap: (HomeChartSong.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HomeSectionHeader(title: HomeTimeOfDay(hour: self.hour).title, subtitle: HomeTimeOfDay.subtitle(hour: self.hour))
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 16) {
          ForEach(Array(self.columns.enumerated()), id: \.offset) { _, column in
            VStack(spacing: 0) {
              ForEach(column) { song in
                Button {
                  self.onTap(song.id)
                } label: {
                  HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 44, height: 44)
                    HomeSongText(title: song.title, artist: song.artist)
                    Image(systemName: "play")
                      .font(.system(size: 12))
                      .foregroundStyle(WePLiColor.textMuted)
                      .frame(width: 40, height: 44)
                  }
                  .frame(height: 58)
                  .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
              }
            }
            .frame(width: 300)
          }
        }
        .padding(.horizontal, 20)
      }
    }
  }
}

/// 내 최애 가수 — 꺾쇠 없음, 카드 150(모서리 18) · 사진 114 · 「#1번째 최애 가수」 · 이름 22 · PLAY
struct HomeFavoriteArtistSection: View {
  let artist: HomeFavoriteArtist?
  let isPlaying: Bool
  let onTap: () -> Void
  let onPlay: () -> Void
  let onPick: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HomeSectionHeader(title: "내 최애 가수", subtitle: "가장 많이 담고 추천한 가수예요", showsChevron: false)
      if let artist = self.artist {
        HStack(spacing: 16) {
          RoundedRectangle(cornerRadius: 8).fill(WePLiColor.imagePlaceholder).frame(width: 114, height: 114)
          VStack(alignment: .leading, spacing: 4) {
            Text("#\(artist.rank)번째 최애 가수")
              .wepliFont(.footnote)
              .foregroundStyle(WePLiColor.accent)
            Text(artist.name)
              .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 22, relativeTo: .title2))
              .foregroundStyle(WePLiColor.textPrimary)
            // 원본은 흰 바탕 + 검은 글자지만 디자인 원칙(DEC-009)에 따라 CTA 그라디언트
            Button(action: self.onPlay) {
              HStack(spacing: 6) {
                Image(systemName: self.isPlaying ? "pause.fill" : "play.fill").font(.system(size: 11))
                Text("PLAY")
                  .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 13, relativeTo: .footnote))
                  .tracking(0.5)
              }
              .foregroundStyle(WePLiColor.textOnCTA)
              .padding(.leading, 10)
              .padding(.trailing, 14)
              .frame(height: 34)
              .background(Capsule().fill(WePLiGradient.cta))
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            .accessibilityLabel(self.isPlaying ? "일시정지" : "\(artist.name) 재생")
          }
          Spacer(minLength: 0)
        }
        .padding(18)
        .frame(height: 150)
        .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 18))
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture(perform: self.onTap)
        .padding(.horizontal, 20)
      } else {
        HomeNewUserPrompt(
          message: "곡을 듣고 추천하다 보면 가장 많이 담은 가수가 여기 떠요.",
          button: "좋아하는 가수 고르기",
          action: self.onPick
        )
      }
    }
  }
}

/// Fa♥orite · 내가 좋아요한 곡 — 「Fa」「♥」(#FE82DB)「orite」 700 · 전체듣기 · 줄 60
struct HomeFavoritesSection: View {
  let favorites: HomeFavorites
  let isNewUser: Bool
  let onSong: (HomeChartSong.ID) -> Void
  let onPlayAll: () -> Void
  let onListenTop100: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .bottom) {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 2) {
            (Text("Fa") + Text("♥").foregroundColor(WePLiColor.highlight) + Text("orite"))
              .wepliFont(.headline, weight: .bold)
              .foregroundStyle(WePLiColor.textPrimary)
            Image(systemName: "chevron.right")
              .font(.system(size: 13, weight: .semibold))
              .foregroundStyle(WePLiColor.textMuted)
              .frame(width: 18, height: 18)
          }
          .accessibilityLabel("Favorite")
          .accessibilityAddTraits(.isHeader)
          Text(self.isNewUser ? "곡에 하트를 누르면 여기 모여요" : "내가 하트를 누른 곡 \(self.favorites.totalCount)곡 · 최근 순")
            .wepliFont(.caption, weight: .light)
            .foregroundStyle(WePLiColor.textTertiary)
        }
        Spacer(minLength: 0)
        if !self.isNewUser {
          HomePlayAllButton(action: self.onPlayAll)
        }
      }
      .padding(.horizontal, 20)
      if self.isNewUser {
        HomeNewUserPrompt(button: "위플리 TOP 100 듣기", action: self.onListenTop100)
      } else {
        VStack(spacing: 0) {
          ForEach(self.favorites.songs) { song in
            Button {
              self.onSong(song.id)
            } label: {
              HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 48, height: 48)
                HomeSongText(title: song.title, artist: song.artist)
                Image(systemName: "play")
                  .font(.system(size: 12))
                  .foregroundStyle(WePLiColor.textMuted)
                  .frame(width: 40, height: 44)
              }
              .padding(.leading, 20)
              .padding(.trailing, 8)
              .frame(height: 60)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }
}
