import ComposableArchitecture
import SwiftUI

// UI-16d 로그인 — 흐르는 커버 벽 위에 Figma 원본 문구, 아래에 Apple · Google · 먼저 둘러볼게요(DEC-032)

struct LoginView: View {
  @Perception.Bindable var store: StoreOf<LoginFeature>

  enum Metric {
    static let copyTop: CGFloat = 430
    static let buttonsBottom: CGFloat = 92
    static let termsBottom: CGFloat = 40
  }

  var body: some View {
    WithPerceptionTracking {
      ZStack {
        WePLiColor.background
          .ignoresSafeArea()

        LoginCoverWall()

        GeometryReader { proxy in
          // 원본 기준(402×874)의 위치를 안전 영역 밖 화면 좌표로 맞춘다
          let fullHeight = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
          ZStack(alignment: .bottom) {
            self.copy
              .padding(.horizontal, 32)
              .padding(.top, Metric.copyTop)
              .frame(maxHeight: .infinity, alignment: .top)

            LoginButtons(
              onApple: { self.store.send(.appleLoginButtonTapped) },
              onGoogle: { self.store.send(.googleLoginButtonTapped) },
              onBrowse: { self.store.send(.browseTapped) }
            )
            .padding(.horizontal, 20)
            .padding(.bottom, Metric.buttonsBottom)

            LoginTerms(
              onTerms: { self.store.send(.termsOfServiceTapped) },
              onPrivacy: { self.store.send(.privacyPolicyTapped) }
            )
            .padding(.horizontal, 28)
            .padding(.bottom, Metric.termsBottom)
          }
          .frame(width: proxy.size.width, height: fullHeight)
          .offset(y: -proxy.safeAreaInsets.top)
        }

        if self.store.isLoading {
          self.loadingOverlay
        }
      }
      .preferredColorScheme(.dark)
      // 탈퇴 유예 · 재가입 제한(UI-17e)
      .fullScreenCover(item: self.$store.scope(state: \.accountGrace, action: \.accountGrace)) { graceStore in
        AccountGraceView(store: graceStore)
      }
    }
  }

  /// 원본 로고(img/logo.png)는 앱에 없어 글자만 둔다
  private var copy: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("WePLi")
        .wepliFont(.title1)
        .foregroundStyle(WePLiColor.textPrimary)
      Text("함께 만들어가는 플레이리스트,\n음악으로 연결되는 특별한 순간을 경험해보세요")
        .wepliFont(.callout)
        .lineSpacing(3)
        .foregroundStyle(WePLiColor.textSecondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var loadingOverlay: some View {
    ZStack {
      Color.black.opacity(0.5)
        .ignoresSafeArea()
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: .white))
        .scaleEffect(1.5)
    }
  }
}

#Preview {
  LoginView(
    store: Store(initialState: LoginFeature.State()) {
      LoginFeature()
    }
  )
}
