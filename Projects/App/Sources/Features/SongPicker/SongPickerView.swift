import ComposableArchitecture
import SwiftUI

// REQ-062 · UI-2a — 곡 검색 · 선택

struct SongPickerView: View {
  let store: StoreOf<SongPickerFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        self.header
        self.searchField
        ScrollView {
          if self.store.hasQuery {
            SongPickerResults(store: self.store)
          } else {
            SongPickerSuggestions(store: self.store)
          }
        }
        .scrollDismissesKeyboard(.interactively)
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        if !self.store.selectedTracks.isEmpty {
          SongPickerTray(tracks: self.store.selectedTracks) { self.store.send(.trackToggled($0)) } onAdd: {
            self.store.send(.addButtonTapped)
          }
        }
      }
      .background(WePLiColor.surface1)
      .wepliToast(Binding(get: { self.store.toast }, set: {
        if $0 == nil {
          self.store.send(.toastDismissed)
        }
      }))
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private var header: some View {
    ZStack {
      Text("곡 검색")
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      HStack {
        Button("취소") { self.store.send(.cancelButtonTapped) }
          .wepliFont(.button, weight: .regular)
          .foregroundStyle(WePLiColor.accent)
        Spacer()
      }
    }
    .padding(.horizontal, 20)
    .frame(height: 56)
  }

  private var searchField: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(WePLiColor.textQuaternary)
      TextField(
        "곡 이름이나 가수를 입력하세요",
        text: Binding(get: { self.store.query }, set: { self.store.send(.queryChanged($0)) })
      )
      .wepliFont(.callout)
      .foregroundStyle(WePLiColor.textPrimary)
      .submitLabel(.search)
      if !self.store.query.isEmpty {
        Button {
          self.store.send(.clearQueryTapped)
        } label: {
          Image(systemName: "xmark.circle.fill").foregroundStyle(WePLiColor.textDisabled)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("검색어 지우기")
      }
    }
    .padding(.horizontal, 14)
    .frame(height: 42)
    .background(WePLiColor.surface3, in: RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal, 20)
  }
}

#Preview {
  SongPickerView(store: Store(initialState: SongPickerFeature.State(query: "아이유")) { SongPickerFeature() })
}
