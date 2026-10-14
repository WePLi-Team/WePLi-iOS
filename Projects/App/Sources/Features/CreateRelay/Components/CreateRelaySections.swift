import SwiftUI

// UI-6a 구역 — 미리보기 카드 · 커버 · 기간 · 투표 방식 · 첫 곡 · 참여 범위

/// 「홈에서 이렇게 보여요」 — 높이 196 · 모서리 22, 입력이 바로 반영된다
struct CreateRelayPreview: View {
  let relay: NewRelay

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      RelayCoverSwatch(index: self.relay.cover)
      LinearGradient(colors: [.black.opacity(0.05), .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
      VStack(alignment: .leading, spacing: 6) {
        Text("RelayList · 새로 열림")
          .wepliFont(.caption, weight: .semibold)
          .foregroundStyle(WePLiColor.accent)
        Text(self.relay.trimmedTopic.isEmpty ? "주제를 입력해주세요" : self.relay.trimmedTopic)
          .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 22, relativeTo: .title2))
          .foregroundStyle(WePLiColor.textPrimary)
          .lineLimit(2)
        Text(self.relay.duration.countdownText)
          .wepliFont(.footnote)
          .monospacedDigit()
          .foregroundStyle(WePLiColor.timerText)
      }
      .padding(18)
    }
    .overlay(alignment: .topLeading) {
      Text("홈에서 이렇게 보여요")
        .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 11, relativeTo: .caption2))
        .foregroundStyle(WePLiColor.textMuted)
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(.black.opacity(0.45), in: Capsule())
        .padding(.leading, 14)
        .padding(.top, 12)
    }
    .frame(height: 196)
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    .accessibilityElement(children: .combine)
  }
}

/// 커버 자리 표시 — 원본은 예시 사진 4장. 앱 커버 묶음이 정해지면 바꾼다.
struct RelayCoverSwatch: View {
  let index: Int

  var body: some View {
    LinearGradient(colors: self.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
  }

  private var colors: [Color] {
    switch self.index {
    case 0: [WePLiColor.accentStrong, WePLiColor.surface2]
    case 1: [WePLiColor.highlight.opacity(0.7), WePLiColor.surface2]
    case 2: [WePLiColor.positive.opacity(0.6), WePLiColor.surface2]
    default: [WePLiColor.accentChip, WePLiColor.surface1]
    }
  }
}

struct CreateRelayCoverPicker: View {
  let selected: Int
  let onSelect: (Int) -> Void
  let onAddPhoto: () -> Void

