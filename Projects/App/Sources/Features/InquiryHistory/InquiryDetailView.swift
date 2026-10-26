import ComposableArchitecture
import SwiftUI

// UI-17a — 문의 답변 · 이의 신청 결과 · 답변 대기 상세

struct InquiryDetailView: View {
  @Perception.Bindable var store: StoreOf<InquiryDetailFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        InquiryNavBar(title: self.store.title) { self.store.send(.backButtonTapped) }
        ScrollView {
          VStack(alignment: .leading, spacing: 22) {
            InquiryDetailHeader(inquiry: self.store.inquiry)
            self.content()
          }
          .padding(.horizontal, 20)
          .padding(.top, 18)
          .padding(.bottom, 60)
        }
      }
      .background(WePLiColor.background.ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
      .confirmationDialog(self.$store.scope(state: \.cancelDialog, action: \.cancelDialog))
      .wepliToast(self.store.toast) { self.store.send(.toastDismissed) }
    }
  }

  @ViewBuilder
  private func content() -> some View {
    switch self.store.inquiry.kind {
    case let .question(_, reply):
      self.myQuestion
      if let reply {
        self.answer(reply)
      } else {
        InquiryWaitingNote()
        Button("문의 취소") { self.store.send(.cancelTapped) }
          .wepliFont(.subheadline)
          .underline()
          .foregroundStyle(WePLiColor.textQuaternary)
          .padding(.vertical, 8)
          .disabled(self.store.isCancelling)
      }
    case let .appealResult(result):
      self.appealResult(result)
    }
  }

  private var myQuestion: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("내 문의").wepliFont(.footnote, weight: .semibold).foregroundStyle(WePLiColor.textQuaternary)
      Text(self.store.inquiry.body)
        .wepliFont(.body, weight: .light)
        .foregroundStyle(WePLiColor.textMuted)
        .lineSpacing(8)
    }
  }

  private func answer(_ reply: InquiryReply) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 10) {
        // 원본은 로고 이미지 — 앱에 로고 에셋이 없어 글자로 대신한다
        Text("W")
          .wepliFont(.footnote, weight: .bold)
          .foregroundStyle(WePLiColor.textPrimary)
          .frame(width: 32, height: 32)
          .background(WePLiColor.surface1, in: Circle())
          .accessibilityHidden(true)
        Text("위플리 운영팀").wepliFont(.subheadline, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
        Text(reply.dateText).wepliFont(.caption, weight: .light).foregroundStyle(WePLiColor.textQuaternary)
      }
      Text(reply.text).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary).lineSpacing(9)
      self.helpful.padding(.top, 6)
      InquirySmallButton(title: "추가로 문의하기") { self.store.send(.followUpTapped) }
    }
    .padding(.top, 20)
    .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.1)).frame(height: 0.5) }
  }

  private var helpful: some View {
    HStack(spacing: 8) {
      Text("답변이 도움이 됐나요?").wepliFont(.subheadline).foregroundStyle(WePLiColor.textTertiary)
        .frame(maxWidth: .infinity, alignment: .leading)
      WePLiChip(title: "네", isOn: self.store.inquiry.isHelpful == true) { self.store.send(.helpfulTapped(true)) }
      WePLiChip(title: "아니요", isOn: self.store.inquiry.isHelpful == false) {
        self.store.send(.helpfulTapped(false))
      }
    }
  }

  private func appealResult(_ result: InquiryAppealResult) -> some View {
    VStack(alignment: .leading, spacing: 22) {
      VStack(alignment: .leading, spacing: 8) {
        Text(result.headline).wepliFont(.headline).foregroundStyle(WePLiColor.accent)
        Text(result.message).wepliFont(.body, weight: .light).foregroundStyle(WePLiColor.textMuted).lineSpacing(8)
      }
      InquiryTimeline(steps: result.steps)
      if result.postID != nil {
        InquirySmallButton(title: "내 게시글 보기") { self.store.send(.showPostTapped) }
      }
    }
  }
}

#Preview {
  NavigationStack {
    InquiryDetailView(store: Store(initialState: InquiryDetailFeature.State(inquiry: MockInquiries.samples[0])) {
      InquiryDetailFeature()
    })
  }
}
