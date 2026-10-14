import ComposableArchitecture
import Foundation

// REQ-033 · UI-3b · DEC-004 — 카드 투표

@Reducer
struct CardVoteFeature {
  @ObservableState
  struct State: Equatable {
    let relayID: String
    let topic: String
    var candidates: [VoteCandidate] = []
    var index = 0
    /// 「주제와 어울려요」를 고른 수(완료 화면 문구)
    var fitsCount = 0
    var loadFailed = false
    /// 서버 저장에 실패한 투표 수 — 0보다 크면 알림을 띄운다
    var failedSubmissionCount = 0
    var toast: String?

    static let cardsPerRound = 10

    var current: VoteCandidate? {
      self.candidates.indices.contains(self.index) ? self.candidates[self.index] : nil
    }

    var next: VoteCandidate? {
      self.candidates.indices.contains(self.index + 1) ? self.candidates[self.index + 1] : nil
    }

    var isDone: Bool {
      !self.candidates.isEmpty && self.index >= self.candidates.count
    }

    init(relayID: String, topic: String) {
      self.relayID = relayID
      self.topic = topic
    }
  }

  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case onAppear
    case candidatesLoaded([VoteCandidate])
    case candidatesFailed
    /// 버튼을 누르거나 카드를 임계값 너머로 밀었을 때(카드가 날아간 뒤)
    case voted(VoteChoice)
    case submissionFailed
    case restartButtonTapped
    case backButtonTapped
    case returnToRelayButtonTapped
    case playTapped(VoteCandidate.ID)
    case delegate(Delegate)
  }

  enum Delegate: Equatable {
    case dismiss
    case playPreview(VoteCandidate.ID)
  }

  @Dependency(\.cardVoteClient)
  var client

  var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case .onAppear:
        guard state.candidates.isEmpty else { return .none }
        state.loadFailed = false
        let relayID = state.relayID
        return .run { send in
          do {
            let candidates = try await self.client.fetchCandidates(relayID)
            await send(.candidatesLoaded(Array(candidates.prefix(State.cardsPerRound))))
          } catch {
            await send(.candidatesFailed)
          }
        }

      case let .candidatesLoaded(candidates):
        state.candidates = candidates
        return .none

      case .candidatesFailed:
        state.loadFailed = true
        return .none

      case let .voted(choice):
        guard let song = state.current else { return .none }
        state.index += 1
        if choice == .fits {
          state.fitsCount += 1
        }
        let relayID = state.relayID
        return .run { send in
          do {
            try await self.client.submit(relayID, song.id, choice)
          } catch {
            await send(.submissionFailed)
          }
        }

      case .submissionFailed:
        state.failedSubmissionCount += 1
        // 원본에 없는 문구 — 디자인 확인 필요
        state.toast = "투표를 저장하지 못했어요. 잠시 후 다시 시도해 주세요"
        return .none

      case .restartButtonTapped:
        state.index = 0
        state.fitsCount = 0
        return .none

      case .backButtonTapped, .returnToRelayButtonTapped:
        return .send(.delegate(.dismiss))

      case let .playTapped(id):
        return .send(.delegate(.playPreview(id)))

      case .delegate:
        return .none
      }
    }
  }
}
