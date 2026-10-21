import SwiftUI

// UI-8f 호스트 탭 — 릴레이를 자주 · 잘 여는 사람. HOST 칩 · 통계 · 팔로우 · 커버 3장 · 최근 연 릴레이

struct SeasonHostList: View {
  let hosts: [SeasonHost]
  let onFollow: (SeasonHost.ID) -> Void

  var body: some View {
    VStack(spacing: 20) {
      ForEach(self.hosts) { host in
        SeasonHostCard(host: host) { self.onFollow(host.id) }
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 18)
  }
}

private struct SeasonHostCard: View {
  let host: SeasonHost
  let onFollow: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        Circle().fill(WePLiColor.imagePlaceholder).frame(width: 48, height: 48).accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 2) {
          HStack(spacing: 6) {
            Text(self.host.name).wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
            Text("HOST")
              .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 10, relativeTo: .caption2))
              .foregroundStyle(WePLiColor.accent)
              .padding(.horizontal, 6)
              .frame(height: 18)
              .background(WePLiColor.chipOn, in: RoundedRectangle(cornerRadius: 4))
          }
          Text(self.host.stats).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
        }
        Spacer(minLength: 8)
        self.followButton
      }
      HStack(spacing: 8) {
        ForEach(0 ..< 3, id: \.self) { _ in
          RoundedRectangle(cornerRadius: 8).fill(WePLiColor.imagePlaceholder).frame(height: 96)
        }
      }
      .accessibilityHidden(true)
      Text("최근 연 릴레이 · \(self.host.recentRelay)").wepliFont(.footnote).foregroundStyle(WePLiColor.textSecondary)
    }
    .padding(EdgeInsets(top: 4, leading: 4, bottom: 20, trailing: 4))
    .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5) }
  }

  private var followButton: some View {
    Button(action: self.onFollow) {
      Text(self.host.isFollowing ? "팔로잉" : "팔로우")
        .wepliFont(.footnote, weight: .semibold)
        .foregroundStyle(self.host.isFollowing ? WePLiColor.textPrimary : WePLiColor.accent)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(self.host.isFollowing ? WePLiColor.disabledFill : WePLiColor.chipOn, in: Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(self.host.name) \(self.host.isFollowing ? "팔로잉" : "팔로우")")
  }
}
