import SwiftUI
import WePLiDesignSystem

// UI-16d 버튼 묶음 — Apple(흰 버튼) · Google(반투명) · 먼저 둘러볼게요(글자 버튼) · 약관 줄
// Apple 버튼만 흰색: Apple 로그인 버튼은 가이드라인상 흰색 · 검은색만 쓸 수 있어 「흰 버튼 금지」의 유일한 예외(16 공통 규칙)

public struct LoginButtons: View {
  public let onApple: () -> Void
  public let onGoogle: () -> Void
  public let onBrowse: () -> Void

  public enum Metric {
    public static let height: CGFloat = 54
    public static let browseHeight: CGFloat = 36
  }

  public var body: some View {
    VStack(spacing: 12) {
      Button(action: self.onApple) {
        HStack(spacing: 8) {
          Image(systemName: "apple.logo")
            .font(.system(size: 19, weight: .medium))
            .offset(y: -1.5)
          Text("Apple로 계속하기")
            .wepliFont(.button)
        }
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity)
        .frame(height: Metric.height)
        .background(.white, in: Capsule())
        .contentShape(Capsule())
      }
      .buttonStyle(.plain)

      Button(action: self.onGoogle) {
        HStack(spacing: 10) {
          WePLiAccountFeaturesAsset.google.swiftUIImage
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
          Text("Google로 계속하기")
            .wepliFont(.button)
            .foregroundStyle(WePLiColor.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Metric.height)
        .background(.ultraThinMaterial, in: Capsule())
        .background(WePLiColor.secondaryButtonFill, in: Capsule())
        .contentShape(Capsule())
      }
      .buttonStyle(.plain)

      Button(action: self.onBrowse) {
        Text("먼저 둘러볼게요")
          .wepliFont(.body, weight: .medium)
          .foregroundStyle(WePLiColor.accent)
          .frame(maxWidth: .infinity)
          .frame(height: Metric.browseHeight)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
  }

  public init(onApple: @escaping () -> Void, onGoogle: @escaping () -> Void, onBrowse: @escaping () -> Void) {
    self.onApple = onApple
    self.onGoogle = onGoogle
    self.onBrowse = onBrowse
  }
}

/// 「처음 로그인하면 계정이 생성되며, 서비스 이용약관과 개인정보처리방침에 동의하게 됩니다.」
public struct LoginTerms: View {
  public let onTerms: () -> Void
  public let onPrivacy: () -> Void

  private static let textColor = Color(rgbHex: 0x767676)

  public var body: some View {
    // 한 문장 안의 두 링크 — 글자 단위로 누를 수 없어 링크 URL을 가로채 액션으로 바꾼다
    Text(Self.attributed)
      .font(.system(size: 12))
      .lineSpacing(2)
      .multilineTextAlignment(.center)
      .foregroundStyle(Self.textColor)
      .tint(WePLiColor.textTertiary)
      .environment(\.openURL, OpenURLAction { url in
        if url.host == "privacy" {
          self.onPrivacy()
        } else {
          self.onTerms()
        }
        return .handled
      })
  }

  private static var attributed: AttributedString {
    var text = AttributedString("처음 로그인하면 계정이 생성되며, ")
    text += Self.link("서비스 이용약관", host: "terms")
    text += AttributedString("과 ")
    text += Self.link("개인정보처리방침", host: "privacy")
    text += AttributedString("에 동의하게 됩니다.")
    return text
  }

  private static func link(_ title: String, host: String) -> AttributedString {
    var part = AttributedString(title)
    part.link = URL(string: "wepli://\(host)")
    part.foregroundColor = WePLiColor.textTertiary
    part.underlineStyle = .single
    return part
  }

  public init(onTerms: @escaping () -> Void, onPrivacy: @escaping () -> Void) {
    self.onTerms = onTerms
    self.onPrivacy = onPrivacy
  }
}
