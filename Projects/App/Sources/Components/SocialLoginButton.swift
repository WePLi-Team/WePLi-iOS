import SwiftUI

// MARK: - SocialLoginProvider

enum SocialLoginProvider {
  case apple
  case google

  var title: String {
    switch self {
    case .apple:
      return "Apple로 시작하기"
    case .google:
      return "Google로 시작하기"
    }
  }

  var iconName: String {
    switch self {
    case .apple:
      return "apple.logo"
    case .google:
      return "g.circle.fill"
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
      GoogleIcon()
    }
  }
}

// MARK: - GoogleIcon

struct GoogleIcon: View {
  var body: some View {
    ZStack {
      Circle()
        .fill(Color.white)
        .frame(width: 18, height: 18)

      Text("G")
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(
          LinearGradient(
            colors: googleColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
    }
  }

  private var googleColors: [Color] {
    [
      Color(red: 66.0 / 255.0, green: 133.0 / 255.0, blue: 244.0 / 255.0),
      Color(red: 219.0 / 255.0, green: 68.0 / 255.0, blue: 55.0 / 255.0),
      Color(red: 244.0 / 255.0, green: 180.0 / 255.0, blue: 0.0 / 255.0),
      Color(red: 15.0 / 255.0, green: 157.0 / 255.0, blue: 88.0 / 255.0)
    ]
  }
}

// MARK: - Preview

#Preview {
  VStack(spacing: 16) {
    SocialLoginButton(provider: .apple) { }

    SocialLoginButton(provider: .google) { }
  }
  .padding()
  .background(Color.black)
}
