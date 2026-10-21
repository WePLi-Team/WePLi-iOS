import ComposableArchitecture
import SwiftUI

// UI-13g — 지금 듣는 중 한 줄 · 메뉴(재생 · 내 플리에 담기), 행동 줄(릴레이에 초대하기 · 명함 · 공유)

/// 듣는 중 막대 + 「밤편지 · 아이유」 + 꺾쇠 — 누르면 메뉴
struct FriendNowPlayingLine: View {
  let song: FriendNowPlaying
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      HStack(spacing: 6) {
        ListeningEqualizer()
        (Text(self.song.title) + Text(" · \(self.song.artist)").font(WePLiFont.font(.footnote, weight: .light)))
          .wepliFont(.footnote)
          .lineLimit(1)
        Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold))
      }
      .foregroundStyle(WePLiColor.accent)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("지금 듣는 중, \(self.song.title), \(self.song.artist)")
  }
}

/// 지금 듣는 중 메뉴 — 커버 · 곡 · 재생 · 내 플리에 담기(폭 290, 글래스)
struct FriendNowPlayingMenu: View {
  let store: StoreOf<FriendProfileFeature>
  let song: FriendNowPlaying

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 52, height: 52)
        VStack(alignment: .leading, spacing: 2) {
          HStack(spacing: 6) {
            ListeningEqualizer()
            Text("지금 듣는 중 · \(self.song.timeText)").font(WePLiFont.font(.caption, weight: .semibold))
              .foregroundStyle(WePLiColor.accent)
          }
          Text(self.song.title).wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
          Text("#\(self.song.artist)").wepliFont(.footnote, weight: .light).foregroundStyle(WePLiColor.accent)
        }
        Spacer(minLength: 0)
      }
      .padding(EdgeInsets(top: 14, leading: 14, bottom: 12, trailing: 14))
      self.row("재생", systemName: "play.fill", isOn: false) { self.store.send(.playNowPlayingTapped) }
      self.row(
        self.store.isSongSaved ? "내 플리에 담았어요" : "내 플리에 담기",
        systemName: "text.badge.plus",
        isOn: self.store.isSongSaved
      ) { self.store.send(.saveSongTapped) }
    }
    .frame(width: 290)
    .wepliGlass(in: RoundedRectangle(cornerRadius: 22))
    .shadow(color: .black.opacity(0.6), radius: 25, y: 20)
  }

  private func row(_ title: String, systemName: String, isOn: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack {
        Text(title).wepliFont(.callout)
        Spacer()
        Image(systemName: systemName).font(.system(size: 16, weight: .medium))
      }
      .foregroundStyle(isOn ? WePLiColor.accent : WePLiColor.textPrimary)
      .padding(.horizontal, 16)
      .frame(height: 48)
      .contentShape(Rectangle())
      .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.1)).frame(height: 0.5) }
    }
    .buttonStyle(.plain)
  }
}

/// 릴레이에 초대하기(그라디언트 ↔ 보낸 뒤 상태 알약) · 명함 · 공유
struct FriendProfileActions: View {
  let store: StoreOf<FriendProfileFeature>
  let profile: FriendProfile

  var body: some View {
    HStack(spacing: 10) {
      if let relay = self.profile.inviteRelay {
        self.invite(relay)
      }
      FriendCardThumb()
      if let url = FriendProfileText.link(self.profile) {
        ShareLink(item: url) {
          Image(systemName: "square.and.arrow.up")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(WePLiColor.textPrimary)
            .frame(width: 56, height: 56)
            .background(WePLiColor.secondaryButtonFill, in: Circle())
        }
        .accessibilityLabel("프로필 공유하기")
      }
    }
  }

  private func invite(_ relay: FriendInviteRelay) -> some View {
    let isSent = self.store.isInviteSent
    return Button {
      self.store.send(.inviteTapped)
    } label: {
      HStack(spacing: 10) {
        Image(systemName: "music.note.list").font(.system(size: 18, weight: .semibold))
        VStack(alignment: .leading, spacing: 0) {
          Text(isSent ? "초대를 보냈어요" : "릴레이에 초대하기").wepliFont(.body, weight: .bold)
          Text(isSent ? "\(relay.title) · \(relay.order)번째 주자" : "\(self.profile.name)님과 같이 플리 만들기")
            .font(WePLiFont.font(.caption, weight: .medium))
            .foregroundStyle(isSent ? WePLiColor.textTertiary : WePLiColor.textOnCTA.opacity(0.65))
            .lineLimit(1)
        }
        Spacer(minLength: 0)
      }
      .foregroundStyle(isSent ? WePLiColor.accent : WePLiColor.textOnCTA)
      .padding(.horizontal, 18)
      .frame(maxWidth: .infinity)
      .frame(height: 56)
      .background {
        if isSent {
          Capsule().fill(WePLiGradient.brand.opacity(0.08)).wepliGlass(in: Capsule())
        } else {
          Capsule().fill(WePLiGradient.cta)
        }
      }
    }
    .buttonStyle(.plain)
    .disabled(isSent)
    .animation(.easeOut(duration: 0.2), value: isSent)
  }
}

/// 명함 축소 — 기울어진 카드 38×54 + 「명함」
private struct FriendCardThumb: View {
  var body: some View {
    VStack(spacing: 4) {
      RoundedRectangle(cornerRadius: 5)
        .fill(WePLiColor.cardFace)
        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(WePLiColor.cardLine, lineWidth: 1))
        .frame(width: 38, height: 54)
        .rotationEffect(.degrees(-9))
        .shadow(color: .black.opacity(0.5), radius: 8, y: 6)
      Text("명함").font(WePLiFont.font(.caption, weight: .semibold)).foregroundStyle(WePLiColor.textSecondary)
    }
    .frame(width: 56, height: 56)
    .accessibilityElement(children: .combine)
  }
}
