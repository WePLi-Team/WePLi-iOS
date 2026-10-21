import ComposableArchitecture
import SwiftUI

// UI-13a 1 음악 서비스 연결 · 2 공개 범위 · 연결했어요

struct ListeningConnectStep: View {
  let store: StoreOf<ListeningShareFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: 22) {
        VStack(alignment: .leading, spacing: 6) {
          Text("듣고 있는 음악을\n친구와 나눠요").wepliFont(.title2).foregroundStyle(WePLiColor.textPrimary)
          Text("음악 앱을 연결하면 친구들에게 이렇게 보여요").wepliFont(.subheadline).foregroundStyle(WePLiColor.textTertiary)
        }
        self.preview
        VStack(alignment: .leading, spacing: 8) {
          Text("음악 서비스").wepliFont(.footnote).foregroundStyle(WePLiColor.textQuaternary).padding(.horizontal, 4)
          VStack(spacing: 0) {
            ForEach(Array(ListeningService.allCases.enumerated()), id: \.element) { index, service in
              self.serviceRow(service, isLast: index == ListeningService.allCases.count - 1)
            }
          }
          .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 20))
          Text("YouTube Music · 멜론 · 벅스는 연동 방법을 검토 중이에요")
            .wepliFont(.caption)
            .foregroundStyle(WePLiColor.textDisabled)
            .padding(.horizontal, 4)
        }
      }
    }
  }

  /// 친구에게 이렇게 보여요 — 미결정: 내가 듣는 곡 대신 원본 예시(밤편지 · 아이유)
  private var preview: some View {
    HStack(spacing: 12) {
      Circle().fill(WePLiColor.imagePlaceholder).frame(width: 52, height: 52)
        .overlay(alignment: .bottomTrailing) {
          RoundedRectangle(cornerRadius: 6).fill(WePLiColor.surface4).frame(width: 26, height: 26)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(WePLiColor.surface1, lineWidth: 2))
            .offset(x: 4, y: 4)
        }
      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 6) {
          Text("\(self.store.nickname)님이 지금 듣는 중").wepliFont(.footnote).foregroundStyle(WePLiColor.textTertiary)
          ListeningEqualizer()
        }
        Text("밤편지 · 아이유").wepliFont(.callout, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
      }
      Spacer(minLength: 0)
    }
    .padding(14)
    .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 20))
    .accessibilityElement(children: .combine)
  }

  private func serviceRow(_ service: ListeningService, isLast: Bool) -> some View {
    let isConnected = self.store.connected.contains(service)
    return HStack(spacing: 12) {
      // 미결정 — 서비스 로고 에셋이 없어 자리 표시
      RoundedRectangle(cornerRadius: 10).fill(WePLiColor.surface4).frame(width: 38, height: 38)
        .overlay { Image(systemName: "music.note").foregroundStyle(WePLiColor.textMuted) }
      VStack(alignment: .leading, spacing: 1) {
        Text(service.name).wepliFont(.body, weight: .medium).foregroundStyle(WePLiColor.textPrimary)
        Text(service.detail).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
      }
      Spacer(minLength: 8)
      Button {
        self.store.send(.serviceTapped(service))
      } label: {
        Text(isConnected ? "연결됨" : "연결하기")
          .wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(isConnected ? WePLiColor.accent : WePLiColor.textPrimary)
          .padding(.horizontal, 12)
          .frame(height: 30)
          .background(
            isConnected ? WePLiColor.accentStrong.opacity(0.14) : WePLiColor.secondaryButtonFill,
            in: Capsule()
          )
      }
      .buttonStyle(.plain)
      .disabled(self.store.connecting != nil)
      .accessibilityLabel("\(service.name) \(isConnected ? "연결됨, 누르면 연결 해제" : "연결하기")")
    }
    .padding(.leading, 12)
    .padding(.trailing, 14)
    .frame(height: 66)
    .overlay(alignment: .bottom) {
      if !isLast {
        Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5).padding(.leading, 62)
      }
    }
  }
}

