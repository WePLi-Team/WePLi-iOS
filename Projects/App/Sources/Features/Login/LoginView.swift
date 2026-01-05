import ComposableArchitecture
import SwiftUI

struct LoginView: View {
  let store: StoreOf<LoginFeature>

  var body: some View {
    WithPerceptionTracking {
      ZStack {
        Color.black
          .ignoresSafeArea()

        VStack(alignment: .leading, spacing: 0) {
          headerSection
            .padding(.top, 80)

          albumCarousel
            .padding(.top, 32)

          Spacer()

          loginButtonsSection
            .padding(.bottom, 16)

          termsSection
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)

        if store.isLoading {
          loadingOverlay
        }
      }
    }
  }
}

// MARK: - Colors

private extension LoginView {
  var subtitleColor: Color {
    Color(red: 163.0 / 255.0, green: 163.0 / 255.0, blue: 163.0 / 255.0)
  }

  var termsColor: Color {
    Color(red: 118.0 / 255.0, green: 118.0 / 255.0, blue: 118.0 / 255.0)
  }
}

// MARK: - Header Section

private extension LoginView {
  var headerSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("함께 만드는\n플레이리스트")
        .font(.system(size: 28, weight: .semibold))
        .foregroundColor(.white)
        .lineSpacing(6)

      Text("다양한 사람들과 음악으로 연결되는\n특별한 순간을 경험해보세요")
        .font(.system(size: 14, weight: .regular))
        .foregroundColor(subtitleColor)
        .lineSpacing(4)
    }
  }
}

// MARK: - Album Carousel

private extension LoginView {
  var albumCarousel: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(0..<6, id: \.self) { index in
          albumCoverView(index: index)
        }
      }
      .padding(.leading, 0)
    }
    .frame(height: 100)
  }

  @ViewBuilder
  func albumCoverView(index: Int) -> some View {
    let isLarge = index == 1
    let size: CGFloat = isLarge ? 100 : 60
    let cornerRadius: CGFloat = isLarge ? 12 : 8

    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(
        LinearGradient(
          colors: albumGradientColors(for: index),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .frame(width: size, height: size)
      .overlay {
        if index == 2 {
          Text("A NEW\nHOPE")
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
        }
      }
  }

  // swiftlint:disable:next function_body_length
  func albumGradientColors(for index: Int) -> [Color] {
    let gradients: [[Color]] = [
      [
        Color(red: 40.0 / 255.0, green: 40.0 / 255.0, blue: 45.0 / 255.0),
        Color(red: 60.0 / 255.0, green: 60.0 / 255.0, blue: 65.0 / 255.0)
      ],
      [
        Color(red: 139.0 / 255.0, green: 90.0 / 255.0, blue: 43.0 / 255.0),
        Color(red: 89.0 / 255.0, green: 60.0 / 255.0, blue: 30.0 / 255.0)
      ],
      [
        Color(red: 75.0 / 255.0, green: 0.0 / 255.0, blue: 130.0 / 255.0),
        Color(red: 138.0 / 255.0, green: 43.0 / 255.0, blue: 226.0 / 255.0)
      ],
      [
        Color(red: 180.0 / 255.0, green: 30.0 / 255.0, blue: 30.0 / 255.0),
        Color(red: 100.0 / 255.0, green: 20.0 / 255.0, blue: 20.0 / 255.0)
      ],
      [
        Color(red: 50.0 / 255.0, green: 50.0 / 255.0, blue: 55.0 / 255.0),
        Color(red: 70.0 / 255.0, green: 70.0 / 255.0, blue: 75.0 / 255.0)
      ],
      [
        Color(red: 30.0 / 255.0, green: 30.0 / 255.0, blue: 35.0 / 255.0),
        Color(red: 50.0 / 255.0, green: 50.0 / 255.0, blue: 55.0 / 255.0)
      ]
    ]
    return gradients[index % gradients.count]
  }
}

// MARK: - Login Buttons Section

private extension LoginView {
  var loginButtonsSection: some View {
    VStack(spacing: 16) {
      SocialLoginButton(provider: .apple) {
        store.send(.appleLoginButtonTapped)
      }

      SocialLoginButton(provider: .google) {
        store.send(.googleLoginButtonTapped)
      }
    }
  }
}

// MARK: - Terms Section

private extension LoginView {
  var termsSection: some View {
    VStack(spacing: 2) {
      Text("최초 로그인은 계정을 생성하며,")
        .font(.system(size: 11, weight: .light))
        .foregroundColor(termsColor)

      HStack(spacing: 0) {
        Text("그와 동시에 ")
          .font(.system(size: 11, weight: .light))
          .foregroundColor(termsColor)

        Button {
          store.send(.termsOfServiceTapped)
        } label: {
          Text("서비스 조건")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(termsColor)
        }

        Text("과 ")
          .font(.system(size: 11, weight: .light))
          .foregroundColor(termsColor)

        Button {
          store.send(.privacyPolicyTapped)
        } label: {
          Text("개인정보처리방침")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(termsColor)
        }

        Text("에 동의하게 됩니다.")
          .font(.system(size: 11, weight: .light))
          .foregroundColor(termsColor)
      }
    }
    .frame(maxWidth: .infinity)
  }
}

// MARK: - Loading Overlay

private extension LoginView {
  var loadingOverlay: some View {
    ZStack {
      Color.black.opacity(0.5)
        .ignoresSafeArea()

      ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: .white))
        .scaleEffect(1.5)
    }
  }
}

// MARK: - Preview

#Preview {
  LoginView(
    store: Store(initialState: LoginFeature.State()) {
      LoginFeature()
    }
  )
}
