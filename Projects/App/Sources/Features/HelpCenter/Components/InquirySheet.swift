import ComposableArchitecture
import PhotosUI
import SwiftUI

// UI-7b 1:1 문의 시트 — 유형(필수) · 내용(필수, 1000자) · 사진(최대 3장) · 답변 받는 곳(DEC-025) · 자동 첨부 안내 · 보내기
// 원본의 흰 선택 칩은 DEC-009(흰 바탕 버튼 금지)에 따라 라벤더 칩(WePLiChip)으로

struct InquirySheet: View {
  @Perception.Bindable var store: StoreOf<HelpCenterFeature>

  @State private var pickerItems: [PhotosPickerItem] = []

  var body: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: 16) {
        ZStack {
          Text("1:1 문의하기").wepliFont(.button).foregroundStyle(WePLiColor.textPrimary)
          HStack {
            Button("취소") { self.store.send(.composeDismissed) }
              .wepliFont(.button, weight: .regular)
              .foregroundStyle(WePLiColor.accent)
            Spacer()
          }
        }
        .frame(height: 44)
        .padding(.top, 8)
        self.categories
        self.textBox
        self.photos
        self.reply
        Text("문의를 보내면 앱 버전, 기기 모델, iOS 버전이 함께 전달돼요.")
          .wepliFont(.caption)
          .foregroundStyle(WePLiColor.textQuaternary)
          .padding(.horizontal, 4)
        Spacer(minLength: 0)
        WePLiPrimaryButton(title: "보내기", isEnabled: self.store.draft.canSend && !self.store.isSending) {
          self.store.send(.sendTapped)
        }
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 24)
      .task(id: self.pickerItems) { await self.loadPhotos() }
    }
  }

  /// 답변 받는 곳 — 앱 알림 · 내 문의 내역이 기본, 「이메일로도 받기」를 켜면 주소 칸
  private var reply: some View {
    VStack(spacing: 0) {
      HStack {
        Text("답변 받는 곳").foregroundStyle(WePLiColor.textQuaternary)
        Spacer()
        Text("앱 알림 · 내 문의 내역").foregroundStyle(WePLiColor.textPrimary)
      }
      .frame(height: 50)
      Divider().overlay(Color.white.opacity(0.08))
      Toggle(isOn: self.$store.draft.wantsEmail.sending(\.emailToggled)) {
        Text("이메일로도 받기").foregroundStyle(WePLiColor.textPrimary)
      }
      .tint(WePLiColor.accent)
      .frame(height: 50)
      if self.store.draft.wantsEmail {
        Divider().overlay(Color.white.opacity(0.08))
        TextField(
          "",
          text: self.$store.draft.email.sending(\.emailChanged),
          prompt: Text("받을 이메일 주소").foregroundColor(WePLiColor.textDisabled)
        )
        .foregroundStyle(WePLiColor.textPrimary)
        .keyboardType(.emailAddress)
        .textContentType(.emailAddress)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .frame(height: 50)
      }
    }
    .wepliFont(.subheadline)
    .padding(.horizontal, 16)
    .background(WePLiColor.surface3, in: RoundedRectangle(cornerRadius: 16))
    .animation(.easeOut(duration: 0.18), value: self.store.draft.wantsEmail)
  }

  private var categories: some View {
    // 칩 5개 — 두 줄로 나눠 둔다(작은 화면에서도 넘치지 않게)
    VStack(alignment: .leading, spacing: 8) {
      ForEach(
        [Array(InquiryCategory.allCases.prefix(3)), Array(InquiryCategory.allCases.dropFirst(3))],
        id: \.self
      ) { row in
        HStack(spacing: 8) {
          ForEach(row, id: \.self) { category in
            WePLiChip(title: category.title, isOn: self.store.draft.category == category) {
              self.store.send(.categorySelected(category))
            }
          }
        }
      }
    }
  }

  private var textBox: some View {
    VStack(alignment: .trailing, spacing: 0) {
      ZStack(alignment: .topLeading) {
        if self.store.draft.text.isEmpty {
          Text("어떤 점이 불편하셨나요? 화면과 상황을 자세히 적어주시면 더 빨리 도와드릴 수 있어요.")
            .wepliFont(.body)
            .foregroundStyle(WePLiColor.textDisabled)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .accessibilityHidden(true)
        }
        TextEditor(text: self.$store.draft.text.sending(\.textChanged))
          .wepliFont(.body)
          .foregroundStyle(WePLiColor.textPrimary)
          .scrollContentBackground(.hidden)
          .padding(.horizontal, 12)
          .padding(.top, 6)
          .accessibilityLabel("문의 내용")
      }
      .frame(height: 170)
      Text("\(self.store.draft.text.count)/\(InquiryDraft.textLimit)")
        .wepliFont(.caption)
        .monospacedDigit()
        .foregroundStyle(WePLiColor.textDisabled)
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }
    .background(WePLiColor.surface3, in: RoundedRectangle(cornerRadius: 18))
  }

  private var photos: some View {
    HStack(spacing: 8) {
      ForEach(Array(self.store.draft.photos.enumerated()), id: \.offset) { index, data in
        Group {
          if let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill()
          } else {
            WePLiColor.imagePlaceholder
          }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .topTrailing) {
          Button {
            self.store.send(.photoRemoved(index))
          } label: {
            Image(systemName: "xmark.circle.fill").font(.system(size: 18)).foregroundStyle(
              WePLiColor.textPrimary,
              .black.opacity(0.6)
            )
          }
          .padding(4)
          .accessibilityLabel("사진 \(index + 1) 빼기")
        }
      }
      let remaining = InquiryDraft.photoLimit - self.store.draft.photos.count
      if remaining > 0 {
        PhotosPicker(selection: self.$pickerItems, maxSelectionCount: remaining, matching: .images) {
          VStack(spacing: 2) {
            Image(systemName: "camera").font(.system(size: 18))
            Text("\(self.store.draft.photos.count)/\(InquiryDraft.photoLimit)").wepliFont(.caption)
          }
          .foregroundStyle(WePLiColor.textQuaternary)
          .frame(width: 72, height: 72)
          .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(
            Color.white.opacity(0.2),
            style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
          ))
        }
        .accessibilityLabel("사진 첨부, 최대 \(InquiryDraft.photoLimit)장")
      }
    }
  }

  private func loadPhotos() async {
    guard !self.pickerItems.isEmpty else { return }
    var loaded: [Data] = []
    for item in self.pickerItems {
      if let data = try? await item.loadTransferable(type: Data.self) {
        loaded.append(data)
      }
    }
    self.pickerItems = []
    self.store.send(.photosPicked(loaded))
  }
}
