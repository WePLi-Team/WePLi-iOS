import ComposableArchitecture
import Foundation

// REQ-101 · UI-6c · DEC-004 · DEC-012 — 오늘의 한 곡(push). 곡은 곡 검색(UI-2a)으로 고른다.
// 내가 답해야 다른 사람의 답이 보인다. 「바꾸기」는 곡을 다시 고른다(원본은 답하기 전으로 되돌림).

@Reducer
struct DailySongFeature {
  @ObservableState
  struct State: Equatable {
    var question: DailyQuestion?
    var loadFailed = false
    var now = Date()
    var isSending = false
    var toast: String?
    @Presents var picker: SongPickerFeature.State?

    var hasAnswered: Bool {
      self.question?.myAnswer != nil
    }
  }

  enum Action: Equatable {
    case onAppear
    case onDisappear
    case loaded(DailyQuestion)
    case loadFailed
    case retryButtonTapped
    case backButtonTapped
    case timerTicked
    case pickTapped
    case picker(PresentationAction<SongPickerFeature.Action>)
    case answered(DailyQuestion)
    case answerFailed(DailyQuestion.Pick?)
    case toastDismissed
    case delegate(DailySongDelegate)
  }

  enum CancelID {
    case timer
  }

  @Dependency(\.dailySongClient)
  var client

  @Dependency(\.continuousClock)
  var clock

  @Dependency(\.date.now)
  var date

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.now = self.date
        let timer = Effect<Action>.run { send in
          for await _ in self.clock.timer(interval: .seconds(1)) {
            await send(.timerTicked)
          }
        }
        .cancellable(id: CancelID.timer, cancelInFlight: true)
        return state.question == nil ? .merge(self.load(&state), timer) : timer
      case .onDisappear:
        return .cancel(id: CancelID.timer)
      case let .loaded(question):
        state.question = question
        return .none
      case .loadFailed:
        state.loadFailed = true
        return .none
      case .retryButtonTapped:
        return self.load(&state)
      case .backButtonTapped:
        return .send(.delegate(.dismiss))
      case .timerTicked:
        state.now = self.date
        return .none
      case .pickTapped:
        guard !state.isSending else { return .none }
        state.picker = SongPickerFeature.State()
        return .none
      case .picker, .answered, .answerFailed:
        return self.answer(&state, action)
      case .toastDismissed:
        state.toast = nil
        return .none
      case .delegate:
        return .none
      }
    }
    .ifLet(\.$picker, action: \.picker) {
      SongPickerFeature()
    }
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.loadFailed = false
    return .run { send in
      do {
        try await send(.loaded(self.client.fetch()))
      } catch {
        await send(.loadFailed)
      }
    }
  }

  private func answer(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case let .picker(.presented(.delegate(.add(tracks)))):
      state.picker = nil
      // 한 곡만 — 처음 고른 곡
      guard let track = tracks.first, let question = state.question else { return .none }
      let pick = DailyQuestion.Pick(title: track.title, artist: track.artist)
      let previous = question.myAnswer
      // 내 답은 먼저 보여주고, 수 · 비율은 서버가 다시 센 값으로 바꾼다
      state.question?.myAnswer = pick
      state.isSending = true
      return .run { send in
        do {
          try await send(.answered(self.client.answer(question.id, pick)))
        } catch {
          await send(.answerFailed(previous))
        }
      }
    case .picker(.presented(.delegate(.dismiss))):
      state.picker = nil
    case let .answered(question):
      state.isSending = false
      state.question = question
    case let .answerFailed(previous):
      state.isSending = false
      state.question?.myAnswer = previous
      // 원본에 없는 문구 — 디자인 확인 필요
      state.toast = "답하지 못했어요. 다시 시도해 주세요"
    default:
      break
    }
    return .none
  }
}

enum DailySongDelegate: Equatable {
  case dismiss
}
