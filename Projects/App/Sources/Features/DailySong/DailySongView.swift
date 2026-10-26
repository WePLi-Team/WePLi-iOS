import ComposableArchitecture
import SwiftUI

// REQ-101 · UI-6c — 오늘의 한 곡. 질문 카드 → 지금 가장 많이 고른 곡 → 사람들의 답변(답하기 전엔 흐리게)

struct DailySongView: View {
  @Perception.Bindable var store: StoreOf<DailySongFeature>

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
          VStack(alignment: .leading, spacing: 0) {
            Text("오늘의 한 곡")
              .wepliFont(.screenTitle)
              .foregroundStyle(WePLiColor.textPrimary)
              .padding(.horizontal, 20)
              .padding(.top, 2)
              .padding(.bottom, 14)
              .accessibilityAddTraits(.isHeader)
            if let question = self.store.question {
              self.content(question)
            } else if self.store.loadFailed {
              self.failed
            } else {
              ProgressView().tint(WePLiColor.textTertiary).frame(maxWidth: .infinity, minHeight: 300)
            }
          }
          .padding(.bottom, 60)
        }
      }
      .background(WePLiColor.background.ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
      .wepliToast(self.store.toast) { self.store.send(.toastDismissed) }
      .sheet(item: self.$store.scope(state: \.picker, action: \.picker)) { pickerStore in
        SongPickerView(store: pickerStore)
          .wepliSheetStyle(detents: [.large])
      }
      .onAppear { self.store.send(.onAppear) }
      .onDisappear { self.store.send(.onDisappear) }
    }
  }

  private var failed: some View {
    VStack(spacing: 12) {
      // 원본에 없는 문구 — 디자인 확인 필요
      Text("오늘의 질문을 불러오지 못했어요").wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
      Button("다시 시도") { self.store.send(.retryButtonTapped) }
        .wepliFont(.subheadline, weight: .semibold)
        .foregroundStyle(WePLiColor.accent)
    }
    .frame(maxWidth: .infinity, minHeight: 300)
  }

  private func content(_ question: DailyQuestion) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      DailyQuestionCard(
        question: question,
        now: self.store.now,
        onPick: { self.store.send(.pickTapped) }
      )
      .padding(.horizontal, 16)
      self.sectionTitle("지금 가장 많이 고른 곡").padding(.top, 24).padding(.bottom, 8)
      VStack(spacing: 8) {
        ForEach(question.top) { song in
          self.topRow(song, percent: question.percent(song))
        }
      }
      .padding(.horizontal, 20)
      .animation(.easeOut(duration: 0.4), value: question.answerCount)
      self.sectionTitle("사람들의 답변").padding(.top, 24).padding(.bottom, 4)
      self.answers(question)
    }
  }

  private func sectionTitle(_ title: String) -> some View {
    Text(title)
      .wepliFont(.callout, weight: .semibold)
      .foregroundStyle(WePLiColor.textPrimary)
      .padding(.horizontal, 20)
      .accessibilityAddTraits(.isHeader)
  }

  private func topRow(_ song: DailyQuestion.TopSong, percent: Int) -> some View {
    HStack(spacing: 10) {
      RoundedRectangle(cornerRadius: 6).fill(WePLiColor.imagePlaceholder).frame(width: 36, height: 36)
      Text("\(song.title) · \(song.artist)").wepliFont(.subheadline).foregroundStyle(WePLiColor.textPrimary)
        .lineLimit(1)
      Spacer(minLength: 8)
      Text("\(percent)%").wepliFont(.footnote, weight: .semibold).monospacedDigit().foregroundStyle(WePLiColor.accent)
    }
    .padding(.leading, 8)
    .padding(.trailing, 14)
    .frame(height: 52)
    .background(alignment: .leading) {
      GeometryReader { proxy in
        Rectangle().fill(WePLiColor.accentStrong.opacity(0.16)).frame(width: proxy.size.width * Double(percent) / 100)
      }
    }
    .background(WePLiColor.surface1)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .accessibilityElement(children: .combine)
  }

  private func answers(_ question: DailyQuestion) -> some View {
    let isLocked = question.myAnswer == nil
    return VStack(spacing: 0) {
      ForEach(question.answers) { answer in
        HStack(alignment: .top, spacing: 10) {
          Circle().fill(WePLiColor.imagePlaceholder).frame(width: 34, height: 34)
          VStack(alignment: .leading, spacing: 6) {
            Text(answer.user).wepliFont(.footnote, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
            HStack(spacing: 8) {
              Circle().fill(WePLiColor.surface4).frame(width: 22, height: 22)
              Text(answer.songTitle).wepliFont(.footnote).foregroundStyle(WePLiColor.textPrimary)
            }
            .padding(.leading, 4)
            .padding(.trailing, 12)
            .frame(height: 30)
            .background(WePLiColor.accentStrong.opacity(0.14), in: Capsule())
            Text(answer.comment).wepliFont(.subheadline).foregroundStyle(WePLiColor.textMuted)
          }
          Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
      }
    }
    .blur(radius: isLocked ? 8 : 0)
    .accessibilityHidden(isLocked)
    .overlay {
      if isLocked {
        Text("내 한 곡을 고르면 볼 수 있어요")
          .wepliFont(.footnote, weight: .medium)
          .foregroundStyle(WePLiColor.textMuted)
          .padding(.horizontal, 14)
          .frame(height: 36)
          .background(WePLiColor.surface1.opacity(0.85), in: Capsule())
      }
    }
    .animation(.easeOut(duration: 0.4), value: isLocked)
  }
}

/// 질문 카드 — 날짜 · 남은 시간 · 질문 · 답한 사람 수 · 고르기 / 내 답변
private struct DailyQuestionCard: View {
  let question: DailyQuestion
  let now: Date
  let onPick: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text(DailySongText.dateTitle(self.question.date)).wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(WePLiColor.accentStrong)
        Spacer()
        Text(DailySongText.remaining(from: self.now, to: self.question.endsAt))
          .wepliFont(.footnote)
          .monospacedDigit()
          .foregroundStyle(WePLiColor.textQuaternary)
      }
      Text(self.question.question)
        .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 26, relativeTo: .title))
        .foregroundStyle(WePLiColor.textPrimary)
      Text("\(HomeText.count(self.question.answerCount))명이 답했어요")
        .wepliFont(.footnote)
        .monospacedDigit()
        .foregroundStyle(WePLiColor.textSecondary)
      if let pick = self.question.myAnswer {
        HStack(spacing: 10) {
          RoundedRectangle(cornerRadius: 6).fill(WePLiColor.imagePlaceholder).frame(width: 40, height: 40)
          VStack(alignment: .leading, spacing: 2) {
            Text("내 답변").wepliFont(.caption, weight: .semibold).foregroundStyle(WePLiColor.positive)
            Text("\(pick.title) · \(pick.artist)").wepliFont(.subheadline, weight: .semibold)
              .foregroundStyle(WePLiColor.textPrimary)
              .lineLimit(1)
          }
          Spacer(minLength: 8)
          Button("바꾸기", action: self.onPick).wepliFont(.footnote).foregroundStyle(WePLiColor.textQuaternary)
        }
        .padding(10)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        .padding(.top, 6)
      } else {
        Button(action: self.onPick) {
          Text("내 한 곡 고르고 답변 보기")
            .wepliFont(.callout, weight: .semibold)
            .foregroundStyle(WePLiColor.textOnCTA)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(WePLiGradient.cta, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
      }
    }
    .padding(20)
    .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 25))
    .padding(1)
    .background(WePLiColor.accentStrong.opacity(0.32), in: RoundedRectangle(cornerRadius: 26))
  }
}

#Preview {
  NavigationStack {
    DailySongView(store: Store(initialState: DailySongFeature.State()) { DailySongFeature() })
  }
}
