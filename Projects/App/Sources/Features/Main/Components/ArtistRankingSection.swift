import SwiftUI

// MARK: - ArtistRankingSection

struct ArtistRankingSection: View {
  let artists: [Artist]
  let onArtistTapped: (Artist) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      // 헤더
      VStack(alignment: .leading, spacing: 4) {
        Text("위플리 인기 랭킹")
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(Color(hex: "F0F0F0"))

        Text("위플리 차트에서 인기가 많은 가수들을 모아봤어요")
          .font(.system(size: 12, weight: .light))
          .foregroundColor(Color(hex: "A3A3A3"))
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)

      // 아티스트 목록
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(artists) { artist in
            ArtistProfileView(artist: artist)
              .onTapGesture { onArtistTapped(artist) }
          }
        }
        .padding(.horizontal, 20)
      }
    }
  }
}

// MARK: - ArtistProfileView

struct ArtistProfileView: View {
  let artist: Artist

  var body: some View {
    VStack(spacing: 4) {
      // 프로필 이미지 (원형 마스크)
      Circle()
        .fill(
          LinearGradient(
            colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .frame(width: 80, height: 80)

      // 아티스트 이름
      Text(artist.name)
        .font(.system(size: 12, weight: .light))
        .foregroundColor(Color(hex: "B5B5C0"))
        .lineLimit(1)
        .frame(width: 92)
        .multilineTextAlignment(.center)
    }
  }
}
