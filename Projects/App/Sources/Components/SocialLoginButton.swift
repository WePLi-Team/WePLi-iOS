import SwiftUI

// MARK: - SocialLoginProvider

enum SocialLoginProvider {
  case apple
  case google

  var title: String {
    switch self {
    case .apple:
      "Apple로 시작하기"
    case .google:
      "Google로 시작하기"
    }
  }
}

// MARK: - SocialLoginButton

struct SocialLoginButton: View {
  let provider: SocialLoginProvider
  let action: () -> Void

  private let buttonBackgroundColor = Color(
    red: 20.0 / 255.0,
    green: 20.0 / 255.0,
    blue: 23.0 / 255.0
  )

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        providerIcon
          .frame(width: 20, height: 20)

        Spacer()

        Text(provider.title)
          .font(.system(size: 14, weight: .regular))
          .foregroundColor(.white.opacity(0.91))

        Spacer()

        Color.clear
          .frame(width: 20, height: 20)
      }
      .padding(.horizontal, 16)
      .frame(height: 48)
      .background(buttonBackgroundColor)
      .cornerRadius(8)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder private var providerIcon: some View {
    switch provider {
    case .apple:
      Image(systemName: "apple.logo")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .foregroundColor(.white)

    case .google:
      Asset.Assets.google.swiftUIImage
        .resizable()
        .aspectRatio(contentMode: .fit)
    }
  }
}

// MARK: - Preview

#Preview {
  VStack(spacing: 16) {
    SocialLoginButton(provider: .apple) {}

    SocialLoginButton(provider: .google) {}
  }
  .padding()
  .background(Color.black)
}
