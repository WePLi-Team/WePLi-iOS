import ComposableArchitecture
import SwiftUI

// REQ-111 · UI-7b — 고객센터. 자주 묻는 질문(펼치고 접기) → 1:1 문의하기 → 내 문의 내역

struct HelpCenterView: View {
  @Perception.Bindable var store: StoreOf<HelpCenterFeature>

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
            VStack(alignment: .leading, spacing: 4) {
              Text("고객센터").wepliFont(.screenTitle).foregroundStyle(WePLiColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
              Text("무엇을 도와드릴까요?").wepliFont(.body).foregroundStyle(WePLiColor.textTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 2)
            self.sectionTitle("자주 묻는 질문").padding(.top, 18).padding(.bottom, 6)
            self.faqs.padding(.horizontal, 16)
            self.composeCard.padding(.horizontal, 16).padding(.top, 20)
            if !self.store.inquiries.isEmpty {
              self.sectionTitle("내 문의 내역").padding(.top, 24).padding(.bottom, 6)
              ForEach(self.store.inquiries) { inquiry in
                InquiryRow(inquiry: inquiry)
              }
            }
          }
          .padding(.bottom, 60)
        }
      }
      .background(WePLiColor.background.ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
      .wepliToast(Binding(get: { self.store.toast }, set: {
        if $0 == nil {
          self.store.send(.toastDismissed)
        }
      }))
      .sheet(isPresented: Binding(get: { self.store.isComposing }, set: {
        if !$0 {
          self.store.send(.composeDismissed)
        }
      })) {
        InquirySheet(store: self.store)
          .wepliSheetStyle(detents: [.large])
      }
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private func sectionTitle(_ title: String) -> some View {
    Text(title)
      .wepliFont(.callout, weight: .semibold)
      .foregroundStyle(WePLiColor.textPrimary)
      .padding(.horizontal, 20)
      .accessibilityAddTraits(.isHeader)
  }

  private var faqs: some View {
    VStack(spacing: 0) {
      ForEach(HelpFAQ.all) { faq in
        let isOpen = self.store.openFAQs.contains(faq.id)
        VStack(alignment: .leading, spacing: 0) {
          Button {
            self.store.send(.faqTapped(faq.id))
          } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
              Text("Q").wepliFont(.body, weight: .bold).foregroundStyle(WePLiColor.accentStrong)
              Text(faq.question).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
              Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(WePLiColor.textQuaternary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 54)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityAddTraits(isOpen ? [.isButton, .isSelected] : .isButton)
          if isOpen {
            Text(faq.answer)
              .wepliFont(.subheadline)
              .foregroundStyle(WePLiColor.textSecondary)
              .padding(.leading, 39)
              .padding(.trailing, 16)
              .padding(.bottom, 14)
          }
        }
        .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5) }
      }
    }
    .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 20))
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .animation(.easeInOut(duration: 0.2), value: self.store.openFAQs)
  }

  private var composeCard: some View {
    Button {
      self.store.send(.composeTapped)
    } label: {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          Text("1:1 문의하기").wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
          // 미결정 — 운영 시간 · 답변 기한 정책(원본 예시)
          Text("평일 10:00–18:00 · 보통 하루 안에 답해드려요").wepliFont(.footnote).foregroundStyle(WePLiColor.textSecondary)
        }
        Spacer()
        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(WePLiColor.accent)
      }
      .padding(16)
      .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 20))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

/// 내 문의 한 줄 — 제목 · 「유형 · 날짜」 · 답변 완료 / 답변 대기
private struct InquiryRow: View {
  let inquiry: Inquiry

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(self.inquiry.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
        Text("\(self.inquiry.category.title) · \(self.inquiry.dateText)").wepliFont(.caption)
          .foregroundStyle(WePLiColor.textQuaternary)
      }
      Spacer(minLength: 8)
      Text(self.inquiry.isAnswered ? "답변 완료" : "답변 대기")
        .wepliFont(.caption, weight: .semibold)
        .foregroundStyle(self.inquiry.isAnswered ? WePLiColor.positive : WePLiColor.textTertiary)
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(
          self.inquiry.isAnswered ? WePLiColor.positive.opacity(0.14) : WePLiColor.disabledFill,
          in: Capsule()
        )
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .accessibilityElement(children: .combine)
  }
}

#Preview {
  NavigationStack {
    HelpCenterView(store: Store(initialState: HelpCenterFeature.State()) { HelpCenterFeature() })
  }
}
