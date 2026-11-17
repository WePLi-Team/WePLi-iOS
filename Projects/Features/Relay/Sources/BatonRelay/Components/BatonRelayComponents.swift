import SwiftUI
import WePLiDesignSystem

// UI-8c — 달리는 사람 줄 · 이어진 곡 · 내 차례

/// 8명 — 이은 사람은 시안 테두리, 지금 달리는 사람은 라벤더 테두리(조금 크게), 기다리는 사람은 흐리게
public struct BatonRunnerRow: View {
  public let relay: BatonRelay

  public var body: some View {
    HStack(spacing: 6) {
      ForEach(self.relay.runners) { runner in
        switch runner.state {
        case .done:
          WePLiArtwork(size: 32, style: .circle)
            .overlay(Circle().stroke(WePLiColor.positive, lineWidth: 2))
        case .now:
          WePLiArtwork(size: 32, style: .circle)
            .padding(2)
            .background(Circle().fill(WePLiColor.accent))
        case .waiting:
          WePLiArtwork(size: 32, style: .circle).opacity(0.3)
        }
      }
      Spacer(minLength: 0)
      Text("\(self.relay.count) / \(self.relay.total)").wepliFont(.footnote).monospacedDigit()
        .foregroundStyle(WePLiColor.textTertiary)
    }
    .accessibilityElement()
    .accessibilityLabel("\(self.relay.total)명 중 \(self.relay.count)명이 이었어요")
  }

  public init(relay: BatonRelay) {
    self.relay = relay
  }
}

/// 이어진 곡 한 칸 — 점 · 세로선 · 사람 · 곡 · 넘긴 키워드
public struct BatonLinkRow: View {
  public let link: BatonRelay.Link

  public var body: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(spacing: 0) {
        Circle().fill(WePLiColor.accentStrong).frame(width: 10, height: 10).padding(.top, 18)
        Rectangle().fill(WePLiColor.accentStrong.opacity(0.3)).frame(width: 2)
      }
      .frame(width: 20)
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
          WePLiArtwork(size: 22, style: .circle)
          Text(self.link.runner).wepliFont(.footnote, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
          Text(self.link.keywordFrom).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
        }
        HStack(spacing: 12) {
          WePLiArtwork(size: 48, style: .rounded(4))
          VStack(alignment: .leading, spacing: 2) {
            Text(self.link.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
            Text(self.link.artist).wepliFont(.footnote, weight: .light)
              .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
          }
          Spacer(minLength: 8)
          Text(self.link.keyword).wepliFont(.footnote, weight: .semibold).foregroundStyle(WePLiColor.accent)
        }
      }
      .padding(.top, 8)
      .padding(.bottom, 14)
    }
    .accessibilityElement(children: .combine)
  }

  public init(link: BatonRelay.Link) {
    self.link = link
  }
}

/// 내 차례 — 남은 시간 · 이어받은 키워드 · 곡 3개 · 다음 키워드 칩
public struct BatonMyTurn: View {
  public let relay: BatonRelay
  public let remaining: String
  public let pickID: BatonRelay.Pick.ID?
  public let keyword: String?
  public let onPick: (BatonRelay.Pick.ID) -> Void
  public let onKeyword: (String) -> Void

  public var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Circle().fill(WePLiGradient.vsRing).frame(width: 14, height: 14)
        .shadow(color: WePLiColor.positive.opacity(0.14), radius: 4)
        .padding(.top, 18)
        .frame(width: 20)
      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .firstTextBaseline) {
          Text("내 차례예요!").wepliFont(.body, weight: .bold).foregroundStyle(WePLiColor.accent)
          Spacer()
          Text("\(self.remaining) 남음").wepliFont(.footnote).monospacedDigit().foregroundStyle(WePLiColor.textTertiary)
        }
        (Text("이어받은 키워드 ") + Text(self.relay.keyword).bold().foregroundColor(WePLiColor.accent) + Text(" 에 어울리는 곡"))
          .wepliFont(.footnote)
          .foregroundStyle(WePLiColor.textSecondary)
        VStack(spacing: 0) {
          ForEach(self.relay.picks) { pick in
            self.pickRow(pick)
          }
        }
        Text("다음 사람에게 넘길 키워드").wepliFont(.footnote).foregroundStyle(WePLiColor.textSecondary)
        HStack(spacing: 6) {
          ForEach(self.relay.nextKeywords, id: \.self) { keyword in
            WePLiChip(title: keyword, isOn: self.keyword == keyword) { self.onKeyword(keyword) }
          }
        }
      }
      .padding(.vertical, 8)
    }
  }

  private func pickRow(_ pick: BatonRelay.Pick) -> some View {
    let isSelected = self.pickID == pick.id
    return Button {
      self.onPick(pick.id)
    } label: {
      HStack(spacing: 12) {
        WePLiArtwork(size: 44, style: .rounded(4))
        VStack(alignment: .leading, spacing: 2) {
          Text(pick.title).wepliFont(.body).foregroundStyle(isSelected ? WePLiColor.accent : WePLiColor.textPrimary)
            .lineLimit(1)
          Text(pick.artist).wepliFont(.footnote, weight: .light).foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
        }
        Spacer(minLength: 8)
        WePLiSelectionCheck(isOn: isSelected)
      }
      .frame(height: 56)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
  }

  public init(
    relay: BatonRelay,
    remaining: String,
    pickID: BatonRelay.Pick.ID?,
    keyword: String?,
    onPick: @escaping (BatonRelay.Pick.ID) -> Void,
    onKeyword: @escaping (String) -> Void
  ) {
    self.relay = relay
    self.remaining = remaining
    self.pickID = pickID
    self.keyword = keyword
    self.onPick = onPick
    self.onKeyword = onKeyword
  }
}