struct ListeningVisibilityStep: View {
  let store: StoreOf<ListeningShareFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: 18) {
        VStack(alignment: .leading, spacing: 6) {
          Text("누구에게 보여줄까요?").wepliFont(.title2).foregroundStyle(WePLiColor.textPrimary)
          Text("언제든 마이 › 설정에서 바꿀 수 있어요").wepliFont(.subheadline).foregroundStyle(WePLiColor.textTertiary)
        }
        VStack(spacing: 0) {
          ForEach(Array(ListeningVisibility.allCases.enumerated()), id: \.element) { index, visibility in
            self.visibilityRow(visibility, isLast: index == ListeningVisibility.allCases.count - 1)
          }
        }
        .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 20))
        if self.store.settings.visibility == .groups {
          HStack(spacing: 8) {
            ForEach(self.store.groups, id: \.self) { group in
              WePLiChip(title: group, isOn: self.store.settings.groups.contains(group)) {
                self.store.send(.groupToggled(group))
              }
            }
          }
        }
        VStack(spacing: 0) {
          ExportToggleRow(
            title: "멈추면 최근 들은 곡 보여주기",
            detail: "30분 동안 ‘최근 들은 곡’으로 표시해요",
            isOn: self.store.settings.showsRecent
          ) { self.store.send(.showsRecentToggled($0)) }
          ExportToggleRow(
            title: "밤 12시–오전 7시엔 숨기기",
            detail: "이 시간에 들은 곡은 공유하지 않아요",
            isOn: self.store.settings.hidesAtNight
          ) { self.store.send(.hidesAtNightToggled($0)) }
        }
        .padding(.horizontal, 16)
        .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 20))
      }
      .animation(.easeInOut(duration: 0.2), value: self.store.settings.visibility)
    }
  }

  /// 설정 화면이라 라디오 원을 쓴다(DEC-009 「라디오는 설정 화면만」)
  private func visibilityRow(_ visibility: ListeningVisibility, isLast: Bool) -> some View {
    let isSelected = self.store.settings.visibility == visibility
    return Button {
      self.store.send(.visibilitySelected(visibility))
    } label: {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          HStack(spacing: 6) {
            Text(visibility.title).wepliFont(.callout, weight: .medium).foregroundStyle(WePLiColor.textPrimary)
            if visibility == .friends {
              Text("기본")
                .font(.custom(WePLiFont.Weight.bold.postScriptName, size: 11, relativeTo: .caption2))
                .foregroundStyle(WePLiColor.accent)
                .padding(.horizontal, 7)
                .frame(height: 20)
                .background(WePLiColor.accentStrong.opacity(0.14), in: Capsule())
            }
          }
          Text(visibility.detail).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
        }
        Spacer(minLength: 8)
        Circle()
          .strokeBorder(Color.white.opacity(isSelected ? 0 : 0.25), lineWidth: 1.5)
          .background(Circle().fill(isSelected ? WePLiColor.accent : .clear))
          .overlay {
            if isSelected {
              Image(systemName: "checkmark").font(.system(size: 10, weight: .heavy))
                .foregroundStyle(WePLiColor.textOnCTA)
            }
          }
          .frame(width: 22, height: 22)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .frame(minHeight: 64)
      .contentShape(Rectangle())
      .overlay(alignment: .bottom) {
        if !isLast {
          Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5).padding(.leading, 16)
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
  }
}

struct ListeningDoneStep: View {
  let store: StoreOf<ListeningShareFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 12) {
        Circle().fill(WePLiColor.accent).frame(width: 64, height: 64)
          .overlay {
            Image(systemName: "checkmark").font(.system(size: 26, weight: .bold)).foregroundStyle(WePLiColor.textOnCTA)
          }
        Text("연결했어요").wepliFont(.title2).foregroundStyle(WePLiColor.textPrimary).padding(.top, 6)
        Text(ListeningShareText.done(self.store.settings, nickname: self.store.nickname))
          .wepliFont(.body)
          .foregroundStyle(WePLiColor.textTertiary)
      }
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 12)
      .padding(.top, 98)
    }
  }
}

/// 듣는 중 막대 3개 — 0.8초, 막대마다 0.18초씩 늦게
struct ListeningEqualizer: View {
  @State private var isAnimating = false

  @Environment(\.accessibilityReduceMotion)
  private var reduceMotion

  var body: some View {
    HStack(alignment: .bottom, spacing: 2) {
      ForEach(0 ..< 3, id: \.self) { index in
        RoundedRectangle(cornerRadius: 1)
          .fill(WePLiColor.accent)
          .frame(width: 3, height: 12)
          .scaleEffect(y: self.isAnimating ? 1 : 0.25, anchor: .bottom)
          .animation(
            self.reduceMotion ? nil : .easeInOut(duration: 0.8).repeatForever().delay(Double(index) * 0.18),
            value: self.isAnimating
          )
      }
    }
    .frame(width: 13, height: 12)
    .onAppear { self.isAnimating = true }
    .accessibilityHidden(true)
  }
}
