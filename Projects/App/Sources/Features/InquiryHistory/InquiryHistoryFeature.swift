import ComposableArchitecture
import Foundation

// UI-17a · DEC-024 · DEC-025 — 내 문의 내역(push). 1:1 문의 답변과 이의 신청 결과가 모두 여기로 온다.
// 줄을 누르면 읽음으로 바꾸고(먼저 반영 · 실패 시 되돌림) 상세를 연다.

@Reducer
struct InquiryHistoryFeature {
  @ObservableState
  struct State: Equatable {
    var inquiries: [Inquiry]?
    var loadFailed = false
    var toast: String?
  }

  enum Action: Equatable {
    case onAppear
    case loaded([Inquiry])
    case loadFailed
    case retryButtonTapped
    case backButtonTapped
    case rowTapped(Inquiry.ID)
    case readFailed(Inquiry.ID)
    case composeTapped
    /// 상세에서 문의를 취소하고 돌아왔을 때
    case cancelled(Inquiry.ID)
    case toastDismissed
    case delegate(InquiryHistoryDelegate)
  }

  @Dependency(\.helpCenterClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear, .retryButtonTapped:
        state.loadFailed = false
        return .run { send in
          do {
            try await send(.loaded(self.client.inquiries()))
          } catch {
            await send(.loadFailed)
          }
        }
      case let .loaded(inquiries):
        state.inquiries = inquiries
        return .none
      case .loadFailed:
        state.loadFailed = state.inquiries == nil
        return .none
      case .backButtonTapped:
        return .send(.delegate(.dismiss))
      case let .rowTapped(id):
        guard var inquiries = state.inquiries, var inquiry = inquiries.first(where: { $0.id == id }) else {
          return .none
        }
        let read = Self.markRead(inquiry, in: &inquiries, client: self.client) { .readFailed($0) }
        state.inquiries = inquiries
        inquiry.isRead = true
        return .merge(read, .send(.delegate(.showInquiry(inquiry))))
      case let .readFailed(id):
        state.inquiries?.setRead(id, false)
        return .none
      case .composeTapped:
        return .send(.delegate(.compose))
      case let .cancelled(id):
        state.inquiries?.removeAll { $0.id == id }
        state.toast = InquiryText.cancelledToast
        return .none
      case .toastDismissed:
        state.toast = nil
        return .none
      case .delegate:
        return .none
      }
    }
  }

  /// 읽지 않은 답을 열면 읽음으로 — 고객센터(7b) 목록도 같은 규칙을 쓴다
  static func markRead<A: Sendable>(
    _ inquiry: Inquiry,
    in inquiries: inout [Inquiry],
    client: HelpCenterClient,
    onFailure: @escaping @Sendable (Inquiry.ID) -> A
  ) -> Effect<A> {
    guard !inquiry.isRead else { return .none }
    inquiries.setRead(inquiry.id, true)
    let id = inquiry.id
    return .run { send in
      do {
        try await client.markRead(id)
      } catch {
        await send(onFailure(id))
      }
    }
  }
}

enum InquiryHistoryDelegate: Equatable {
  case dismiss
  case showInquiry(Inquiry)
  /// 빈 상태 「1:1 문의하기」 → 고객센터 문의 시트
  case compose
}

/// 원본에 없어 채운 문구 — 디자인 확인 필요
enum InquiryText {
  static let cancelledToast = "문의를 취소했어요"
  static let failedToast = "저장하지 못했어요. 다시 시도해 주세요"
}
