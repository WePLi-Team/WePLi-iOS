import SwiftUI

// UI-10d 곡 행 — 높이 62 · 커버 44(모서리 4) · 제목 15 · 가수 13 흰색 70%
// 보기: 오른쪽 ··· · 편집: 왼쪽 빨간 − 22, 오른쪽 ▲▼(12, #8E8E99)

struct MyPlaylistTrackRow: View {
  let track: ComposeTrack
  let isEditing: Bool
  let send: (MyPlaylistFeature.Action) -> Void

  var body: some View {
    HStack(spacing: 12) {
      if self.isEditing {
        Button {
          self.send(.removeTapped(self.track.id))
        } label: {
          Circle()
            .fill(WePLiColor.destructive)
            .frame(width: 22, height: 22)
            .overlay(Capsule().fill(.white).frame(width: 10, height: 2))
            .frame(width: 28, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(self.track.title) 빼기")
        .transition(.move(edge: .leading).combined(with: .opacity))
      }
      RoundedRectangle(cornerRadius: 4)
        .fill(WePLiColor.imagePlaceholder)
        .frame(width: 44, height: 44)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 0) {
        Text(self.track.title)
          .wepliFont(.body)
          .foregroundStyle(WePLiColor.textPrimary)
        Text(self.track.artist)
          .wepliFont(.footnote)
          .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
      }
      .lineLimit(1)
      .frame(maxWidth: .infinity, alignment: .leading)
      if self.isEditing {
        VStack(spacing: 2) {
          self.moveButton("chevron.up", label: "위로") { self.send(.moveUpTapped(self.track.id)) }
          self.moveButton("chevron.down", label: "아래로") { self.send(.moveDownTapped(self.track.id)) }
        }
      } else {
        Button {
          self.send(.trackMenuTapped(self.track.id))
        } label: {
          HStack(spacing: 3) {
            ForEach(0 ..< 3, id: \.self) { _ in
              Circle().fill(WePLiColor.tabInactiveGlass).frame(width: 4, height: 4)
            }
          }
          .frame(width: 36, height: 44)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(self.track.title) 더보기")
      }
    }
    .padding(.leading, 20)
    .padding(.trailing, 12)
    .frame(height: 62)
  }

  private func moveButton(_ systemName: String, label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(WePLiColor.textQuaternary)
        .frame(width: 32, height: 20)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(self.track.title) \(label)")
  }
}
