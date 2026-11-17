import ComposableArchitecture
import Foundation

// REQ-114 · UI-7g · DEC-004 — 앱 정보 · 약관(push). 아이콘이나 버전을 일곱 번 누르면 개발자 모드가 켜진다.

@Reducer
public struct AppInfoFeature {
  @ObservableState
  public struct State: Equatable {
    public var version = ""
    public var latestVersion: String?
    public var document: AppDocument?
    public var versionTaps = 0
    public var isDeveloperModeEnabled = false
    public var toast: String?

    public init(isDeveloperModeEnabled: Bool = false) {
      self.isDeveloperModeEnabled = isDeveloperModeEnabled
    }

    /// 「1.2.0 업데이트하기」 — 새 버전이 있을 때만
    public var update: String? {
      self.latestVersion.flatMap { AppInfoText.isNewer($0, than: self.version) ? $0 : nil }
    }
  }

  public enum Action: Equatable {
    case onAppear
    case latestLoaded(String?)
    case backButtonTapped
    case versionTapped
    case updateTapped
    case documentTapped(AppDocument.ID)
    case toastExpired
    case delegate(AppInfoDelegate)
  }

  public enum CancelID {
    case toast
  }

  /// 토스트를 보여주는 시간(원본 1400ms)
  public static let toastDuration: Duration = .milliseconds(1400)

  @Dependency(\.appInfoClient)
  public var client

  @Dependency(\.continuousClock)
  public var clock

  @Dependency(\.dismiss)
  public var dismiss

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.version.isEmpty else { return .none }
        state.version = self.client.currentVersion()
        return .run { send in await send(.latestLoaded(self.client.latestVersion())) }
      case let .latestLoaded(version):
        state.latestVersion = version
        return .none
      case .backButtonTapped:
        // 문서 본문이면 앱 정보로, 앱 정보면 마이로
        guard state.document == nil else {
          state.document = nil
          return .none
        }
        return .run { _ in await self.dismiss() }
      case .versionTapped:
        return self.countTap(&state)
      case let .documentTapped(id):
        // 커뮤니티 운영정책은 이용 제한 단계 표가 있는 화면(UI-17b)으로 연다
        guard id != AppDocument.policyID else { return .send(.delegate(.showCommunityPolicy)) }
        state.document = AppDocument.all.first { $0.id == id }
        return .none
      case .toastExpired:
        state.toast = nil
        return .none
      // 미결정 — 업데이트 링크(App Store 주소)가 정해지면 잇는다
      case .updateTapped, .delegate:
        return .none
      }
    }
  }

  private func countTap(_ state: inout State) -> Effect<Action> {
    guard !state.isDeveloperModeEnabled else { return .none }
    state.versionTaps += 1
    guard let toast = AppInfoText.developerToast(taps: state.versionTaps) else { return .none }
    state.toast = toast
    let hide = Effect<Action>.run { send in
      try await self.clock.sleep(for: Self.toastDuration)
      await send(.toastExpired)
    }
    .cancellable(id: CancelID.toast, cancelInFlight: true)
    guard state.versionTaps >= AppInfoText.developerTapCount else { return hide }
    state.isDeveloperModeEnabled = true
    return .merge(hide, .send(.delegate(.developerModeEnabled)))
  }

  public init() {}
}

public enum AppInfoDelegate: Equatable {
  /// 마이 「기타」에 개발자 모드 행을 보인다
  case developerModeEnabled
  /// 커뮤니티 운영정책(UI-17b)
  case showCommunityPolicy
}
