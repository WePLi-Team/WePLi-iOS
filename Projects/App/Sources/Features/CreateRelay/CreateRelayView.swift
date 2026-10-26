import ComposableArchitecture
import SwiftUI

// REQ-036 · UI-6a — 릴레이리스트 만들기(시트). 취소 · 제목 · 만들기 내비, 아래로 미리보기 → 커버 → 입력 → 기간 → 투표 방식 → 첫 곡 → 참여 범위

struct CreateRelayView: View {
  @Perception.Bindable var store: StoreOf<CreateRelayFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        self.navigationBar
        ScrollView {
          VStack(alignment: .leading, spacing: 22) {
            CreateRelayPreview(relay: self.store.relay)
            self.section("커버") {
              CreateRelayCoverPicker(
                selected: self.store.relay.cover,
                onSelect: { self.store.send(.coverSelected($0)) },
                onAddPhoto: { self.store.send(.addPhotoTapped) }
              )
            }
            self.inputs
            self.section("진행 기간") {
              CreateRelayDurationPicker(selected: self.store.relay.duration) { self.store.send(.durationSelected($0)) }
            }
            self.section("투표 방식") {
              CreateRelayVoteFormatPicker(selected: self.store.relay.voteFormat) {
                self.store.send(.voteFormatSelected($0))
              }
            }
            self.firstSong
            self.audience
          }
          .padding(.horizontal, 16)
          .padding(.bottom, 48)
        }
        .scrollDismissesKeyboard(.interactively)
      }
      .background(WePLiColor.surface1)
      .wepliToast(self.store.toast) { self.store.send(.toastDismissed) }
      .sheet(item: self.$store.scope(state: \.picker, action: \.picker)) { pickerStore in
        SongPickerView(store: pickerStore)
          .wepliSheetStyle(detents: [.large])
      }
    }
  }

  private var navigationBar: some View {
    ZStack {
      Text("릴레이리스트 만들기")
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      HStack {
        Button("취소") { self.store.send(.cancelTapped) }
          .wepliFont(.button, weight: .regular)
          .foregroundStyle(WePLiColor.accent)
          .padding(10)
        Spacer()
        Button {
          self.store.send(.createTapped)
        } label: {
          Text("만들기")
            .wepliFont(.subheadline, weight: .semibold)
            .foregroundStyle(self.store.canCreate ? WePLiColor.textOnCTA : WePLiColor.textDisabled)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(self.store.canCreate ? WePLiColor.accent : WePLiColor.disabledFill, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!self.store.canCreate)
      }
    }
    .padding(.horizontal, 10)
    .padding(.top, 14)
    .padding(.bottom, 12)
  }

  private var inputs: some View {
    VStack(spacing: 0) {
      HStack {
        TextField(
          "주제 (예: 비 오는 날 생각나는 노래)",
          text: self.$store.relay.topic.sending(\.topicChanged)
        )
        .wepliFont(.callout, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
        .tint(WePLiColor.accent)
        Text("\(self.store.relay.topic.count)/\(NewRelay.topicLimit)")
          .wepliFont(.caption)
          .monospacedDigit()
          .foregroundStyle(WePLiColor.textDisabled)
      }
      .padding(.leading, 16)
      .padding(.trailing, 14)
      .frame(height: 54)
      Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5).padding(.leading, 16)
      TextField(
        "한 줄 설명 (선택)",
        text: self.$store.relay.description.sending(\.descriptionChanged)
      )
      .wepliFont(.body)
      .foregroundStyle(WePLiColor.textMuted)
      .tint(WePLiColor.accent)
      .padding(.horizontal, 16)
      .frame(height: 50)
    }
    .background(WePLiColor.surface3, in: RoundedRectangle(cornerRadius: 18))
  }

  private var firstSong: some View {
    VStack(alignment: .leading, spacing: 8) {
      (Text("첫 곡 ") + Text("*").foregroundColor(WePLiColor.accentStrong))
        .wepliFont(.subheadline, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
        .padding(.horizontal, 4)
        .accessibilityLabel("첫 곡, 필수")
      CreateRelayFirstSong(song: self.store.relay.firstSong) { self.store.send(.firstSongTapped) }
    }
  }

  private var audience: some View {
    VStack(alignment: .leading, spacing: 8) {
      self.label("누가 참여할 수 있나요")
      CreateRelayAudiencePicker(selected: self.store.relay.audience) { self.store.send(.audienceSelected($0)) }
      Text("기간이 끝나면 투표 결과 순서대로 플레이리스트가 완성되고, 참여한 모든 사람에게 알려드려요.")
        .wepliFont(.caption)
        .foregroundStyle(WePLiColor.textQuaternary)
        .padding(.horizontal, 4)
    }
  }

  private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      self.label(title)
      content()
    }
  }

  private func label(_ text: String) -> some View {
    Text(text)
      .wepliFont(.subheadline, weight: .semibold)
      .foregroundStyle(WePLiColor.textPrimary)
      .padding(.horizontal, 4)
      .accessibilityAddTraits(.isHeader)
  }
}

#Preview {
  Color.black.sheet(isPresented: .constant(true)) {
    CreateRelayView(store: Store(initialState: CreateRelayFeature.State()) {
      CreateRelayFeature()
    })
    .wepliSheetStyle(detents: [.large])
  }
}
