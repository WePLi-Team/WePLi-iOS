import SwiftUI

// MARK: - InteractiveAlbumCarousel

struct InteractiveAlbumCarousel: View {
  let albumCount: Int

  private let minSize: CGFloat = 60
  private let maxSize: CGFloat = 100
  private let spacing: CGFloat = 12

  var body: some View {
    GeometryReader { outerGeometry in
      let centerX = outerGeometry.size.width / 2

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .center, spacing: spacing) {
          ForEach(0..<albumCount, id: \.self) { index in
            AlbumItemView(
              index: index,
              screenCenterX: centerX,
              minSize: minSize,
              maxSize: maxSize,
              gradientColors: albumGradientColors(for: index)
            )
          }
        }
        .padding(.horizontal, (outerGeometry.size.width - minSize) / 2)
      }
    }
    .frame(height: maxSize)
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

// MARK: - AlbumItemView

private struct AlbumItemView: View {
  let index: Int
  let screenCenterX: CGFloat
  let minSize: CGFloat
  let maxSize: CGFloat
  let gradientColors: [Color]

  @State private var itemCenterX: CGFloat = 0

  private var distance: CGFloat {
    abs(screenCenterX - itemCenterX)
  }

  private var currentSize: CGFloat {
    let maxDistance: CGFloat = 120
    let normalizedDistance = min(distance / maxDistance, 1.0)
    let size = maxSize - (maxSize - minSize) * normalizedDistance
    return max(minSize, size)
  }

  var body: some View {
    let cornerRadius: CGFloat = currentSize > 80 ? 12 : 8

    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(
        LinearGradient(
          colors: gradientColors,
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .frame(width: currentSize, height: currentSize)
      .overlay {
        if index == 2 {
          Text("A NEW\nHOPE")
            .font(.system(size: 8 * (currentSize / minSize), weight: .bold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
        }
      }
      .background(
        GeometryReader { geometry in
          Color.clear
            .preference(
              key: CenterXPreferenceKey.self,
              value: geometry.frame(in: .global).midX
            )
        }
      )
      .onPreferenceChange(CenterXPreferenceKey.self) { value in
        itemCenterX = value
      }
      .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: currentSize)
  }
}

// MARK: - CenterXPreferenceKey

private struct CenterXPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = 0

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
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
