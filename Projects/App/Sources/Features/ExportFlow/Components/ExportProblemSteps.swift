import ComposableArchitecture
import MusicKit
import SwiftUI

// UI-14f 구독이 없을 때 · 14n 문제가 생겼을 때 — 이미 담긴 곡이 남아 있다는 것과 다음에 할 일을 먼저 말한다

struct ExportSubscriptionStep: View {
  @Perception.Bindable var store: StoreOf<ExportFlowFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 14) {
        Spacer(minLength: 0)
        ExportServiceIcon(service: .appleMusic, size: 64)
        Text("Apple Music 구독이 필요해요")
          .wepliFont(.title3)
          .foregroundStyle(WePLiColor.textPrimary)
          .padding(.top, 4)
        Text("보관함에 플레이리스트를 만들려면 구독이 있어야 해요. 위플리 안에서는 구독 없이도 미리듣기로 들을 수 있어요.")
          .wepliFont(.subheadline, weight: .light)
          .multilineTextAlignment(.center)
          .foregroundStyle(WePLiColor.textSecondary)
        Spacer(minLength: 0)
        VStack(spacing: 10) {
          WePLiPrimaryButton(title: "Apple Music 구독 혜택 보기") { self.store.send(.subscriptionOfferTapped) }
          ExportSecondaryButton(title: "다른 서비스로 담기") { self.store.send(.otherServiceTapped) }
          Button("곡 목록으로 옮기기") { self.store.send(.copyListTapped) }
            .wepliFont(.subheadline)
            .foregroundStyle(WePLiColor.accent)
            .frame(height: 40)
        }
        .padding(.top, 10)
      }
      .padding(.horizontal, 24)
      .padding(.top, 30)
      .padding(.bottom, 24)
      // iOS의 Apple Music 구독 제안 시트
      .musicSubscriptionOffer(isPresented: Binding(
        get: { self.store.showsSubscriptionOffer },
        set: { self.store.send(.subscriptionOfferChanged($0)) }
      ))
    }
  }
}

struct ExportProblemStep: View {
  let store: StoreOf<ExportFlowFeature>
  let problem: ExportProblem

  var body: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: 12) {
        Spacer(minLength: 0)
        switch self.problem {
        case .interrupted: self.interrupted
        case .expired: self.expired
        case let .alreadyExported(record): self.alreadyExported(record)
        }
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 22)
      .padding(.top, 28)
      .padding(.bottom, 24)
    }
  }

  private var interrupted: some View {
    let added = self.store.addedCount
    let total = self.store.pendingSongIDs.count
    return VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        Text("\(added) / \(total)곡")
          .wepliFont(.footnote, weight: .semibold)
          .monospacedDigit()
          .foregroundStyle(WePLiColor.accent)
        ExportProgressBar(fraction: total == 0 ? 0 : Double(added) / Double(total))
      }
      self.title("\(added)곡까지 담았어요").padding(.top, 6)
      self.message(
        "인터넷 연결이 끊겨 잠시 멈췄어요. 담긴 \(added)곡은 \(self.store.service.name)에 그대로 있어요. 연결이 돌아오면 이어서 담고 알려드릴게요."
      )
      VStack(spacing: 4) {
        WePLiPrimaryButton(
          title: "나머지 \(self.store.remainingSongIDs.count)곡 이어서 담기",
          isEnabled: !self.store.isAdding
        ) { self.store.send(.resumeTapped) }
        ExportTextButton(title: "나중에 하기") { self.store.send(.problemLaterTapped) }
      }
      .padding(.top, 8)
    }
  }

  private var expired: some View {
    let name = self.store.service.name
    return VStack(alignment: .leading, spacing: 12) {
      ExportServiceIcon(service: self.store.service, size: 48)
      self.title("\(name) 연결이 만료됐어요").padding(.top, 6)
      self.message("보안을 위해 연결이 풀렸어요. 다시 로그인하면 멈춘 곳부터 이어서 담아요.")
      VStack(spacing: 4) {
        WePLiPrimaryButton(title: "\(name) 다시 연결", isEnabled: !self.store.isConnecting) {
          self.store.send(.reconnectTapped)
        }
        ExportTextButton(title: "다른 서비스로 담기") { self.store.send(.otherServiceTapped) }
      }
      .padding(.top, 8)
    }
  }

  private func alreadyExported(_ record: ExportRecord) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      self.title("이미 \(record.service.name)에 담은\n플리예요")
      self.message("\(record.exportedOn)에 \(record.songCount)곡을 담았어요.")
      VStack(spacing: 0) {
        ForEach(ExportReExport.allCases, id: \.self) { choice in
          self.choiceRow(choice)
        }
      }
      WePLiPrimaryButton(title: "계속") { self.store.send(.reExportContinueTapped) }
        .padding(.top, 8)
    }
  }

  private func choiceRow(_ choice: ExportReExport) -> some View {
    let isSelected = self.store.reExport == choice
    return Button {
      self.store.send(.reExportSelected(choice))
    } label: {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          Text(choice.title)
            .wepliFont(.body)
            .foregroundStyle(isSelected ? WePLiColor.accent : WePLiColor.textPrimary)
          Text(choice.detail).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textQuaternary)
        }
        Spacer()
        if isSelected {
          ExportCheck(size: 20)
        }
      }
      .padding(.vertical, 10)
      .frame(minHeight: 62)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
  }

  private func title(_ text: String) -> some View {
    Text(text).wepliFont(.title3).foregroundStyle(WePLiColor.textPrimary)
  }

  private func message(_ text: String) -> some View {
    Text(text).wepliFont(.subheadline, weight: .light).foregroundStyle(WePLiColor.textSecondary)
  }
}
