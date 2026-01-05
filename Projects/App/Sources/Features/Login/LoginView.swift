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
    InteractiveAlbumCarousel(
      albumImages: [
        Asset.Assets.album1,
        Asset.Assets.album2,
        Asset.Assets.album3,
        Asset.Assets.album4,
        Asset.Assets.album1,
        Asset.Assets.album2,
        Asset.Assets.album3,
        Asset.Assets.album4,
      ]
    )
    .padding(.horizontal, -24)
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
