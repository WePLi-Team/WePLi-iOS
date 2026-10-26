import ComposableArchitecture
import SwiftUI

// REQ-061 · UI-2b — 게시글 작성(큰 시트 안의 루트 화면)

struct ComposePostView: View {
  @Perception.Bindable var store: StoreOf<ComposePostFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        self.header
        List {
          Section {
            self.inputCard
              .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
          }
          Section {
            ForEach(self.store.tracks) { track in
              ComposeTrackRow(track: track) { self.store.send(.removeTrackTapped(track.id)) }
            }
            .onMove { self.store.send(.tracksMoved($0, $1)) }
            Button {
              self.store.send(.addSongTapped)
            } label: {
              Label("노래 추가하기", systemImage: "plus")
                .wepliFont(.body, weight: .semibold)
                .foregroundStyle(WePLiColor.accent)
                .frame(height: 50)
            }
          } header: {
            Text("노래 · 선택 · \(self.store.tracks.count)곡")
              .wepliFont(.subheadline, weight: .semibold)
              .foregroundStyle(WePLiColor.textPrimary)
              .textCase(nil)
          } footer: {
            Text("≡ 를 끌어 순서를 바꿀 수 있어요. 같은 곡은 한 번만 추가돼요.")
              .wepliFont(.caption)
              .foregroundStyle(WePLiColor.textQuaternary)
          }
          .listRowBackground(WePLiColor.surface3)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
      }
      .background(WePLiColor.surface1)
      .wepliToast(self.store.toast) { self.store.send(.toastDismissed) }
      .confirmationDialog(self.$store.scope(state: \.addSongDialog, action: \.addSongDialog))
      .sheet(item: self.$store.scope(state: \.picker, action: \.picker)) { pickerStore in
        SongPickerView(store: pickerStore)
          .wepliSheetStyle(detents: [.large])
      }
    }
  }

  private var header: some View {
    ZStack {
      Text("게시글 작성")
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      HStack {
        Button("취소") { self.store.send(.cancelButtonTapped) }
          .wepliFont(.button, weight: .regular)
          .foregroundStyle(WePLiColor.accent)
        Spacer()
        Button {
          self.store.send(.publishButtonTapped)
        } label: {
          Text("등록")
            .wepliFont(.body, weight: .semibold)
            .foregroundStyle(self.store.canPublish ? WePLiColor.textOnCTA : WePLiColor.textDisabled)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(self.store.canPublish ? WePLiColor.accent : WePLiColor.disabledFill, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!self.store.canPublish)
      }
    }
    .padding(.horizontal, 20)
    .frame(height: 56)
  }

  private var inputCard: some View {
    VStack(spacing: 0) {
      TextField("제목을 입력해주세요", text: self.$store.title.sending(\.titleChanged))
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.textPrimary)
        .padding(.horizontal, 16)
        .frame(height: 54)
      Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5).padding(.horizontal, 16)
      ZStack(alignment: .topLeading) {
        if self.store.body.isEmpty {
          Text("내용을 작성해주세요.")
            .wepliFont(.body)
            .foregroundStyle(WePLiColor.textDisabled)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .accessibilityHidden(true)
        }
        TextEditor(text: self.$store.body.sending(\.bodyChanged))
          .wepliFont(.body)
          .foregroundStyle(WePLiColor.textPrimary)
          .scrollContentBackground(.hidden)
          .padding(.horizontal, 11)
          .padding(.top, 6)
          .accessibilityLabel("내용")
      }
      .frame(height: 168)
      Text("\(self.store.body.count)/\(ComposeInput.bodyLimit)")
        .wepliFont(.caption)
        .foregroundStyle(WePLiColor.textDisabled)
        .monospacedDigit()
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    .background(WePLiColor.surface3, in: RoundedRectangle(cornerRadius: 18))
  }
}

struct ComposeTrackRow: View {
  let track: ComposeTrack
  let onRemove: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      RoundedRectangle(cornerRadius: 4).fill(WePLiColor.imagePlaceholder).frame(width: 44, height: 44)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        Text(self.track.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
        Text(self.track.artist).wepliFont(.footnote).foregroundStyle(WePLiColor.textQuaternary).lineLimit(1)
      }
    }
    .frame(height: 62)
    .swipeActions { Button("삭제", role: .destructive, action: self.onRemove) }
  }
}

#Preview {
  ComposePostView(store: Store(initialState: ComposePostFeature.State()) { ComposePostFeature() })
}
