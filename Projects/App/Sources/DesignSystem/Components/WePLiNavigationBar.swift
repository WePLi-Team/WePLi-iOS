import SwiftUI

// REQ-002 · push 화면 상단 바 — 가운데 제목 · 왼쪽 뒤로 · 오른쪽 버튼(선택). 높이 48 · 좌우 16.
// 배경은 화면마다 달라 부르는 쪽에서 붙인다.

struct WePLiNavigationBar<Trailing: View>: View {
  static var height: CGFloat {
    48
  }

  let title: String
  let onBack: () -> Void
  let trailing: Trailing

  /// `trailing`은 여기서 바로 만든다 — 하위 뷰 body에서 부르면 store를 Perception 추적 밖에서 읽게 된다(#216)
  init(title: String, onBack: @escaping () -> Void, @ViewBuilder trailing: () -> Trailing) {
    self.title = title
    self.onBack = onBack
    self.trailing = trailing()
  }

  var body: some View {
    ZStack {
      Text(self.title)
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      HStack {
        WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로", action: self.onBack)
        Spacer()
        self.trailing
      }
    }
    .padding(.horizontal, 16)
    .frame(height: Self.height)
  }
}

extension WePLiNavigationBar where Trailing == EmptyView {
  init(title: String, onBack: @escaping () -> Void) {
    self.init(title: title, onBack: onBack) { EmptyView() }
  }
}

#Preview {
  VStack {
    WePLiNavigationBar(title: "알림 설정") {}
    WePLiNavigationBar(title: "게시글") {} trailing: {
      WePLiIconButton(systemName: "ellipsis", accessibilityLabel: "더보기") {}
    }
  }
  .background(WePLiColor.background)
}
