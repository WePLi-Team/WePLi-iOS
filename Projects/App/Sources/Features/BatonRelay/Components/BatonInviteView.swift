import ComposableArchitecture
import SwiftUI

// REQ-035 · UI-11c — 바통 초대 링크로 들어왔을 때. 누가 넘겼는지 · 앞사람 곡 · 이어받을 키워드 · 제한 시간을 먼저 보여주고
// 「바통 받기」를 눌러야 24시간 타이머가 시작된다. 부담스러우면 바로 넘길 수 있다.

struct BatonInviteView: View {
  let store: StoreOf<BatonRelayFeature>
  let relay: BatonRelay

  var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        // 미결정 — 원본은 앞사람 곡 커버를 흐려 깐다. 커버가 없어 어두운 바탕만 둔다
        LinearGradient(colors: [WePLiColor.surface2, WePLiColor.background], startPoint: .top, endPoint: .center)
          .ignoresSafeArea()
        VStack(alignment: .leading, spacing: 0) {
          HStack {
            WePLiIconButton(systemName: "xmark", accessibilityLabel: "닫기") { self.store.send(.closeTapped) }
            Spacer()
          }
          .padding(.horizontal, 16)
          .frame(height: 48)
          self.content.padding(.horizontal, 24).padding(.top, 14)
          Spacer(minLength: 0)
          self.bottomContent().padding(.horizontal, 20).padding(.bottom, 24)
        }
      }
    }
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: 18) {
      if case let .invited(passer) = self.relay.turn {
        self.passerRow(passer)
      } else if let last = self.relay.chain.last {
        self.passerRow(last.runner)
      }
      Text(self.relay.title)
        .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 28, relativeTo: .title))
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      HStack(spacing: 8) {
        ForEach(self.relay.chain) { _ in
          RoundedRectangle(cornerRadius: 8).fill(WePLiColor.imagePlaceholder).frame(width: 46, height: 46)
        }
        RoundedRectangle(cornerRadius: 8)
          .strokeBorder(WePLiColor.accent.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
          .frame(width: 46, height: 46)
          .overlay {
            Text("\(self.relay.myPosition)").wepliFont(.footnote, weight: .bold).foregroundStyle(WePLiColor.accent)
          }
      }
      .accessibilityElement()
      .accessibilityLabel("앞사람 \(self.relay.count)곡, 내 자리 \(self.relay.myPosition)번째")
      VStack(spacing: 10) {
        self.infoRow("이어받을 키워드", value: self.relay.keyword, isAccent: true)
        self.infoRow("내 순서", value: "\(self.relay.total)명 중 \(self.relay.myPosition)번째")
        self.infoRow("제한 시간", value: "받은 뒤 24시간")
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .background(WePLiColor.surface1.opacity(0.8), in: RoundedRectangle(cornerRadius: 18))
    }
  }

  private func passerRow(_ passer: String) -> some View {
    HStack(spacing: 10) {
      Circle().fill(WePLiColor.imagePlaceholder).frame(width: 44, height: 44)
      (Text(passer).font(WePLiFont.font(.body, weight: .bold))
        .foregroundColor(WePLiColor.textPrimary) + Text("님이\n바통을 넘겼어요"))
        .wepliFont(.body)
        .foregroundStyle(WePLiColor.textMuted)
    }
  }

  private func infoRow(_ label: String, value: String, isAccent: Bool = false) -> some View {
    HStack {
      Text(label).foregroundStyle(WePLiColor.textQuaternary)
      Spacer()
      Text(value)
        .fontWeight(isAccent ? .bold : .regular)
        .foregroundStyle(isAccent ? WePLiColor.accent : WePLiColor.textPrimary)
    }
    .wepliFont(.subheadline)
  }

  @ViewBuilder
  private func bottomContent() -> some View {
    switch self.relay.turn {
    case .invited:
      VStack(spacing: 4) {
        WePLiPrimaryButton(title: "바통 받기", isEnabled: !self.store.isSending) { self.store.send(.acceptTapped) }
        Button("이번엔 다음 사람에게 넘길게요") { self.store.send(.skipTapped) }
          .wepliFont(.body)
          .foregroundStyle(WePLiColor.textTertiary)
          .frame(maxWidth: .infinity)
          .frame(height: 44)
          .disabled(self.store.isSending)
      }
    case let .mine(endsAt):
      VStack(spacing: 10) {
        HStack {
          Text("내 차례 시작!").wepliFont(.body, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
          Spacer()
          Text(BatonText.clock(from: self.store.now, to: endsAt))
            .wepliFont(.title3, weight: .bold)
            .monospacedDigit()
            .foregroundStyle(WePLiColor.accent)
        }
        .padding(16)
        .background(WePLiColor.accentStrong.opacity(0.14), in: RoundedRectangle(cornerRadius: 20))
        // 원본의 흰 버튼은 DEC-009(흰 바탕 버튼 금지)에 따라 그라디언트로, 문구의 「(8c)」는 뺀다
        WePLiPrimaryButton(title: "곡 고르러 가기") { self.store.send(.goPickTapped) }
      }
    default:
      VStack(spacing: 2) {
        Text("\(self.relay.nextRunner)님에게 바로 넘겼어요.").wepliFont(.body).foregroundStyle(WePLiColor.textMuted)
        Text("완성되면 플리를 보내드릴게요").wepliFont(.footnote).foregroundStyle(WePLiColor.textQuaternary)
      }
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity)
      .padding(16)
      .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 20))
    }
  }
}
