import SwiftUI

// MARK: - RelayListSection

struct RelayListSection: View {
  let relayLists: [RelayList]
  let currentIndex: Int
  let topSafeArea: CGFloat
  let onPageChanged: (Int) -> Void

  var body: some View {
    VStack(spacing: 16) {
      TabView(selection: Binding(
        get: { currentIndex },
        set: { onPageChanged($0) }
      )) {
        ForEach(Array(relayLists.enumerated()), id: \.element.id) { index, relayList in
          RelayListCard(relayList: relayList, topSafeArea: topSafeArea)
            .tag(index)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .frame(height: 400 + topSafeArea)

      // 커스텀 인디케이터
      HStack(spacing: 4) {
        ForEach(0 ..< relayLists.count, id: \.self) { index in
          Capsule()
            .fill(Color.white.opacity(index == currentIndex ? 0.7 : 0.3))
            .frame(width: index == currentIndex ? 20 : 4, height: 4)
        }
      }
    }
  }
}

// MARK: - RelayListCard

struct RelayListCard: View {
  let relayList: RelayList
  var topSafeArea: CGFloat = 0

  var body: some View {
    ZStack(alignment: .bottom) {
      // 배경 이미지 (플레이스홀더)
      LinearGradient(
        colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      // 하단 그라디언트
      LinearGradient(
        colors: [
          Color.black.opacity(0),
          Color.black.opacity(0.1),
          Color.black.opacity(0.2),
          Color.black.opacity(0.6),
          Color.black,
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .frame(height: 342)

      // 콘텐츠
      VStack(alignment: .leading, spacing: 0) {
        // 상단 safe area + 앱바 높이만큼 여백
        Spacer()
          .frame(height: topSafeArea + 60)

        VStack(alignment: .leading, spacing: 4) {
          // 제목
          Text(relayList.title)
            .font(.system(size: 28, weight: .semibold))
            .foregroundColor(.white)
            .lineSpacing(6)

          // 참여자 수
          Text("\(relayList.participantCount.formatted())명 참여")
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(Color(hex: "D8D8DD"))
        }

        Spacer()
          .frame(height: 32)

        // 첫 곡 정보
        if let firstSong = relayList.firstSong {
          FirstSongView(song: firstSong)
        }

        Spacer()
          .frame(height: 16)

        // 타이머 또는 완성 상태
        RelayListTimerView(relayList: relayList)
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 20)
    }
  }
}

// MARK: - FirstSongView

struct FirstSongView: View {
  let song: Song

  var body: some View {
    HStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 6) {
        Text(song.title)
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(.white)
          .lineLimit(1)

        HStack(spacing: 8) {
          if let albumName = song.albumName {
            Text(albumName)
              .font(.system(size: 14, weight: .light))
              .foregroundColor(Color(hex: "B5B5C0"))
          }

          if song.albumName != nil, song.releaseYear != nil {
            Circle()
              .fill(Color(hex: "B5B5C0"))
              .frame(width: 4, height: 4)
          }

          if let year = song.releaseYear {
            Text(year)
              .font(.system(size: 14, weight: .light))
              .foregroundColor(Color(hex: "B5B5C0"))
          }
        }
      }

      Spacer()

      // 앨범 아트 (플레이스홀더)
      RoundedRectangle(cornerRadius: 8)
        .fill(
          LinearGradient(
            colors: [Color.orange, Color.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 60, height: 60)
    }
  }
}

// MARK: - RelayListTimerView

struct RelayListTimerView: View {
  let relayList: RelayList

  var body: some View {
    HStack {
      if relayList.isCompleted {
        Text("릴레이리스트가 완성되었어요 🎉")
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(Color(hex: "F0F0F0"))
      } else {
        Text("플리 완성까지")
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(Color(hex: "F0F0F0"))

        Spacer()

        Text(relayList.remainingTimeText)
          .font(.system(size: 14, weight: .light))
          .foregroundColor(Color(hex: "C2C2C2"))
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color.white.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}
