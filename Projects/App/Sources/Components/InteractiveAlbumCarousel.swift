import Combine
import SwiftUI

// MARK: - InteractiveAlbumCarousel

struct InteractiveAlbumCarousel: View {
  let albumCount: Int
  var autoScrollInterval: TimeInterval = 3.0

  private let minSize: CGFloat = 60
  private let maxSize: CGFloat = 100
  private let spacing: CGFloat = 12

  @State private var currentIndex: Int = 0
  @State private var scrollTarget: Int?

  private let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()

  var body: some View {
    GeometryReader { outerGeometry in
      ScrollViewReader { scrollProxy in
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(alignment: .center, spacing: spacing) {
            ForEach(0..<albumCount, id: \.self) { index in
              AlbumItemView(
                index: index,
                focusedIndex: currentIndex + 1,
                minSize: minSize,
                maxSize: maxSize,
                gradientColors: albumGradientColors(for: index)
              )
              .id(index)
            }
          }
          .padding(.leading, 24)
          .padding(.trailing, outerGeometry.size.width - 24 - minSize)
        }
        .onReceive(timer) { _ in
          let nextIndex = (currentIndex + 1) % albumCount
          currentIndex = nextIndex
          withAnimation(.easeInOut(duration: 0.5)) {
            scrollProxy.scrollTo(nextIndex, anchor: .leading)
          }
        }
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
  let focusedIndex: Int
  let minSize: CGFloat
  let maxSize: CGFloat
  let gradientColors: [Color]

  private var isFocused: Bool {
    index == focusedIndex
  }

  private var currentSize: CGFloat {
    isFocused ? maxSize : minSize
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
      .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: currentSize)
  }
}

// MARK: - Preview

#Preview {
  ZStack {
    Color.black
      .ignoresSafeArea()

    InteractiveAlbumCarousel(albumCount: 10, autoScrollInterval: 2.0)
  }
}
