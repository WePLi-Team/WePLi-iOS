import SwiftUI

// REQ-002 · 토스트 — 상단 중앙 44pt 캡슐, 체크 아이콘 #A4FFFF, 3초 유지 · 사라짐 200ms (모션 03)

enum WePLiToast {
  static let height: CGFloat = 44
  static let duration: Duration = .seconds(3)
}

struct WePLiToastView: View {
  let message: String

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "checkmark")
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(WePLiColor.positive)
      Text(self.message)
        .wepliFont(.subheadline, weight: .medium)
        .foregroundStyle(WePLiColor.textPrimary)
        .lineLimit(1)
    }
    .padding(.horizontal, 18)
    .frame(height: WePLiToast.height)
    .wepliGlass(in: Capsule())
    .accessibilityElement(children: .combine)
  }
}

private struct WePLiToastModifier: ViewModifier {
  @Binding var message: String?

  func body(content: Content) -> some View {
    content
      .overlay(alignment: .top) {
        if let message = self.message {
          WePLiToastView(message: message)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .task(id: message) {
              try? await Task.sleep(for: WePLiToast.duration)
              guard !Task.isCancelled else { return }
              withAnimation(.easeOut(duration: 0.2)) { self.message = nil }
            }
        }
      }
      .animation(.spring(response: 0.3, dampingFraction: 0.85), value: self.message)
  }
}

extension View {
  /// `message`에 문자열을 넣으면 토스트가 뜨고 3초 뒤 `nil`로 돌아간다.
  func wepliToast(_ message: Binding<String?>) -> some View {
    self.modifier(WePLiToastModifier(message: message))
  }

  /// store 상태로 띄우는 토스트 — 값은 body(WithPerceptionTracking 안)에서 읽고, 3초 뒤 `onDismiss`를 부른다.
  /// 바인딩 get에서 store를 읽으면 SwiftUI가 추적 밖에서 불러 Perception 경고가 나고 iOS 16에서 갱신되지 않는다.
  func wepliToast(_ message: String?, onDismiss: @escaping () -> Void) -> some View {
    self.wepliToast(Binding(get: { message }, set: {
      if $0 == nil {
        onDismiss()
      }
    }))
  }
}

#Preview {
  WePLiToastView(message: "‘밤편지’에 투표했어요")
    .padding(40)
    .background(WePLiColor.background)
}
