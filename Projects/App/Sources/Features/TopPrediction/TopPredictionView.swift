import ComposableArchitecture
import SwiftUI

// REQ-039 · UI-8d — 1위 예측. 후보마다 비율 · 막대, 고른 뒤 「예측하기」, 확정하면 「내 예측 · 변경 불가」 카드

struct TopPredictionView: View {
  let store: StoreOf<TopPredictionFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        HStack {
          WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") { self.store.send(.backButtonTapped) }
          Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        ScrollView {
          if let prediction = self.store.prediction {
            self.content(prediction)
          } else if self.store.loadFailed {
            self.failed
          } else {
            ProgressView().tint(WePLiColor.textTertiary).frame(maxWidth: .infinity, minHeight: 300)
          }
        }
      }
      .background(WePLiColor.background.ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
      .wepliToast(Binding(get: { self.store.toast }, set: {
        if $0 == nil {
          self.store.send(.toastDismissed)
        }
      }))
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private var failed: some View {
    VStack(spacing: 12) {
      // 원본에 없는 문구 — 디자인 확인 필요
      Text("예측을 불러오지 못했어요").wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
      Button("다시 시도") { self.store.send(.retryButtonTapped) }
        .wepliFont(.subheadline, weight: .semibold)
        .foregroundStyle(WePLiColor.accent)
    }
    .frame(maxWidth: .infinity, minHeight: 300)
  }

  private func content(_ prediction: TopPrediction) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 8) {
        Text("1위 예측 · 마감 \(prediction.remaining) 전까지")
          .wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(WePLiColor.accent)
        Text("\(prediction.relayTitle)\n최종 1위는?")
          .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 26, relativeTo: .title))
          .foregroundStyle(WePLiColor.textPrimary)
          .accessibilityAddTraits(.isHeader)
      }
      .padding(.horizontal, 20)
      .padding(.top, 12)
      if let locked = prediction.locked {
        TopPredictionLockedCard(option: locked).padding(.horizontal, 20).padding(.top, 18)
      } else {
        self.options(prediction).padding(.top, 12)
        WePLiPrimaryButton(title: "예측하기", isEnabled: self.store.canPredict) { self.store.send(.predictTapped) }
          .padding(.horizontal, 20)
          .padding(.top, 14)
      }
      self.record(prediction.record).padding(.horizontal, 20).padding(.top, 14)
    }
    .padding(.bottom, 60)
  }

  private func options(_ prediction: TopPrediction) -> some View {
    VStack(spacing: 0) {
      ForEach(prediction.options) { option in
        TopPredictionRow(option: option, isSelected: self.store.selectedID == option.id) {
          self.store.send(.optionTapped(option.id))
        }
      }
    }
  }

  @ViewBuilder
  private func record(_ record: TopPrediction.Record) -> some View {
    if let text = TopPredictionRecordText(record) {
      (Text(text.lead) + Text(text.hits).font(WePLiFont.font(.footnote, weight: .semibold))
        .foregroundColor(WePLiColor.textPrimary) + Text(text.tail))
        .wepliFont(.footnote, weight: .light)
        .foregroundStyle(WePLiColor.textTertiary)
    } else {
      // 홈 1위 예측(UI-12a)의 처음 문구
      Text("처음이라면 지금 한 번 맞혀보세요").wepliFont(.footnote, weight: .light).foregroundStyle(WePLiColor.textTertiary)
    }
  }
}

/// 후보 한 줄 — 아트 · 제목 · 비율 · 막대 · 고른 표시
private struct TopPredictionRow: View {
  let option: TopPrediction.Option
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 48, height: 48)
        VStack(alignment: .leading, spacing: 8) {
          HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(self.option.title)
              .wepliFont(.body)
              .foregroundStyle(self.isSelected ? WePLiColor.accent : WePLiColor.textPrimary)
              .lineLimit(1)
            Spacer(minLength: 0)
            Text("\(self.option.percent)%")
              .wepliFont(.caption, weight: .light)
              .monospacedDigit()
              .foregroundStyle(WePLiColor.textTertiary)
          }
          GeometryReader { proxy in
            Capsule().fill(Color.white.opacity(0.08))
              .overlay(alignment: .leading) {
                Capsule()
                  .fill(self.isSelected ? WePLiColor.accent : Color.white.opacity(0.28))
                  .frame(width: proxy.size.width * Double(self.option.percent) / 100)
              }
          }
          .frame(height: 3)
        }
        WePLiSelectionCheck(isOn: self.isSelected)
      }
      .padding(.horizontal, 20)
      .frame(height: 68)
      .contentShape(Rectangle())
      .animation(.easeOut(duration: 0.2), value: self.isSelected)
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(self.option.title), \(self.option.percent)퍼센트 예측")
    .accessibilityAddTraits(self.isSelected ? [.isButton, .isSelected] : .isButton)
  }
}

/// 확정한 예측 — 글래스 캡슐, 원형 아트
private struct TopPredictionLockedCard: View {
  let option: TopPrediction.Option

  var body: some View {
    HStack(spacing: 12) {
      Circle().fill(WePLiColor.imagePlaceholder).frame(width: 44, height: 44)
      VStack(alignment: .leading, spacing: 1) {
        Text("내 예측 · 변경 불가")
          .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 11, relativeTo: .caption2))
          .foregroundStyle(WePLiColor.positive)
        Text(self.option.title).wepliFont(.body, weight: .semibold).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
      }
      Spacer(minLength: 8)
      Text("맞히면 예언자 +1").wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textTertiary).lineLimit(1)
    }
    .padding(.leading, 10)
    .padding(.trailing, 20)
    .frame(height: 64)
    .wepliGlass(in: Capsule())
    .accessibilityElement(children: .combine)
  }
}

#Preview {
  NavigationStack {
    TopPredictionView(store: Store(initialState: TopPredictionFeature.State(relayID: "first-love")) {
      TopPredictionFeature()
    })
  }
}
