import ComposableArchitecture
import Foundation

// REQ-111 · UI-7b · DEC-013 — 고객센터(push). 자주 묻는 질문을 먼저 보여주고, 해결이 안 되면 1:1 문의 시트로 넘어간다.
// 「내 문의 내역」 줄을 누르면 읽음으로 바꾸고 상세(UI-17a)를 연다.

@Reducer
struct HelpCenterFeature {
  @ObservableState
  struct State: Equatable {
    /// 펼친 FAQ — 원본은 두 번째가 열려 있다
    var openFAQs: Set<HelpFAQ.ID> = [1]
    var inquiries: [Inquiry] = []
    var isComposing = false
    var draft = InquiryDraft()
    var isSending = false
    var toast: String?

    /// 고객센터에는 최근 3건만 — 더 있으면 머리 꺾쇠로 내 문의 내역(UI-17a)을 연다
    static let recentCount = 3

    var recentInquiries: [Inquiry] {
      Array(self.inquiries.prefix(Self.recentCount))
    }

    var hasMoreInquiries: Bool {
      self.inquiries.count > Self.recentCount
    }
  }

  enum Action: Equatable {
    case onAppear
    case loaded([Inquiry])
    case backButtonTapped
    case faqTapped(HelpFAQ.ID)
    case composeTapped
    case composeDismissed
    case categorySelected(InquiryCategory)
    case textChanged(String)
    case emailToggled(Bool)
    case emailChanged(String)
    case photosPicked([Data])
    case photoRemoved(Int)
    case sendTapped
    case sent(Inquiry)
    case sendFailed
    case inquiryTapped(Inquiry.ID)
    case readFailed(Inquiry.ID)
    case historyTapped
    /// 문의 상세 「추가로 문의하기」 — 같은 유형으로 문의 시트를 연다
    case followUpRequested(InquiryCategory)
    /// 문의 상세에서 취소한 문의
    case inquiryCancelled(Inquiry.ID)
    case toastDismissed
    case delegate(HelpCenterDelegate)
  }

  @Dependency(\.helpCenterClient)
  var client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .run { send in
          let inquiries = await (try? self.client.inquiries()) ?? []
          await send(.loaded(inquiries))
        }
      case let .loaded(inquiries):
        state.inquiries = inquiries
        return .none
      case .backButtonTapped:
        return .send(.delegate(.dismiss))
      case let .faqTapped(id):
        if state.openFAQs.contains(id) {
          state.openFAQs.remove(id)
        } else {
          state.openFAQs.insert(id)
        }
        return .none
      case .composeTapped:
        state.isComposing = true
        return .none
      case .composeDismissed:
        // 닫아도 쓰던 내용은 남긴다(원본)
        state.isComposing = false
        return .none
      case .categorySelected, .textChanged, .emailToggled, .emailChanged, .photosPicked, .photoRemoved:
        self.edit(&state, action)
        return .none
      case .sendTapped, .sent, .sendFailed:
        return self.send(&state, action)
      case .inquiryTapped, .readFailed, .historyTapped, .followUpRequested, .inquiryCancelled:
        return self.history(&state, action)
      case .toastDismissed:
        state.toast = nil
        return .none
      case .delegate:
        return .none
      }
    }
  }

  private func history(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case let .inquiryTapped(id):
      guard var inquiry = state.inquiries.first(where: { $0.id == id }) else { return .none }
      let read = InquiryHistoryFeature.markRead(inquiry, in: &state.inquiries, client: self.client) {
        .readFailed($0)
      }
      inquiry.isRead = true
      return .merge(read, .send(.delegate(.showInquiry(inquiry))))
    case let .readFailed(id):
      state.inquiries.setRead(id, false)
    case .historyTapped:
      return .send(.delegate(.showHistory))
    case let .followUpRequested(category):
      state.draft.category = category
      state.isComposing = true
    case let .inquiryCancelled(id):
      state.inquiries.removeAll { $0.id == id }
      state.toast = InquiryText.cancelledToast
    default:
      break
    }
    return .none
  }

  private func edit(_ state: inout State, _ action: Action) {
    switch action {
    case let .categorySelected(category):
      state.draft.category = category
    case let .textChanged(text):
      state.draft.text = String(text.prefix(InquiryDraft.textLimit))
    case let .emailToggled(isOn):
      state.draft.wantsEmail = isOn
    case let .emailChanged(email):
      state.draft.email = String(email.prefix(InquiryDraft.emailLimit))
    case let .photosPicked(photos):
      state.draft.photos = Array((state.draft.photos + photos).prefix(InquiryDraft.photoLimit))
    case let .photoRemoved(index):
      guard state.draft.photos.indices.contains(index) else { return }
      state.draft.photos.remove(at: index)
    default:
      break
    }
  }

  private func send(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case .sendTapped:
      guard state.draft.canSend, !state.isSending else { return .none }
      state.isSending = true
      let draft = state.draft
      return .run { send in
        let device = await self.client.deviceInfo()
        do {
          try await send(.sent(self.client.submit(draft, device)))
        } catch {
          await send(.sendFailed)
        }
      }
    case let .sent(inquiry):
      state.isSending = false
      state.inquiries.insert(inquiry, at: 0)
      // 원본: 이메일 설정은 다음 문의에도 그대로 둔다
      state.draft = InquiryDraft(wantsEmail: state.draft.wantsEmail, email: state.draft.email)
      state.isComposing = false
      state.toast = "문의를 보냈어요. 답변이 오면 알림으로 알려드려요"
    case .sendFailed:
      state.isSending = false
      // 원본에 없는 문구 — 디자인 확인 필요
      state.toast = "문의를 보내지 못했어요. 다시 시도해 주세요"
    default:
      break
    }
    return .none
  }
}

enum HelpCenterDelegate: Equatable {
  case dismiss
  case showInquiry(Inquiry)
  case showHistory
}
