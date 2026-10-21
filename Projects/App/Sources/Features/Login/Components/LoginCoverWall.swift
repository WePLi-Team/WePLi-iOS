import SwiftUI

// UI-16d 「흐르는 커버 벽」 — 앨범 커버 세 줄이 천천히 흐르고 가운데 줄만 반대 방향.
// y300 아래는 점진 블러와 검정 그라디언트로 녹인다. 동작 줄이기면 멈춘다(16d 노트).
// 원본 커버 21장(img/c1 …)은 앱에 없어 번들된 앨범 아트 4장을 줄마다 다른 순서로 돌려 쓴다.

struct LoginCoverWall: View {
  @Environment(\.accessibilityReduceMotion)
  private var reduceMotion

  enum Metric {
    static let tile: CGFloat = 130
    static let gap: CGFloat = 6
    static let tilesPerColumn = 7
    /// 한 벌(7장) 높이 — 두 벌을 이어 붙여 이만큼 흐르면 처음과 같아진다
    static let loop = CGFloat(tilesPerColumn) * (tile + gap)
    static let fadeTop: CGFloat = 300
    static let topScrim: CGFloat = 140
    static let blur: CGFloat = 20
  }

  /// 원본 줄 A · B · C — 위로 70초 · 아래로 60초 · 위로 84초, C는 64 위에서 시작
  private static let columns: [Column] = [
    Column(duration: 70, isUpward: true, top: 0, offset: 0),
    Column(duration: 60, isUpward: false, top: 0, offset: 1),
    Column(duration: 84, isUpward: true, top: -64, offset: 2),
  ]

  var body: some View {
    TimelineView(.animation(paused: self.reduceMotion)) { context in
      let time = self.reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
      ZStack(alignment: .top) {
        self.wall(at: time)
        self.wall(at: time)
          .blur(radius: Metric.blur)
          .mask(Self.blurMask)
      }
    }
    .overlay { Self.shade }
    .clipped()
    .ignoresSafeArea()
    .accessibilityHidden(true)
  }

  private func wall(at time: TimeInterval) -> some View {
    HStack(alignment: .top, spacing: Metric.gap) {
      ForEach(Self.columns.indices, id: \.self) { index in
        Self.columns[index].view(at: time)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }

  /// y300부터 40% 지점까지 블러가 차오른다
  private static var blurMask: some View {
    VStack(spacing: 0) {
      Color.clear.frame(height: Metric.fadeTop)
      LinearGradient(
        stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.4)],
        startPoint: .top,
        endPoint: .bottom
      )
    }
  }

  /// 전체 0.3 어둡게 · 위 140 상태 바 그늘 · y300부터 검정으로
  private static var shade: some View {
    ZStack(alignment: .top) {
      Color.black.opacity(0.3)
      LinearGradient(colors: [.black.opacity(0.7), .clear], startPoint: .top, endPoint: .bottom)
        .frame(height: Metric.topScrim)
      VStack(spacing: 0) {
        Color.clear.frame(height: Metric.fadeTop)
        LinearGradient(
          stops: [
            .init(color: .clear, location: 0),
            .init(color: .black.opacity(0.3), location: 0.25),
            .init(color: .black.opacity(0.75), location: 0.45),
            .init(color: .black, location: 0.62),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
      }
    }
  }
}

private struct Column {
  let duration: TimeInterval
  let isUpward: Bool
  let top: CGFloat
  /// 줄마다 커버 순서를 밀어 옆 줄과 같은 커버가 나란히 서지 않게 한다
  let offset: Int

  private static let covers = [Asset.Assets.album1, Asset.Assets.album2, Asset.Assets.album3, Asset.Assets.album4]

  func view(at time: TimeInterval) -> some View {
    let progress = CGFloat(time.truncatingRemainder(dividingBy: self.duration) / self.duration)
    let travel = LoginCoverWall.Metric.loop * progress
    // 위로: 0 → -한 벌, 아래로: -한 벌 → 0
    let y = self.isUpward ? -travel : travel - LoginCoverWall.Metric.loop
    return VStack(spacing: LoginCoverWall.Metric.gap) {
      ForEach(0 ..< LoginCoverWall.Metric.tilesPerColumn * 2, id: \.self) { index in
        let cover = Self.covers[(index + self.offset) % Self.covers.count]
        cover.swiftUIImage
          .resizable()
          .scaledToFill()
          .frame(width: LoginCoverWall.Metric.tile, height: LoginCoverWall.Metric.tile)
          .background(WePLiColor.imagePlaceholder)
          .clipShape(RoundedRectangle(cornerRadius: 4))
      }
    }
    .offset(y: self.top + y)
    .frame(width: LoginCoverWall.Metric.tile, alignment: .top)
  }
}
