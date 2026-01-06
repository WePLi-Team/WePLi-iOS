import SwiftUI

// MARK: - YouTubeSection

struct YouTubeSection: View {
  let videos: [YouTubeVideo]
  let onVideoTapped: (YouTubeVideo) -> Void
  let onSeeAllTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // 헤더
      Button(action: onSeeAllTapped) {
        HStack(spacing: 4) {
          // YouTube 아이콘 (플레이스홀더)
          Image(systemName: "play.rectangle.fill")
            .font(.system(size: 12))
            .foregroundColor(.red)

          Text("Youtube Music")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Color(hex: "F0F0F0"))

          Image(systemName: "chevron.right")
            .font(.system(size: 12))
            .foregroundColor(Color(hex: "D8D8DD"))
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)

      // 영상 목록
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(videos) { video in
            YouTubeVideoItemView(video: video)
              .onTapGesture { onVideoTapped(video) }
          }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
      }
    }
  }
}

// MARK: - YouTubeVideoItemView

struct YouTubeVideoItemView: View {
  let video: YouTubeVideo

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // 썸네일 (플레이스홀더)
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.gray.opacity(0.3))
        .frame(width: 240, height: 135)

      // 제목
      Text(video.title)
        .font(.system(size: 15, weight: .regular))
        .foregroundColor(Color(hex: "F0F0F0"))
        .lineLimit(1)
        .frame(width: 240, alignment: .leading)
        .padding(.top, 11)

      // 채널명
      Text(video.channelName)
        .font(.system(size: 13, weight: .light))
        .foregroundColor(Color(hex: "B5B5C0"))
        .padding(.top, 4)
    }
  }
}
