import SwiftUI
import WePLiDesignSystem
import WePLiSharedModels

// UI-2e 단계 공통 — 제목 24 SemiBold · 설명 14 #A3A3A3 · 큰 버튼 54(켜면 CTA 그라디언트, 끄면 흰색 8% · #6B6B7C)

public struct CardStepTitle: View {
  public let title: String
  public let message: String
  public var size: CGFloat = 24

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(self.title)
        .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: self.size, relativeTo: .title2))
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      Text(self.message)
        .wepliFont(.subheadline)
        .foregroundStyle(WePLiColor.textTertiary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  public init(title: String, message: String, size: CGFloat = 24) {
    self.title = title
    self.message = message
    self.size = size
  }
}

public struct CardStepButton: View {
  public let title: String
  public var systemImage: String?
  public let isEnabled: Bool
  public let action: () -> Void

  public var body: some View {
    Button(action: self.action) {
      HStack(spacing: 8) {
        if let systemImage {
          Image(systemName: systemImage).font(.system(size: 16, weight: .semibold))
        }
        Text(self.title).wepliFont(.button)
      }
      .foregroundStyle(self.isEnabled ? WePLiColor.textOnCTA : WePLiColor.textDisabled)
      .frame(maxWidth: .infinity)
      .frame(height: 54)
      .background {
        if self.isEnabled {
          Capsule().fill(WePLiGradient.cta)
        } else {
          Capsule().fill(WePLiColor.disabledFill)
        }
      }
    }
    .buttonStyle(.plain)
    .disabled(!self.isEnabled)
  }

  public init(title: String, systemImage: String? = nil, isEnabled: Bool, action: @escaping () -> Void) {
    self.title = title
    self.systemImage = systemImage
    self.isEnabled = isEnabled
    self.action = action
  }
}

/// 「건너뛰기」 · 「나가기」
public struct CardTextButton: View {
  public let title: String
  public let action: () -> Void

  public var body: some View {
    Button(action: self.action) {
      Text(self.title)
        .wepliFont(.body, weight: .medium)
        .foregroundStyle(WePLiColor.textTertiary)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  public init(title: String, action: @escaping () -> Void) {
    self.title = title
    self.action = action
  }
}

/// 밑줄 입력칸 — 글자 22 SemiBold · 밑줄 #C8CFFF 60% · 「n/20」
public struct CardUnderlineField: View {
  public let placeholder: String
  public let text: String
  public var prefix: String?
  public let onChange: (String) -> Void

  public var body: some View {
    VStack(alignment: .trailing, spacing: 8) {
      HStack(spacing: 4) {
        if let prefix {
          Text(prefix)
            .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 22, relativeTo: .title2))
            .foregroundStyle(WePLiColor.textQuaternary)
        }
        TextField(self.placeholder, text: Binding(get: { self.text }, set: self.onChange))
          .font(.custom(WePLiFont.Weight.semibold.postScriptName, size: 22, relativeTo: .title2))
          .foregroundStyle(WePLiColor.textPrimary)
          .tint(WePLiColor.accent)
          .autocorrectionDisabled()
      }
      .padding(.horizontal, 2)
      .frame(height: 48)
      .overlay(alignment: .bottom) {
        Rectangle().fill(WePLiColor.accent.opacity(0.6)).frame(height: 1.5)
      }
      Text("\(self.text.count)/\(BusinessCardInput.limit)")
        .wepliFont(.footnote)
        .monospacedDigit()
        .foregroundStyle(WePLiColor.textQuaternary)
    }
  }

  public init(placeholder: String, text: String, prefix: String? = nil, onChange: @escaping (String) -> Void) {
    self.placeholder = placeholder
    self.text = text
    self.prefix = prefix
    self.onChange = onChange
  }
}

/// 곡 고르기 영역 — 고르기 전 점선 원 240, 고른 뒤 디스크 + 「앨범을 누르면 다시 고를 수 있어요」
public struct CardSongPicker: View {
  public let song: ComposeTrack?
  public let onTap: () -> Void

  public var body: some View {
    Button(action: self.onTap) {
      if let song = self.song {
        VStack(spacing: 16) {
          Text("앨범을 누르면 다시 고를 수 있어요")
            .wepliFont(.footnote)
            .foregroundStyle(WePLiColor.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(WePLiColor.cardLine, in: RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .bottom) {
              RoundedRectangle(cornerRadius: 2)
                .fill(WePLiColor.cardLine)
                .frame(width: 10, height: 10)
                .rotationEffect(.degrees(45))
                .offset(y: 5)
            }
          BusinessCardDisc(size: 240, ring: 3, hole: 17, centerRing: 38)
          VStack(spacing: 2) {
            Text(song.title)
              .wepliFont(.title3)
              .foregroundStyle(WePLiColor.textPrimary)
            Text(song.artist)
              .wepliFont(.body)
              .foregroundStyle(WePLiColor.textTertiary)
          }
          .lineLimit(1)
        }
      } else {
        VStack(spacing: 10) {
          Image(systemName: "plus")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(WePLiColor.accent)
            .frame(width: 48, height: 48)
            .background(WePLiColor.disabledFill, in: Circle())
          Text("노래를 선택해주세요")
            .wepliFont(.callout, weight: .semibold)
            .foregroundStyle(WePLiColor.textPrimary)
          Text("선택하면 화면에 표시됩니다")
            .wepliFont(.footnote)
            .foregroundStyle(WePLiColor.textQuaternary)
        }
        .frame(width: 240, height: 240)
        .overlay(Circle().strokeBorder(Color.white.opacity(0.22), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])))
        .contentShape(Circle())
      }
    }
    .buttonStyle(.plain)
  }

  public init(song: ComposeTrack?, onTap: @escaping () -> Void) {
    self.song = song
    self.onTap = onTap
  }
}

/// 위쪽 내비게이션 — 뒤로 · 3칸 진행 막대 · 닫기
public struct CardStepNavigation: View {
  public let step: BusinessCardStep
  public let onBack: () -> Void
  public let onClose: () -> Void

  public var body: some View {
    HStack(spacing: 16) {
      WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로", action: self.onBack)
      HStack(spacing: 6) {
        ForEach(1 ... 3, id: \.self) { index in
          Capsule()
            .fill(self.step.rawValue >= index ? WePLiColor.accent : Color.white.opacity(0.14))
            .frame(height: 4)
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(self.step.accessibilityLabel)
      WePLiIconButton(systemName: "xmark", accessibilityLabel: "닫기", action: self.onClose)
    }
    .frame(height: 48)
  }

  public init(step: BusinessCardStep, onBack: @escaping () -> Void, onClose: @escaping () -> Void) {
    self.step = step
    self.onBack = onBack
    self.onClose = onClose
  }
}
