import ComposableArchitecture
import Foundation

// REQ-038 · UI-8a · DEC-004 — 내 추천곡 실시간 순위
// 화면이 보이는 동안 3.2초마다 서버 순위를 다시 받는다. 내 곡 순위가 오르면 위에서 역전 알림이 3.2초 내려온다.

@Reducer
struct MyRecommendationFeature {
  @ObservableState
  struct State: Equatable {
    let relayID: String
    var standing: RelayStanding?
    var remainingText = ""
    var banner: ReversalBanner?
    var loadFailed = false

    init(relayID: String) {
      self.relayID = relayID
    }
  }

  enum Action: Equatable {
    case onAppear
    case onDisappear
    case refreshTicked
    case standingLoaded(RelayStanding)
    case loadFailed
    case bannerDismissed
    case backButtonTapped
    case liveActivityTapped
    case cheerTapped
    case delegate(MyRecommendationDelegate)
  }

  /// 원본 갱신 · 알림 시간
  static let refreshInterval: Duration = .milliseconds(3200)
  static let bannerDuration: Duration = .milliseconds(3200)

  private enum CancelID {
    case refresh
    case banner
  }

  @Dependency(\.myRecommendationClient)
  var client

  @Dependency(\.continuousClock)
  var clock

  @Dependency(\.date.now)
  var now

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.loadFailed = false
        return .merge(
          .send(.refreshTicked),
          .run { send in
            for await _ in self.clock.timer(interval: Self.refreshInterval) {
              await send(.refreshTicked)
            }
          }
          .cancellable(id: CancelID.refresh, cancelInFlight: true)
        )

      case .onDisappear:
        return .merge(.cancel(id: CancelID.refresh), .cancel(id: CancelID.banner))

      case .refreshTicked:
        let relayID = state.relayID
        return .run { send in
          do {
            try await send(.standingLoaded(self.client.fetchStanding(relayID)))
          } catch {
            await send(.loadFailed)
          }
        }

      case let .standingLoaded(standing):
        let banner = Self.reversal(from: state.standing, to: standing)
        state.standing = standing
        state.remainingText = StandingText.remaining(until: standing.endsAt, now: self.now)
        guard let banner else { return .none }
        state.banner = banner
        return .run { send in
          try await self.clock.sleep(for: Self.bannerDuration)
          await send(.bannerDismissed)
        }
        .cancellable(id: CancelID.banner, cancelInFlight: true)

      case .loadFailed:
        // 처음 불러오기에 실패했을 때만 오류를 보여 주고, 갱신 실패는 지난 순위를 그대로 둔다
        state.loadFailed = state.standing == nil
        return .none

      case .bannerDismissed:
        state.banner = nil
        return .none

      case .backButtonTapped:
        return .send(.delegate(.dismiss))

      // 미결정 — 잠금화면 Live Activity(ActivityKit 위젯)와 응원 요청 방식이 정해지면 잇는다
      case .liveActivityTapped, .cheerTapped, .delegate:
        return .none
      }
    }
  }

  /// 히어로 내 곡의 순위가 올랐을 때만 알린다
  static func reversal(from old: RelayStanding?, to new: RelayStanding) -> ReversalBanner? {
    guard let song = new.heroSong,
          let before = old?.rank(of: song.id),
          let after = new.rank(of: song.id),
          after < before
    else { return nil }
    return ReversalBanner(rank: after, songTitle: song.title)
  }
}

enum MyRecommendationDelegate: Equatable {
  case dismiss
}
