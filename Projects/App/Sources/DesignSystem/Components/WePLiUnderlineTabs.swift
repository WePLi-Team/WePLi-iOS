import SwiftUI

// 디자인 시스템 04 버튼 · 선택(2026-10-15) — 탭은 밑줄 텍스트, 선택은 칩. iOS 세그먼트 · 라디오는 설정 화면에서만(DEC-009)
// 밑줄 탭: 선택 17/700 + 밑줄 2 #C8CFFF · 꺼짐 17/500 #6B6B7C · 탭 간격 22 · 아래 패딩 10 · 바닥선 0.5 흰색 10%
// 칩: 높이 32 · 좌우 14 · 13 · 선택 rgba(200,207,255,0.16) + #C8CFFF 600 · 꺼짐 흰색 6% + #B5B5C0 · 간격 8

struct WePLiUnderlineTabs<Item: Hashable>: View {
  let items: [Item]
  let selected: Item
  let title: (Item) -> String
  let onSelect: (Item) -> Void

  var body: some View {
    HStack(spacing: 22) {
      ForEach(self.items, id: \.self) { item in
        let isOn = item == self.selected
        Button {
          self.onSelect(item)
        } label: {
          Text(self.title(item))
            .wepliFont(.button, weight: isOn ? .bold : .medium)
            .foregroundStyle(isOn ? WePLiColor.textPrimary : WePLiColor.textDisabled)
            .monospacedDigit()
            .padding(.bottom, 10)
            .overlay(alignment: .bottom) {
              if isOn {
                Rectangle().fill(WePLiColor.accent).frame(height: 2)
              }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
      }
      Spacer(minLength: 0)
    }
    .overlay(alignment: .bottom) {
      Rectangle().fill(Color.white.opacity(0.1)).frame(height: 0.5)
    }
    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: self.selected)
  }
}

struct WePLiChip: View {
  let title: String
  let isOn: Bool
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      Text(self.title)
        .wepliFont(.footnote, weight: self.isOn ? .semibold : .regular)
        .foregroundStyle(self.isOn ? WePLiColor.accent : WePLiColor.textSecondary)
        .padding(.horizontal, 14)
        .frame(height: 32)
        .background(self.isOn ? WePLiColor.chipOn : WePLiColor.chipOff, in: Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(self.isOn ? [.isButton, .isSelected] : .isButton)
  }
}

#Preview {
  VStack(spacing: 24) {
    WePLiUnderlineTabs(items: ["내 플리", "참여한 릴레이", "좋아요"], selected: "참여한 릴레이", title: { $0 }, onSelect: { _ in })
    HStack(spacing: 8) {
      WePLiChip(title: "1일", isOn: false) {}
      WePLiChip(title: "3일", isOn: true) {}
    }
  }
  .padding()
  .background(WePLiColor.background)
}
