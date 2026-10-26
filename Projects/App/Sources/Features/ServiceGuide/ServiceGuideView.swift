import ComposableArchitecture
import SwiftUI

// REQ-113 · UI-7f — 전체 화면 페이저. 좌우로 넘기거나 「다음」, 마지막 장은 「시작하기」

struct ServiceGuideView: View {
  @Perception.Bindable var store: StoreOf<ServiceGuideFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        self.topBar
        TabView(selection: self.$store.page.sending(\.pageChanged)) {
          ForEach(Array(ServiceGuidePage.all.enumerated()), id: \.element.id) { index, page in
            ServiceGuideCard(page: page).tag(index)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.3), value: self.store.page)
        self.bottomBar
      }
      .background(WePLiColor.background.ignoresSafeArea())
    }
  }

  private var topBar: some View {
    HStack {
      Text("위플리 이용 가이드")
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.textPrimary)
        .padding(.leading, 8)
        .accessibilityAddTraits(.isHeader)
      Spacer()
      Button {
        self.store.send(.closeTapped)
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(WePLiColor.textMuted)
          .frame(width: 36, height: 36)
          .background(WePLiColor.secondaryButtonFill, in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("닫기")
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
  }

  private var bottomBar: some View {
    HStack {
      HStack(spacing: 6) {
        ForEach(ServiceGuidePage.all.indices, id: \.self) { index in
          let isCurrent = index == self.store.page
          Capsule()
            .fill(isCurrent ? WePLiColor.textPrimary : Color.white.opacity(0.3))
            .frame(width: isCurrent ? 18 : 6, height: 6)
            .onTapGesture { self.store.send(.pageChanged(index)) }
        }
      }
      .accessibilityElement()
      .accessibilityLabel("\(ServiceGuidePage.all.count)장 중 \(self.store.page + 1)번째")
      Spacer()
      Button {
        self.store.send(.nextTapped)
      } label: {
        Text(self.store.isLastPage ? "시작하기" : "다음")
          .wepliFont(.callout, weight: .semibold)
          .foregroundStyle(WePLiColor.textOnCTA)
          .padding(.horizontal, 26)
          .frame(height: 50)
          .background(WePLiGradient.cta, in: Capsule())
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 24)
    .padding(.top, 12)
    .padding(.bottom, 24)
  }
}

/// 한 장 — 이미지(380, 모서리 28) · 번호 · 제목 · 설명
private struct ServiceGuideCard: View {
  let page: ServiceGuidePage

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      // 미결정 — 원본 노트 02: 실제 화면(2a · 3b 등) 캡처로 바꿀 이미지. 지금은 자리 표시
      RoundedRectangle(cornerRadius: 28)
        .fill(WePLiColor.surface1)
        .overlay {
          LinearGradient(colors: [.black.opacity(0), .black.opacity(0.75)], startPoint: .center, endPoint: .bottom)
        }
        .overlay(alignment: .bottomLeading) {
          Text(self.page.id)
            .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 64, relativeTo: .largeTitle))
            .foregroundStyle(WePLiColor.accent)
            .padding(.leading, 20)
            .padding(.bottom, 18)
            .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .frame(height: 380)
      Text(self.page.title)
        .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 26, relativeTo: .title))
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      Text(self.page.body)
        .wepliFont(.body)
        .lineSpacing(6)
        .foregroundStyle(WePLiColor.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 24)
    .padding(.top, 8)
  }
}

#Preview {
  ServiceGuideView(store: Store(initialState: ServiceGuideFeature.State()) { ServiceGuideFeature() })
}
