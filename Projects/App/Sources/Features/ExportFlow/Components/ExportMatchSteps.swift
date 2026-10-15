import ComposableArchitecture
import SwiftUI

// UI-14h 곡 맞추는 중 · 14i 확인이 필요한 곡 · 14j 다른 버전 고르기

struct ExportMatchingStep: View {
  let store: StoreOf<ExportFlowFeature>

  var body: some View {
    WithPerceptionTracking {
      let total = self.store.selectedSongs.count
      let count = self.store.matchedCount
      ZStack(alignment: .bottom) {
        VStack(spacing: 0) {
          VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
              Text(count < total ? "\(self.store.service.name)에 담는 중" : "다 찾았어요")
                .wepliFont(.title3)
                .foregroundStyle(WePLiColor.textPrimary)
              Spacer()
              Text("\(count) / \(total)")
                .wepliFont(.body, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(WePLiColor.accent)
            }
            ExportProgressBar(fraction: total == 0 ? 0 : Double(count) / Double(total))
            Text("곡 고유 번호(ISRC)로 같은 음원을 찾고, 없으면 제목·가수로 다시 찾아요")
              .wepliFont(.caption, weight: .light)
              .foregroundStyle(WePLiColor.textTertiary)
          }
          .padding(.horizontal, 20)
          .padding(.top, 18)
          .padding(.bottom, 14)
          ScrollView {
            LazyVStack(spacing: 0) {
              ForEach(Array(self.store.selectedSongs.enumerated()), id: \.element.id) { index, song in
                self.row(song, isCurrent: index == count)
              }
            }
            .padding(.bottom, 150)
          }
        }
        self.footer
      }
    }
  }

  private func row(_ song: ExportSong, isCurrent: Bool) -> some View {
    let match = self.store.matches[song.id]
    return HStack(spacing: 12) {
      ExportArtwork()
      VStack(alignment: .leading, spacing: 0) {
        Text(song.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
        Text(song.artist).wepliFont(.footnote, weight: .light).foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
      }
      Spacer(minLength: 8)
      ExportMatchBadge(match: match, isCurrent: isCurrent).frame(width: 70, alignment: .trailing)
    }
    .padding(.horizontal, 20)
    .frame(height: 60)
    .opacity(match == nil && !isCurrent ? 0.35 : 1)
    .animation(.easeOut(duration: 0.25), value: match)
  }

  private var footer: some View {
    VStack(spacing: 12) {
      Text("화면을 닫아도 계속 담아요. 끝나면 알림으로 알려드릴게요.")
        .wepliFont(.footnote, weight: .light)
        .multilineTextAlignment(.center)
        .foregroundStyle(WePLiColor.textTertiary)
      ExportSecondaryButton(title: "닫기") { self.store.send(.closeTapped) }
    }
    .padding(.horizontal, 20)
    .padding(.top, 40)
    .padding(.bottom, 40)
    .background(
      LinearGradient(
        stops: [
          .init(color: WePLiColor.surface3.opacity(0), location: 0),
          .init(color: WePLiColor.surface3, location: 0.34),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    )
  }
}

/// 체크 · 「확인 필요」 · 「다른 버전」 · 「찾는 중」
struct ExportMatchBadge: View {
  let match: ExportMatch?
  let isCurrent: Bool

  var body: some View {
    switch self.match {
    case .found:
      ExportCheck(size: 18).accessibilityLabel("찾음")
    case .otherVersion:
      self.flag("다른 버전")
    case .needsCheck:
      self.flag("확인 필요")
    case nil:
      if self.isCurrent {
        HStack(spacing: 6) {
          Circle().fill(WePLiGradient.vsRing).frame(width: 6, height: 6)
          Text("찾는 중").wepliFont(.caption, weight: .semibold).foregroundStyle(WePLiColor.accent)
        }
      }
    }
  }

  private func flag(_ text: String) -> some View {
    Text(text).wepliFont(.caption, weight: .semibold).foregroundStyle(WePLiColor.positive)
  }
}

struct ExportProgressBar: View {
  let fraction: Double

  var body: some View {
    GeometryReader { proxy in
      Capsule().fill(Color.white.opacity(0.1))
        .overlay(alignment: .leading) {
          Capsule().fill(WePLiColor.accent).frame(width: proxy.size.width * min(max(self.fraction, 0), 1))
        }
    }
    .frame(height: 3)
    .animation(.easeOut(duration: 0.3), value: self.fraction)
    .accessibilityElement()
    .accessibilityValue("\(Int((self.fraction * 100).rounded()))%")
  }
}

struct ExportReviewStep: View {
  let store: StoreOf<ExportFlowFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: 0) {
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
              Text("\(self.store.foundSongs.count)곡은 그대로 찾았어요")
                .wepliFont(.title2, weight: .semibold)
                .foregroundStyle(WePLiColor.textPrimary)
              if !self.store.checkSongs.isEmpty {
                Text("\(self.store.checkSongs.count)곡은 담기 전에 한 번 확인해 주세요")
                  .wepliFont(.subheadline, weight: .light)
                  .foregroundStyle(WePLiColor.textSecondary)
              }
            }
            .padding(.top, 22)
            if !self.store.checkSongs.isEmpty {
              self.label("확인이 필요한 곡").padding(.top, 28).padding(.bottom, 6)
              ForEach(self.store.checkSongs) { song in
                self.checkRow(song)
              }
            }
            self.label("그대로 찾은 \(self.store.foundSongs.count)곡").padding(.top, 26).padding(.bottom, 10)
            self.foundSummary
          }
          .padding(.horizontal, 20)
        }
        self.buttons
      }
    }
  }

  private func label(_ text: String) -> some View {
    Text(text)
      .wepliFont(.footnote, weight: .semibold)
      .foregroundStyle(WePLiColor.textTertiary)
      .accessibilityAddTraits(.isHeader)
  }

  private func checkRow(_ song: ExportSong) -> some View {
    HStack(spacing: 12) {
      ExportArtwork(size: 48)
      VStack(alignment: .leading, spacing: 0) {
        Text(song.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
        Text(self.detail(song)).wepliFont(.footnote, weight: .light).foregroundStyle(WePLiColor.positive).lineLimit(1)
      }
      Spacer(minLength: 8)
      // 다른 버전으로 찾은 곡은 고를 후보가 없다 — 원본에도 이 「바꾸기」의 이동이 없다
      if case .needsCheck = self.store.matches[song.id] {
        Button("바꾸기") { self.store.send(.changeTapped(song.id)) }
          .wepliFont(.subheadline, weight: .semibold)
          .foregroundStyle(WePLiColor.accent)
      }
    }
    .frame(height: 68)
  }

  private func detail(_ song: ExportSong) -> String {
    switch (self.store.matches[song.id], self.store.resolutions[song.id]) {
    case let (_, .replace(alternative)?): "\(alternative.title)로 바꿨어요"
    case (_, .skip?): "이 곡은 빼고 담아요"
    case let (.needsCheck(alternatives)?, nil): "같은 음원이 없어요 · 비슷한 버전 \(alternatives.count)개"
    default: "다른 앨범에 실린 같은 곡으로 찾았어요"
    }
  }

  /// 문제없는 곡은 한 줄로 접는다 — 펼친 모습은 원본에 없다
  private var foundSummary: some View {
    let songs = self.store.foundSongs
    return HStack(spacing: 10) {
      HStack(spacing: 4) {
        ForEach(songs.prefix(5)) { _ in ExportArtwork(size: 30) }
      }
      Text(Self.summary(songs))
        .wepliFont(.footnote, weight: .light)
        .foregroundStyle(WePLiColor.textTertiary)
        .lineLimit(1)
    }
  }

  /// 「Supernova, How Sweet 외 8곡」
  static func summary(_ songs: [ExportSong]) -> String {
    let head = songs.prefix(2).map(\.title).joined(separator: ", ")
    return songs.count > 2 ? "\(head) 외 \(songs.count - 2)곡" : head
  }

  private var buttons: some View {
    VStack(spacing: 4) {
      WePLiPrimaryButton(
        title: "\(self.store.exportSongIDs.count)곡 담기",
        isEnabled: !self.store.isAdding && !self.store.exportSongIDs.isEmpty
      ) { self.store.send(.confirmTapped) }
      if !self.store.checkSongs.isEmpty, !self.store.foundSongs.isEmpty {
        ExportTextButton(title: "확인할 곡은 빼고 \(self.store.foundSongs.count)곡만 담기") {
          self.store.send(.addFoundOnlyTapped)
        }
        .disabled(self.store.isAdding)
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 12)
    .padding(.bottom, 40)
  }
}

struct ExportAlternativesSheet: View {
  let store: StoreOf<ExportFlowFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: 0) {
        ExportSheetNavBar(leading: "닫기", title: "다른 버전 고르기") { self.store.send(.alternativesClosed) }
        if let song = self.store.pickingSong {
          self.original(song)
        }
        Text("\(self.store.service.name)에서 찾은 비슷한 버전")
          .wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(WePLiColor.textTertiary)
          .padding(.horizontal, 20)
          .padding(.top, 16)
          .padding(.bottom, 4)
        ForEach(self.store.pickingAlternatives) { alternative in
          self.candidate(alternative)
        }
        self.skipRow
        Spacer(minLength: 0)
        WePLiPrimaryButton(title: self.ctaTitle, isEnabled: self.store.pick != nil) {
          self.store.send(.alternativeConfirmTapped)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
      }
    }
  }

  private var ctaTitle: String {
    switch self.store.pick {
    case .replace: "이 버전으로 바꾸기"
    case .skip: "이 곡 빼고 담기"
    case nil: "버전을 골라 주세요"
    }
  }

  private func original(_ song: ExportSong) -> some View {
    let rank = (self.store.songs.firstIndex(of: song) ?? 0) + 1
    return VStack(alignment: .leading, spacing: 10) {
      Text("원래 추천곡 · \(rank)위").wepliFont(.caption, weight: .semibold).foregroundStyle(WePLiColor.accent)
      HStack(spacing: 12) {
        ExportArtwork(size: 48)
        VStack(alignment: .leading, spacing: 0) {
          Text(song.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary).lineLimit(1)
          Text(song.recommender.isEmpty ? song.artist : "\(song.artist) · 추천 \(song.recommender)")
            .wepliFont(.footnote, weight: .light)
            .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
        }
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 10)
    .padding(.bottom, 16)
    .overlay(alignment: .bottom) { ExportDivider() }
  }

  private func candidate(_ alternative: ExportAlternative) -> some View {
    let isSelected = self.store.pick == .replace(alternative)
    return Button {
      self.store.send(.alternativePicked(.replace(alternative)))
    } label: {
      HStack(spacing: 12) {
        ExportArtwork(size: 48)
        VStack(alignment: .leading, spacing: 0) {
          Text(alternative.title)
            .wepliFont(.body)
            .foregroundStyle(isSelected ? WePLiColor.accent : WePLiColor.textPrimary)
          Text(alternative.detail)
            .wepliFont(.footnote, weight: .light)
            .foregroundStyle(WePLiColor.textPrimary.opacity(0.7))
            .lineLimit(1)
        }
        Spacer(minLength: 8)
        if isSelected {
          ExportCheck(size: 20)
        }
      }
      .padding(.horizontal, 20)
      .frame(height: 66)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
  }

  private var skipRow: some View {
    let isSelected = self.store.pick == .skip
    return Button {
      self.store.send(.alternativePicked(.skip))
    } label: {
      HStack(spacing: 12) {
        Image(systemName: "minus.circle")
          .font(.system(size: 20, weight: .light))
          .foregroundStyle(WePLiColor.textTertiary)
          .frame(width: 48)
        Text("이 곡은 빼고 담기").wepliFont(.body).foregroundStyle(isSelected ? WePLiColor.accent : WePLiColor.textPrimary)
        Spacer()
        if isSelected {
          ExportCheck(size: 20)
        }
      }
      .padding(.horizontal, 20)
      .frame(height: 56)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
  }
}
