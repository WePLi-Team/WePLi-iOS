import ComposableArchitecture
import SwiftUI

// UI-2a 최근 · 급상승 검색어, 결과, 하단 선택 트레이

struct SongPickerSuggestions: View {
  let store: StoreOf<SongPickerFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Text("최근 검색어").wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
          Spacer()
          if !self.store.recent.isEmpty {
            Button("전체삭제") { self.store.send(.clearRecentTapped) }
              .wepliFont(.footnote)
              .foregroundStyle(WePLiColor.textQuaternary)
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 26)
        .padding(.bottom, 12)
        if self.store.recent.isEmpty {
          Text("최근 검색어가 없어요")
            .wepliFont(.subheadline)
            .foregroundStyle(WePLiColor.textQuaternary)
            .padding(.horizontal, 20)
        } else {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
              ForEach(self.store.recent, id: \.self) { term in
                self.recentChip(term)
              }
            }
            .padding(.horizontal, 20)
          }
        }
        self.trending
      }
    }
  }

  private func recentChip(_ term: String) -> some View {
    HStack(spacing: 6) {
      Button(term) { self.store.send(.suggestionTapped(term)) }
        .wepliFont(.subheadline)
        .foregroundStyle(WePLiColor.textMuted)
      Button {
        self.store.send(.removeRecentTapped(term))
      } label: {
        Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundStyle(WePLiColor.textDisabled)
      }
      .accessibilityLabel("\(term) 삭제")
    }
    .buttonStyle(.plain)
    .padding(.horizontal, 14)
    .frame(height: 34)
    .background(WePLiColor.surface3, in: Capsule())
  }

  private var trending: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("급상승 검색어")
        .wepliFont(.callout, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
        .padding(.horizontal, 20)
        .padding(.top, 34)
        .padding(.bottom, 10)
      // 2열, 세로로 채운다(UI-2a)
      let half = (self.store.trending.count + 1) / 2
      HStack(alignment: .top, spacing: 12) {
        ForEach([0, 1], id: \.self) { column in
          VStack(spacing: 0) {
            ForEach(Array(self.store.trending.enumerated()), id: \.offset) { index, term in
              if (index < half) == (column == 0) {
                Button {
                  self.store.send(.suggestionTapped(term))
                } label: {
                  HStack(spacing: 12) {
                    Text("\(index + 1)")
                      .wepliFont(.body, weight: index < 3 ? .bold : .semibold)
                      .foregroundStyle(index < 3 ? WePLiColor.accent : WePLiColor.textQuaternary)
                      .monospacedDigit()
                      .frame(width: 20)
                    Text(term).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
                    Spacer(minLength: 0)
                  }
                  .frame(height: 46)
                  .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
              }
            }
          }
          .frame(maxWidth: .infinity)
        }
      }
      .padding(.horizontal, 20)
    }
  }
}

struct SongPickerResults: View {
  let store: StoreOf<SongPickerFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: 0) {
        if !self.store.isSearching, self.store.results.isEmpty {
          VStack(spacing: 8) {
            Text("검색 결과가 없어요").wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
            Text("곡 이름이나 가수 이름을 다시 확인해 주세요")
              .wepliFont(.subheadline)
              .foregroundStyle(WePLiColor.textQuaternary)
          }
          .frame(maxWidth: .infinity)
          .padding(.top, 60)
        } else {
          HStack {
            Text("‘\(self.store.query)’ 검색 결과").wepliFont(.callout, weight: .semibold)
              .foregroundStyle(WePLiColor.textPrimary)
            Spacer()
            Text("\(self.store.results.count)곡").wepliFont(.footnote).foregroundStyle(WePLiColor.textQuaternary)
          }
          .padding(.horizontal, 20)
          .padding(.top, 20)
          .padding(.bottom, 6)
          ForEach(self.store.results) { track in
            self.row(track)
          }
        }
      }
      .padding(.bottom, 24)
    }
  }

  private func row(_ track: ComposeTrack) -> some View {
    let isOn = self.store.selectedIDs.contains(track.id)
    return Button {
      self.store.send(.trackToggled(track.id))
    } label: {
      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 4).fill(WePLiColor.surface4).frame(width: 48, height: 48)
        VStack(alignment: .leading, spacing: 2) {
          Text(track.title)
            .wepliFont(.body, weight: isOn ? .semibold : .regular)
            .foregroundStyle(isOn ? WePLiColor.accent : WePLiColor.textPrimary)
            .lineLimit(1)
          Text(track.artist).wepliFont(.footnote).foregroundStyle(WePLiColor.textQuaternary).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        Group {
          if isOn {
            Image(systemName: "checkmark")
              .font(.system(size: 11, weight: .heavy))
              .foregroundStyle(WePLiColor.textOnCTA)
              .frame(width: 24, height: 24)
              .background(WePLiColor.accent, in: Circle())
          } else {
            Circle().strokeBorder(Color.white.opacity(0.28), lineWidth: 1.5).frame(width: 24, height: 24)
          }
        }
        .accessibilityHidden(true)
      }
      .padding(.horizontal, 20)
      .frame(height: 64)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
  }
}

struct SongPickerTray: View {
  let tracks: [ComposeTrack]
  let onRemove: (ComposeTrack.ID) -> Void
  let onAdd: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("선택한 노래 \(self.tracks.count)곡")
        .wepliFont(.subheadline, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 10) {
          ForEach(self.tracks) { track in
            RoundedRectangle(cornerRadius: 8).fill(WePLiColor.surface4).frame(width: 52, height: 52)
              .overlay(alignment: .topTrailing) {
                Button {
                  self.onRemove(track.id)
                } label: {
                  Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(WePLiColor.textPrimary, WePLiColor.surface2)
                }
                .buttonStyle(.plain)
                .offset(x: 6, y: -6)
                .accessibilityLabel("\(track.title) 빼기")
              }
          }
        }
        .padding(.top, 6)
      }
      WePLiPrimaryButton(title: "\(self.tracks.count)곡 추가하기", action: self.onAdd)
    }
    .padding(.horizontal, 16)
    .padding(.top, 14)
    .padding(.bottom, 8)
    .background(.ultraThinMaterial)
    .background(WePLiColor.trayBackground)
    .clipShape(UnevenRoundedRectangleShape(radius: 28))
  }
}

/// 위쪽 두 모서리만 둥근 모양(iOS 16 대응 — UnevenRoundedRectangle은 iOS 17+)
struct UnevenRoundedRectangleShape: Shape {
  let radius: CGFloat

  func path(in rect: CGRect) -> Path {
    Path(
      UIBezierPath(
        roundedRect: rect,
        byRoundingCorners: [.topLeft, .topRight],
        cornerRadii: CGSize(width: self.radius, height: self.radius)
      ).cgPath
    )
  }
}
