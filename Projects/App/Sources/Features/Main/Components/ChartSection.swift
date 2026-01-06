import SwiftUI

// MARK: - ChartSection

struct ChartSection: View {
  let songs: [ChartSong]
  let updateTime: String
  let onSongTapped: (ChartSong) -> Void
  let onSeeAllTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      // 헤더
      VStack(alignment: .leading, spacing: 4) {
        Text("위플리 TOP 100")
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(Color(hex: "F0F0F0"))

        Text(updateTime)
          .font(.system(size: 12, weight: .light))
          .foregroundColor(Color(hex: "A3A3A3"))
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)

      // 노래 목록
      VStack(spacing: 8) {
        ForEach(songs) { chartSong in
          ChartSongRow(chartSong: chartSong)
            .onTapGesture { onSongTapped(chartSong) }
        }
      }
      .padding(.vertical, 12)
    }
  }
}

// MARK: - ChartSongRow

struct ChartSongRow: View {
  let chartSong: ChartSong

  var body: some View {
    HStack(spacing: 0) {
      // 앨범 아트
      RoundedRectangle(cornerRadius: 4)
        .fill(
          LinearGradient(
            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 52, height: 52)
        .padding(.leading, 20)

      // 순위
      Text("\(chartSong.rank)")
        .font(.system(size: 12, weight: .light))
        .foregroundColor(Color.white.opacity(0.8))
        .frame(width: 26)

      // 노래 정보
      VStack(alignment: .leading, spacing: 4) {
        Text(chartSong.song.title)
          .font(.system(size: 14, weight: .light))
          .foregroundColor(.white)
          .lineLimit(1)

        Text(chartSong.song.artist)
          .font(.system(size: 12, weight: .light))
          .foregroundColor(Color.white.opacity(0.7))
          .lineLimit(1)
      }

      Spacer()

      // 더보기 버튼
      Button(action: {}) {
        Image(systemName: "ellipsis")
          .font(.system(size: 16))
          .foregroundColor(.white)
      }
      .frame(width: 44, height: 44)
      .padding(.trailing, 20)
    }
    .frame(height: 52)
  }
}
