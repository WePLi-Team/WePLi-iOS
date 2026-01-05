import SwiftUI

// MARK: - InteractiveAlbumCarousel

struct InteractiveAlbumCarousel: View {
  let albumCount: Int

  private let baseSize: CGFloat = 60
  private let maxSize: CGFloat = 100
  private let spacing: CGFloat = 12

  var body: some View {
    GeometryReader { outerGeometry in
      let screenCenterX = outerGeometry.size.width / 2

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: spacing) {
          ForEach(0..<albumCount, id: \.self) { index in
            GeometryReader { geometry in
              let itemCenterX = geometry.frame(in: .global).midX
              let distanceFromCenter = abs(screenCenterX - itemCenterX)
              let scale = calculateScale(distance: distanceFromCenter)
              let size = baseSize * scale

              albumCoverView(index: index, size: size)
                .frame(width: baseSize, height: baseSize)
                .scaleEffect(scale)
                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: scale)
            }
            .frame(width: baseSize, height: maxSize)
          }
        }
        .padding(.horizontal, screenCenterX - baseSize / 2)
      }
    }
    .frame(height: maxSize + 20)
    .clipped()
  }

  private func calculateScale(distance: CGFloat) -> CGFloat {
    let maxDistance: CGFloat = 150
    let minScale: CGFloat = 1.0
    let maxScale: CGFloat = maxSize / baseSize

    let normalizedDistance = min(distance / maxDistance, 1.0)
    let scale = maxScale - (maxScale - minScale) * normalizedDistance

    return max(minScale, scale)
  }

  @ViewBuilder
  private func albumCoverView(index: Int, size: CGFloat) -> some View {
    let cornerRadius: CGFloat = size > 80 ? 12 : 8

    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(
        LinearGradient(
          colors: albumGradientColors(for: index),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .overlay {
        if index == 2 {
          Text("A NEW\nHOPE")
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
        }
      }
  }

  private func albumGradientColors(for index: Int) -> [Color] {
    let gradients: [[Color]] = [
      [
        Color(red: 40.0 / 255.0, green: 40.0 / 255.0, blue: 45.0 / 255.0),
        Color(red: 60.0 / 255.0, green: 60.0 / 255.0, blue: 65.0 / 255.0)
      ],
      [
        Color(red: 139.0 / 255.0, green: 90.0 / 255.0, blue: 43.0 / 255.0),
        Color(red: 89.0 / 255.0, green: 60.0 / 255.0, blue: 30.0 / 255.0)
      ],
      [
        Color(red: 75.0 / 255.0, green: 0.0 / 255.0, blue: 130.0 / 255.0),
        Color(red: 138.0 / 255.0, green: 43.0 / 255.0, blue: 226.0 / 255.0)
      ],
      [
        Color(red: 180.0 / 255.0, green: 30.0 / 255.0, blue: 30.0 / 255.0),
        Color(red: 100.0 / 255.0, green: 20.0 / 255.0, blue: 20.0 / 255.0)
      ],
      [
        Color(red: 50.0 / 255.0, green: 50.0 / 255.0, blue: 55.0 / 255.0),
        Color(red: 70.0 / 255.0, green: 70.0 / 255.0, blue: 75.0 / 255.0)
      ],
      [
        Color(red: 30.0 / 255.0, green: 30.0 / 255.0, blue: 35.0 / 255.0),
        Color(red: 50.0 / 255.0, green: 50.0 / 255.0, blue: 55.0 / 255.0)
      ]
    ]
    return gradients[index % gradients.count]
  }
}

// MARK: - Preview

#Preview {
  ZStack {
    Color.black
      .ignoresSafeArea()

    InteractiveAlbumCarousel(albumCount: 10)
  }
}
