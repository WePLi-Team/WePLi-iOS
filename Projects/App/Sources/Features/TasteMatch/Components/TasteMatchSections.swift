import ComposableArchitecture
import SwiftUI

// UI-6d — 점수 고리(210, #C8CFFF로 차오름) · 아티스트 · 추천해 볼 곡 · 둘이서 플레이리스트 만들기

/// 점수 고리 — 열면 0에서 점수까지 차오른다(약 1.1초). 동작 줄이기면 바로 채운다
struct TasteMatchScore: View {
  let match: TasteMatch
  let name: String

  @State private var progress = 0.0

  @Environment(\.accessibilityReduceMotion)
  private var reduceMotion

  var body: some View {
    VStack(spacing: 14) {
      ZStack {
        // 원본은 conic 채움 위에 186 원판 — 폭 12 고리와 같다
        Circle().stroke(Color.white.opacity(0.08), lineWidth: 12).padding(6)
        Circle()
          .trim(from: 0, to: self.progress)
          .stroke(WePLiColor.accent, lineWidth: 12)
          .rotationEffect(.degrees(-90))
          .padding(6)
        Circle().fill(WePLiColor.cardFace).padding(12)
        VStack(spacing: 4) {
          HStack(spacing: -10) {
            ForEach(0 ..< 2, id: \.self) { _ in
              Circle()
                .fill(WePLiColor.imagePlaceholder)
                .frame(width: 44, height: 44)
                .overlay(Circle().strokeBorder(WePLiColor.cardFace, lineWidth: 2))
            }
          }
          .accessibilityHidden(true)
          Text("\(self.match.score)%")
            .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 44, relativeTo: .largeTitle))
            .monospacedDigit()
            .foregroundStyle(WePLiColor.textPrimary)
        }
      }
      .frame(width: 210, height: 210)
      .accessibilityElement(children: .combine)
      .accessibilityLabel("취향 일치 \(self.match.score)퍼센트")
      // 50점 아래 문구는 한 줄을 넘어 가운데로 줄바꿈
      Text(TasteMatchText.headline(name: self.name, score: self.match.score))
        .wepliFont(.title2, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 20)
      if let persona = self.match.sharedPersona {
        HStack(spacing: 8) {
          Text(persona)
            .wepliFont(.caption, weight: .semibold)
            .foregroundStyle(WePLiColor.textPrimary)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(WePLiColor.surface1, in: Capsule())
          Text("같은 성향").wepliFont(.footnote).foregroundStyle(WePLiColor.textQuaternary)
        }
      }
    }
    .onAppear {
      let target = Double(self.match.score) / 100
      withAnimation(self.reduceMotion ? nil : .easeOut(duration: 1.1)) { self.progress = target }
    }
  }
}

/// 둘 다 자주 듣는 아티스트 · 추천해 볼 곡 · 둘이서 플레이리스트 만들기
struct TasteMatchDetails: View {
  let store: StoreOf<TasteMatchFeature>
  let match: TasteMatch

  var body: some View {
    VStack(alignment: .leading, spacing: 26) {
      VStack(alignment: .leading, spacing: 12) {
        Text("둘 다 자주 듣는 아티스트").wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
        HStack(spacing: 14) {
          ForEach(self.match.artists, id: \.self) { artist in
            Button {
              self.store.send(.artistTapped(artist))
            } label: {
              VStack(spacing: 6) {
                Circle().fill(WePLiColor.imagePlaceholder).frame(width: 64, height: 64)
                Text(artist).wepliFont(.caption).foregroundStyle(WePLiColor.textSecondary).lineLimit(1)
              }
            }
            .buttonStyle(.plain)
          }
        }
      }
      self.recommendations
      WePLiPrimaryButton(title: "둘이서 플레이리스트 만들기") { self.store.send(.createPlaylistTapped) }
    }
  }

  private var recommendations: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(TasteMatchText.recommendTitle(self.store.name))
        .wepliFont(.callout, weight: .semibold)
        .foregroundStyle(WePLiColor.textPrimary)
      Text("내가 좋아하지만 상대는 아직 안 들어본 곡이에요").wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
      ForEach(self.match.recommendations) { song in
        HStack(spacing: 12) {
          RoundedRectangle(cornerRadius: 6).fill(WePLiColor.imagePlaceholder).frame(width: 46, height: 46)
          VStack(alignment: .leading, spacing: 2) {
            Text(song.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
            Text(song.artist).wepliFont(.footnote).foregroundStyle(WePLiColor.textQuaternary)
          }
          .lineLimit(1)
          Spacer(minLength: 8)
          self.sendButton(song)
        }
        .frame(height: 62)
      }
    }
  }

  /// 「추천 보내기」 → 「보냄」 — 곡당 1번
  private func sendButton(_ song: TasteMatchSong) -> some View {
    Button {
      self.store.send(.recommendTapped(song.id))
    } label: {
      Text(song.isSent ? "보냄" : "추천 보내기")
        .wepliFont(.footnote, weight: .semibold)
        .foregroundStyle(song.isSent ? WePLiColor.textQuaternary : WePLiColor.accent)
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(song.isSent ? WePLiColor.disabledFill : WePLiColor.chipOn, in: Capsule())
    }
    .buttonStyle(.plain)
    .disabled(song.isSent)
    .animation(.easeOut(duration: 0.2), value: song.isSent)
  }
}
