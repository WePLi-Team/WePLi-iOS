import ComposableArchitecture
import Foundation

// REQ-039 · UI-8d · DEC-004 — 1위 예측(push). 마감 전에 1곡을 고르고 「예측하기」로 확정하면 바꿀 수 없다.
// 확정은 먼저 보여주고 서버가 거절하면 되돌린다.

@Reducer
struct TopPredictionFeature {
  @ObservableState
  struct State: Equatable {
    let relayID: String
    var prediction: TopPrediction?
    var loadFailed = false
    var selectedID: TopPrediction.Option.ID?
    var isSubmitting = false
    var toast: String?
    /// 아래쪽 「내 칭호」(DEC-021)
    var titles: TitleBoard?

    init(relayID: String) {
      self.relayID = relayID
    }

    var canPredict: Bool {
      self.selectedID != nil && self.prediction?.lockedID == nil && !self.isSubmitting
    }
  }

  enum Action: Equatable {
    case onAppear
    case loaded(TopPrediction)
    case loadFailed
    case retryButtonTapped
    case backButtonTapped
    case optionTapped(TopPrediction.Option.ID)
    case predictTapped
    case predicted(TopPrediction)
    case predictFailed
    case titlesLoaded(TitleBoard)
    case titleTapped(UserTitle.ID)
    case representativeFailed(previous: UserTitle.ID?)
    case toastDismissed
    case delegate(TopPredictionDelegate)
  }

  @Dependency(\.topPredictionClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.prediction == nil else { return .none }
        return .merge(self.load(&state), self.loadTitles())
      case let .loaded(prediction):
        state.prediction = prediction
        return .none
      case .loadFailed:
        state.loadFailed = true
        return .none
      case .retryButtonTapped:
        return self.load(&state)
      case .backButtonTapped:
        return .send(.delegate(.dismiss))
      case let .optionTapped(id):
        // 확정 전까지는 바꿀 수 있다
        guard state.prediction?.lockedID == nil, !state.isSubmitting else { return .none }
        state.selectedID = id
        return .none
      case .predictTapped:
        guard state.canPredict, let optionID = state.selectedID else { return .none }
        state.isSubmitting = true
        state.prediction?.lockedID = optionID
        let relayID = state.relayID
        return .run { send in
          do {
            try await send(.predicted(self.client.predict(relayID, optionID)))
          } catch {
            await send(.predictFailed)
          }
        }
      case let .predicted(prediction):
        state.isSubmitting = false
        state.prediction = prediction
        guard let optionID = prediction.lockedID else { return .none }
        return .send(.delegate(.predicted(relayID: state.relayID, optionID: optionID)))
      case .predictFailed:
        state.isSubmitting = false
        state.prediction?.lockedID = nil
        // 원본에 없는 문구 — 디자인 확인 필요
        state.toast = "예측하지 못했어요. 다시 시도해 주세요"
        return .none
      case .titlesLoaded, .titleTapped, .representativeFailed:
        return self.titles(&state, action)
      case .toastDismissed:
        state.toast = nil
        return .none
      case .delegate:
        return .none
      }
    }
  }

  // MARK: 내 칭호

  private func loadTitles() -> Effect<Action> {
    .run { send in
      // 칭호를 못 받아도 예측은 쓸 수 있다 — 칭호 영역만 비워 둔다
      if let board = try? await self.client.titles() {
        await send(.titlesLoaded(board))
      }
    }
  }

  /// 얻은 칭호만 대표로 고를 수 있다. 먼저 반영하고 실패하면 되돌린다(DEC-004)
  private func titles(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case let .titlesLoaded(board):
      state.titles = board
      return .none
    case let .titleTapped(id):
      guard let board = state.titles, board.canChoose(id) else { return .none }
      let previous = board.representativeID
      state.titles?.representativeID = id
      return .run { send in
        do {
          try await self.client.setRepresentative(id)
        } catch {
          await send(.representativeFailed(previous: previous))
        }
      }
    case let .representativeFailed(previous):
      state.titles?.representativeID = previous
      // 원본에 없는 문구 — 디자인 확인 필요
      state.toast = "대표 칭호를 바꾸지 못했어요"
      return .none
    default:
      return .none
    }
  }

  private func load(_ state: inout State) -> Effect<Action> {
    state.loadFailed = false
    let relayID = state.relayID
    return .run { send in
      do {
        try await send(.loaded(self.client.fetch(relayID)))
      } catch {
        await send(.loadFailed)
      }
    }
  }
}

enum TopPredictionDelegate: Equatable {
  case dismiss
  /// 확정했다 — 홈 1위 예측 섹션도 「예측 완료」로 바꾼다
  case predicted(relayID: String, optionID: TopPrediction.Option.ID)
}
