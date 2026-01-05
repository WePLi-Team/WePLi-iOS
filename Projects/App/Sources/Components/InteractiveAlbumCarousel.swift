import Combine
import SwiftUI

// MARK: - InteractiveAlbumCarousel

struct InteractiveAlbumCarousel: View {
  let albumImages: [ImageAsset]
  var autoScrollInterval: TimeInterval = 3.0

  private let minSize: CGFloat = 60
  private let maxSize: CGFloat = 100
  private let spacing: CGFloat = 12

  /// 무한 스크롤을 위해 원본 데이터를 복제한 횟수
  private let repeatCount: Int = 100

  @State private var currentIndex: Int = 0
  @State private var isInitialized: Bool = false

  private let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()

  /// 무한 스크롤을 위해 복제된 전체 아이템 배열
  private var extendedItems: [(index: Int, imageAsset: ImageAsset)] {
    guard !albumImages.isEmpty else { return [] }
    return (0 ..< albumImages.count * repeatCount).map { index in
      (index: index, imageAsset: albumImages[index % albumImages.count])
    }
  }

  /// 무한 스크롤 시작 위치 (중간)
  private var startIndex: Int {
    guard !albumImages.isEmpty else { return 0 }
    return (repeatCount / 2) * albumImages.count
  }

  var body: some View {
    GeometryReader { outerGeometry in
      ScrollViewReader { scrollProxy in
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(alignment: .center, spacing: spacing) {
            ForEach(extendedItems, id: \.index) { item in
              AlbumItemView(
                index: item.index,
                focusedIndex: currentIndex + 1,
                minSize: minSize,
                maxSize: maxSize,
                imageAsset: item.imageAsset
              )
              .id(item.index)
            }
          }
          .padding(.leading, 24)
          .padding(.trailing, outerGeometry.size.width - 24 - minSize)
        }
        .onAppear {
          guard !isInitialized else { return }
          isInitialized = true
          currentIndex = startIndex
          scrollProxy.scrollTo(startIndex, anchor: .leading)
        }
        .onReceive(timer) { _ in
          guard isInitialized else { return }
          let nextIndex = currentIndex + 1
          currentIndex = nextIndex
          withAnimation(.easeInOut(duration: 0.5)) {
            scrollProxy.scrollTo(nextIndex, anchor: .leading)
          }
        }
      }
    }
    .frame(height: maxSize)
  }
}

// MARK: - AlbumItemView

private struct AlbumItemView: View {
  let index: Int
  let focusedIndex: Int
  let minSize: CGFloat
  let maxSize: CGFloat
  let imageAsset: ImageAsset

  private var isFocused: Bool {
    index == focusedIndex
  }

  private var currentSize: CGFloat {
    isFocused ? maxSize : minSize
  }

  var body: some View {
    let cornerRadius: CGFloat = currentSize > 80 ? 12 : 8

    imageAsset.swiftUIImage
      .resizable()
      .aspectRatio(contentMode: .fill)
      .frame(width: currentSize, height: currentSize)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: currentSize)
  }
}

// MARK: - Preview

#Preview {
  ZStack {
    Color.black
      .ignoresSafeArea()

    InteractiveAlbumCarousel(
      albumImages: [
        Asset.Assets.album1,
        Asset.Assets.album2,
        Asset.Assets.album3,
        Asset.Assets.album4,
        Asset.Assets.album1,
        Asset.Assets.album2,
        Asset.Assets.album3,
        Asset.Assets.album4,
      ],
      autoScrollInterval: 2.0
    )
  }
}
