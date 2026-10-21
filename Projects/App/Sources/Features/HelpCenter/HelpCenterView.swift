import ComposableArchitecture
import SwiftUI

// REQ-111 · UI-7b — 고객센터. 자주 묻는 질문(펼치고 접기) → 1:1 문의하기 → 내 문의 내역(줄 모양 · 상세는 UI-17a)

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
              self.historyTitle.padding(.top, 24).padding(.bottom, 6)
              ForEach(self.store.recentInquiries) { inquiry in
                InquiryListRow(inquiry: inquiry) { self.store.send(.inquiryTapped(inquiry.id)) }
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

  /// 더 볼 문의가 있을 때만 꺾쇠 — 누르면 내 문의 내역(UI-17a)
  @ViewBuilder private var historyTitle: some View {
    if self.store.hasMoreInquiries {
      Button {
        self.store.send(.historyTapped)
      } label: {
        HStack(spacing: 4) {
          Text("내 문의 내역").wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
          Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
            .foregroundStyle(WePLiColor.textPrimary)
        }
        .padding(.horizontal, 20)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityAddTraits(.isHeader)
    } else {
      self.sectionTitle("내 문의 내역")
    }
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

#Preview {
  NavigationStack {
    HelpCenterView(store: Store(initialState: HelpCenterFeature.State()) { HelpCenterFeature() })
  }
}
