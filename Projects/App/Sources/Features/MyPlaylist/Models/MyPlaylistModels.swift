import Foundation

// REQ-078 · UI-10d — 내 플레이리스트

struct MyPlaylist: Equatable, Identifiable, Sendable {
  static let nameLimit = 30

  let id: String
  var name: String
  /// 원본은 「비공개」 고정 표시 — 공개 전환 화면은 없다
  var isPrivate: Bool
  var tracks: [ComposeTrack]

  /// 「6곡 · 비공개」 — 곡 수는 편집 결과를 바로 반영한다
  var meta: String {
    "\(self.tracks.count)곡 · \(self.isPrivate ? "비공개" : "공개")"
  }

  /// 이름 — 30자에서 자른다
  static func clampName(_ text: String) -> String {
    String(text.prefix(self.nameLimit))
  }
}

extension MyPlaylist {
  /// 원본(UI-10d) 예시
  static func mock(id: String) -> MyPlaylist {
    MyPlaylist(
      id: id,
      name: id == "album" ? "내 앨범 (2024.05.03)" : "비 오는 날 듣는 플리",
      isPrivate: true,
      tracks: [
        ComposeTrack(id: "shopper", title: "Shopper", artist: "아이유 (IU)"),
        ComposeTrack(id: "bam", title: "밤양갱", artist: "비비(bibi)"),
        ComposeTrack(id: "supernova", title: "Supernova", artist: "aespa"),
        ComposeTrack(id: "rain", title: "비와 당신", artist: "이무진"),
        ComposeTrack(id: "lovepoem", title: "Love poem", artist: "아이유(IU)"),
        ComposeTrack(id: "sea", title: "너의 바다", artist: "호피폴라"),
      ]
    )
  }
}
