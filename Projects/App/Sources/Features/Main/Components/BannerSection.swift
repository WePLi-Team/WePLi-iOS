import SwiftUI

// MARK: - BannerSection

struct BannerSection: View {
  let banners: [Banner]
  let onBannerTapped: (Banner) -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 16) {
        ForEach(banners) { banner in
          BannerCard(banner: banner)
            .onTapGesture { onBannerTapped(banner) }
        }
      }
      .padding(.horizontal, 20)
    }
  }
}

// MARK: - BannerCard

struct BannerCard: View {
  let banner: Banner

  var body: some View {
    ZStack(alignment: .leading) {
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(hex: "141417"))

      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(banner.subtitle)
            .font(.system(size: 10, weight: .regular))
            .foregroundColor(Color(hex: "F0F0F0"))

          Text(banner.title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
        }
        .padding(.leading, 20)

        Spacer()

        // 배너 이미지 영역 (플레이스홀더)
        RoundedRectangle(cornerRadius: 4)
          .fill(Color.gray.opacity(0.3))
          .frame(width: 100, height: 76)
          .padding(.trailing, 12)
      }
    }
    .frame(width: 335, height: 84)
  }
}
