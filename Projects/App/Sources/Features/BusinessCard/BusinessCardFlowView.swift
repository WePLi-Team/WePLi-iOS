import ComposableArchitecture
import SwiftUI

// REQ-075 · UI-2e — 명함 만들기(전체 화면). 좌표는 원본(402×874, 화면 위 기준)을 그대로 쓴다.
// 카드는 소개 · 생성 · 완성 단계에서 보이고, 단계마다 위치 · 기울기 · 크기가 0.6초에 걸쳐 바뀐다.

struct BusinessCardFlowView: View {
  @Perception.Bindable var store: StoreOf<BusinessCardFeature>

  @FocusState private var isEditing: Bool

  var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        WePLiColor.background
        self.content()
        if let placement = CardPlacement(step: self.store.step) {
          BusinessCardView(card: self.store.card, isBlurred: self.store.step == .generating)
            .shadow(color: .black.opacity(0.6), radius: 40, y: 30)
            .rotationEffect(.degrees(placement.rotation))
            .scaleEffect(placement.scale)
            .padding(.top, placement.top)
            .allowsHitTesting(false)
            .transition(.opacity)
        }
        self.topBar()
      }
      .ignoresSafeArea()
      .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.6), value: self.store.step)
      .wepliToast(self.store.toast) { self.store.send(.toastDismissed) }
      .sheet(item: self.$store.scope(state: \.picker, action: \.picker)) { pickerStore in
        SongPickerView(store: pickerStore)
          .wepliSheetStyle(detents: [.large])
      }
      .sheet(isPresented: Binding(
        get: { [isPresented = self.store.isShareSheetPresented] in isPresented },
        set: {
          if !$0 {
            self.store.send(.shareSheetDismissed)
          }
        }
      )) {
        BusinessCardShareSheet(
          onItem: { self.store.send(.shareItemTapped($0, image: BusinessCardView.png(self.store.card))) },
          onClose: { self.store.send(.shareSheetDismissed) }
        )
        .wepliSheetStyle(detents: [.height(BusinessCardShareSheet.height)])
      }
      .sheet(item: Binding(
        get: { [systemShare = self.store.systemShare] in systemShare },
        set: {
          if $0 == nil {
            self.store.send(.systemShareDismissed)
          }
        }
      )) { item in
        ActivityView(item: item)
      }
    }
  }

  @ViewBuilder
  private func topBar() -> some View {
    if self.store.step.showsNavigation {
      CardStepNavigation(
        step: self.store.step,
        onBack: { self.store.send(.backTapped) },
        onClose: { self.store.send(.closeTapped) }
      )
      .padding(.horizontal, 16)
      .padding(.top, 58)
    } else if self.store.step == .intro {
      // 원본 소개 단계에는 나가는 버튼이 없다 — 전체 화면이라 닫기만 둔다(디자인 확인 필요)
      HStack {
        Spacer()
        WePLiIconButton(systemName: "xmark", accessibilityLabel: "닫기") { self.store.send(.closeTapped) }
      }
      .padding(.horizontal, 16)
      .padding(.top, 58)
    }
  }

  @ViewBuilder
  private func content() -> some View {
    switch self.store.step {
    case .intro: self.introStep
    case .song: self.songStep
    case .oneLiner: self.oneLinerStep
    case .instagram: self.instagramStep
    case .generating: self.generatingStep
    case .done: self.doneStep
    }
  }

  private var introStep: some View {
    VStack(spacing: 30) {
      Spacer()
      VStack(spacing: 8) {
        Text("내 취향 명함 만들기")
          .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 28, relativeTo: .title))
          .foregroundStyle(WePLiColor.textPrimary)
        Text("\(self.store.nickname)님의 취향이 드러나는 명함을 만들어드려요")
          .wepliFont(.body)
          .foregroundStyle(WePLiColor.textSecondary)
      }
      .multilineTextAlignment(.center)
      CardStepButton(title: "시작하기", isEnabled: true) { self.store.send(.startTapped) }
    }
    .padding(EdgeInsets(top: 0, leading: 24, bottom: 42, trailing: 24))
  }

  private var songStep: some View {
    VStack(spacing: 0) {
      CardStepTitle(
        title: "가장 좋아하는 노래 1곡을\n선택해 주세요",
        message: "선택한 노래는 명함에 추가되어 다른 사람들에게 보여질거예요"
      )
      Spacer()
      CardSongPicker(song: self.store.song) { self.store.send(.songAreaTapped) }
      Spacer()
      CardStepButton(title: "선택완료", isEnabled: self.store.song != nil) { self.store.send(.songConfirmed) }
    }
    .padding(EdgeInsets(top: 122, leading: 24, bottom: 42, trailing: 24))
  }

  private var oneLinerStep: some View {
    VStack(spacing: 0) {
      CardStepTitle(title: "한 줄 소개를 입력해주세요", message: "\(self.store.nickname)님을 잘 나타내는 문장을 입력해주세요")
      CardUnderlineField(placeholder: "문구를 작성해주세요.", text: self.store.oneLiner) {
        self.store.send(.oneLinerChanged($0))
      }
      .focused(self.$isEditing)
      .padding(.top, 44)
      Spacer()
      CardStepButton(title: "입력완료", isEnabled: BusinessCardInput.hasText(self.store.oneLiner)) {
        self.store.send(.oneLinerConfirmed)
      }
    }
    .padding(EdgeInsets(top: 122, leading: 24, bottom: 42, trailing: 24))
    .onAppear { self.isEditing = true }
  }

  private var instagramStep: some View {
    VStack(spacing: 0) {
      CardStepTitle(
        title: "Instagram 계정을 입력해주세요",
        message: "명함에 표시될 SNS 계정을 입력해주세요\n계정 입력을 원하지 않으면 건너뛸 수 있어요"
      )
      CardUnderlineField(placeholder: "계정을 입력해주세요", text: self.store.instagram, prefix: "@") {
        self.store.send(.instagramChanged($0))
      }
      .focused(self.$isEditing)
      .textInputAutocapitalization(.never)
      .keyboardType(.asciiCapable)
      .padding(.top, 44)
      Spacer()
      CardStepButton(title: "입력완료", isEnabled: BusinessCardInput.hasText(self.store.instagram)) {
        self.store.send(.instagramConfirmed)
      }
      CardTextButton(title: "건너뛰기") { self.store.send(.skipTapped) }
        .padding(.top, 4)
    }
    .padding(EdgeInsets(top: 122, leading: 24, bottom: 30, trailing: 24))
  }

  private var generatingStep: some View {
    VStack(spacing: 0) {
      VStack(spacing: 8) {
        Text("위플리가 명함을 만드는 중이에요")
          .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 24, relativeTo: .title2))
          .foregroundStyle(WePLiColor.textPrimary)
        Text("조금만 기다리면 근사한 명함을 만들어드릴게요!")
          .wepliFont(.subheadline)
          .foregroundStyle(WePLiColor.textTertiary)
      }
      .multilineTextAlignment(.center)
      Spacer()
      Text("\(self.store.percent)%")
        .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 36, relativeTo: .largeTitle))
        .monospacedDigit()
        .foregroundStyle(WePLiColor.textPrimary)
      // GeometryReader 내용은 body 밖에서 그려지므로 진행률은 미리 읽어 둔다
      let fraction = CGFloat(self.store.percent) / 100
      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          Capsule().fill(Color.white.opacity(0.1))
          Capsule().fill(WePLiColor.accent).frame(width: proxy.size.width * fraction)
        }
      }
      .frame(height: 6)
      .padding(.top, 14)
      .animation(.linear(duration: 0.1), value: self.store.percent)
      .accessibilityHidden(true)
    }
    .padding(EdgeInsets(top: 122, leading: 24, bottom: 64, trailing: 24))
  }

  private var doneStep: some View {
    VStack(spacing: 4) {
      Text("명함이 완성되었어요!")
        .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 26, relativeTo: .title))
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      Spacer()
      CardStepButton(title: "공유하기", systemImage: "square.and.arrow.up", isEnabled: true) {
        self.store.send(.shareTapped)
      }
      CardTextButton(title: "나가기") { self.store.send(.closeTapped) }
    }
    .padding(EdgeInsets(top: 116, leading: 24, bottom: 30, trailing: 24))
  }
}

/// 단계별 카드 자리 — 원본 top · rotate · scale
private struct CardPlacement {
  let top: CGFloat
  let rotation: Double
  let scale: CGFloat

  init?(step: BusinessCardStep) {
    switch step {
    case .intro: (self.top, self.rotation, self.scale) = (176, -6, 1)
    case .generating: (self.top, self.rotation, self.scale) = (236, 0, 0.92)
    case .done: (self.top, self.rotation, self.scale) = (214, 0, 1.12)
    case .song, .oneLiner, .instagram: return nil
    }
  }
}

#Preview {
  BusinessCardFlowView(store: Store(initialState: BusinessCardFeature.State(
    nickname: "김동",
    persona: "멜로디 메모리즈",
    today: .now
  )) {
    BusinessCardFeature()
  })
}