  var body: some View {
    HStack(spacing: 10) {
      ForEach(0 ..< NewRelay.coverCount, id: \.self) { index in
        Button {
          self.onSelect(index)
        } label: {
          RelayCoverSwatch(index: index)
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(2)
            .background {
              if index == self.selected {
                RoundedRectangle(cornerRadius: 14).fill(WePLiColor.accent)
              }
            }
            .opacity(index == self.selected ? 1 : 0.6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("커버 \(index + 1)")
        .accessibilityAddTraits(index == self.selected ? .isSelected : [])
      }
      Button(action: self.onAddPhoto) {
        Image(systemName: "camera")
          .font(.system(size: 18))
          .foregroundStyle(WePLiColor.textQuaternary)
          .frame(width: 64, height: 64)
          .overlay(
            RoundedRectangle(cornerRadius: 14)
              .strokeBorder(Color.white.opacity(0.22), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
          )
      }
      .buttonStyle(.plain)
      .accessibilityLabel("사진으로 커버 추가")
    }
  }
}

struct CreateRelayDurationPicker: View {
  let selected: RelayDuration
  let onSelect: (RelayDuration) -> Void

  var body: some View {
    HStack(spacing: 0) {
      ForEach(RelayDuration.allCases, id: \.self) { duration in
        let isOn = duration == self.selected
        Button {
          self.onSelect(duration)
        } label: {
          Text(duration.title)
            .wepliFont(.subheadline, weight: isOn ? .semibold : .regular)
            .foregroundStyle(isOn ? WePLiColor.textPrimary : WePLiColor.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background {
              if isOn {
                RoundedRectangle(cornerRadius: 8).fill(WePLiColor.segmentSelected)
              }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
      }
    }
    .padding(2)
    .background(WePLiColor.surface3, in: RoundedRectangle(cornerRadius: 10))
  }
}

struct CreateRelayVoteFormatPicker: View {
  let selected: CreateRelayVoteFormat
  let onSelect: (CreateRelayVoteFormat) -> Void

  var body: some View {
    HStack(spacing: 10) {
      ForEach(CreateRelayVoteFormat.allCases, id: \.self) { format in
        let isOn = format == self.selected
        Button {
          self.onSelect(format)
        } label: {
          VStack(alignment: .leading, spacing: 2) {
            Text(format.title)
              .wepliFont(.body, weight: .semibold)
              .foregroundStyle(WePLiColor.textPrimary)
            Text(format.detail)
              .wepliFont(.caption)
              .foregroundStyle(isOn ? WePLiColor.textTertiary : WePLiColor.textQuaternary)
              .multilineTextAlignment(.leading)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(isOn ? 12 : 13.5)
          .background(
            isOn ? WePLiColor.selectionFill : WePLiColor.surface3,
            in: RoundedRectangle(cornerRadius: isOn ? 14.5 : 16, style: .continuous)
          )
          .padding(isOn ? 1.5 : 0)
          .background {
            if isOn {
              RoundedRectangle(cornerRadius: 16, style: .continuous).fill(WePLiColor.accentStrong.opacity(0.32))
            }
          }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
      }
    }
  }
}

struct CreateRelayFirstSong: View {
  let song: ComposeTrack?
  let onTap: () -> Void

  var body: some View {
    Button(action: self.onTap) {
      if let song = self.song {
        HStack(spacing: 12) {
          RoundedRectangle(cornerRadius: 6).fill(WePLiColor.surface4).frame(width: 44, height: 44)
          VStack(alignment: .leading, spacing: 1) {
            Text(song.title)
              .wepliFont(.body, weight: .medium)
              .foregroundStyle(WePLiColor.textPrimary)
            Text("\(song.artist) · 내가 시작한 곡")
              .wepliFont(.footnote)
              .foregroundStyle(WePLiColor.textQuaternary)
          }
          .lineLimit(1)
          .frame(maxWidth: .infinity, alignment: .leading)
          Text("변경")
            .wepliFont(.subheadline, weight: .semibold)
            .foregroundStyle(WePLiColor.accent)
        }
        .padding(.horizontal, 14)
        .frame(height: 66)
        .background(WePLiColor.surface3, in: RoundedRectangle(cornerRadius: 18))
      } else {
        HStack(spacing: 12) {
          Image(systemName: "plus")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(WePLiColor.textOnCTA)
            .frame(width: 30, height: 30)
            .background(WePLiColor.accent, in: Circle())
          Text("주제에 맞는 첫 곡을 골라주세요")
            .wepliFont(.body, weight: .medium)
            .foregroundStyle(WePLiColor.accent)
          Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(height: 66)
        .overlay(
          RoundedRectangle(cornerRadius: 18)
            .strokeBorder(WePLiColor.accent.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        )
      }
    }
    .buttonStyle(.plain)
  }
}

struct CreateRelayAudiencePicker: View {
  let selected: RelayAudience
  let onSelect: (RelayAudience) -> Void

  var body: some View {
    VStack(spacing: 0) {
      ForEach(Array(RelayAudience.allCases.enumerated()), id: \.element) { index, audience in
        Button {
          self.onSelect(audience)
        } label: {
          HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
              Text(audience.title)
                .wepliFont(.body)
                .foregroundStyle(WePLiColor.textPrimary)
              Text(audience.detail)
                .wepliFont(.caption)
                .foregroundStyle(WePLiColor.textQuaternary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if audience == self.selected {
              Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(WePLiColor.accent)
            }
          }
          .padding(.horizontal, 16)
          .frame(height: 56)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(audience == self.selected ? .isSelected : [])
        .overlay(alignment: .bottom) {
          if index < RelayAudience.allCases.count - 1 {
            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5).padding(.leading, 16)
          }
        }
      }
    }
    .background(WePLiColor.surface3, in: RoundedRectangle(cornerRadius: 18))
  }
}
