import SwiftUI

struct MainAppBar: View {
  let topSafeArea: CGFloat
  let onSearchTapped: () -> Void
  let onNotificationTapped: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      Spacer()
        .frame(height: topSafeArea)

      HStack {
        // 로고
        Text("w.")
          .font(.system(size: 24, weight: .bold))
          .foregroundColor(.white)

        Spacer()

        // 검색 버튼
        Button(action: onSearchTapped) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 20))
            .foregroundColor(.white)
        }
        .frame(width: 40, height: 40)

        // 알림 버튼
        Button(action: onNotificationTapped) {
          ZStack(alignment: .topTrailing) {
            Image(systemName: "bell")
              .font(.system(size: 20))
              .foregroundColor(.white)

            Circle()
              .fill(Color.red)
              .frame(width: 5, height: 5)
              .offset(x: 2, y: -2)
          }
        }
        .frame(width: 40, height: 40)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)

      Spacer()
    }
  }
}
