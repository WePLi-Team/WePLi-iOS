import ComposableArchitecture
import Foundation

// REQ-075 · UI-2e · DEC-004 — 명함 만들기
// 뒤로 가도 입력값은 남는다. 닫기 · 나가기는 흐름을 닫는다(원본 프로토타입은 처음으로 되돌림).

@Reducer
struct BusinessCardFeature {
  @ObservableState
  struct State: Equatable {
    var step: BusinessCardStep = .intro
    let nickname: String
    let persona: String?
    let day: String
    let month: String
    var song: ComposeTrack?
    var oneLiner = ""
    var instagram = ""
    /// 생성 진행률 0–100
    var percent = 0
    var cardID: String?
    @Presents var picker: SongPickerFeature.State?
    var isShareSheetPresented = false
    var systemShare: SystemShareItem?
    var shareCount = 0
    var toast: String?

    init(nickname: String, persona: String?, today: Date) {
      self.nickname = nickname
      self.persona = persona
      let date = ShareCardDate(today)
      self.day = date.day
      self.month = date.month
    }

    var card: BusinessCard {
      BusinessCard(
        nickname: self.nickname,
        persona: self.persona,
        oneLiner: BusinessCardInput.hasText(self.oneLiner)
          ? self.oneLiner.trimmingCharacters(in: .whitespaces) : BusinessCard.defaultOneLiner,
        song: self.song,
        instagram: BusinessCardInput.displayInstagram(self.instagram),
        day: self.day,
        month: self.month
      )
    }
  }

  enum Action: Equatable {
    case startTapped
    case backTapped
    case closeTapped
    case songAreaTapped
    case picker(PresentationAction<SongPickerFeature.Action>)
    case songConfirmed
    case oneLinerChanged(String)
    case oneLinerConfirmed
    case instagramChanged(String)
    case instagramConfirmed
    case skipTapped
    case progressTicked(Int)
    case saved(cardID: String)
    case saveFailed
    case finished
    case shareTapped
    case shareSheetDismissed
    case shareItemTapped(BusinessCardShareItem, image: Data?)
    case linkCopied
    case linkFailed
    case imageSaved
    case imageSaveFailed(SongShareError?)
    case systemShareReady(image: Data, link: URL?)
    case systemShareDismissed
    case toastDismissed
    case delegate(BusinessCardDelegate)
  }

  private enum CancelID {
    case generation
  }

  /// 원본: 70ms마다 2–5%씩 오르고, 100%가 되면 450ms 뒤 완성
  static let tick: Duration = .milliseconds(70)
  static let finishDelay: Duration = .milliseconds(450)

  @Dependency(\.businessCardClient)
  var client

  @Dependency(\.songShareClient)
  var shareClient

  @Dependency(\.continuousClock)
  var clock

  @Dependency(\.withRandomNumberGenerator)
  var random

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .startTapped:
        state.step = .song
        return .none

      case .backTapped:
        guard state.step.showsNavigation, let previous = BusinessCardStep(rawValue: state.step.rawValue - 1) else {
          return .none
        }
        state.step = previous
        return .none

      case .closeTapped:
        return .merge(.cancel(id: CancelID.generation), .send(.delegate(.dismiss)))

      case .songAreaTapped:
        // 원본에 곡 고르는 화면이 없어 게시글의 곡 검색 시트(UI-2a)를 쓴다 — 처음 고른 한 곡
        state.picker = SongPickerFeature.State()
        return .none

      case let .picker(.presented(.delegate(.add(tracks)))):
        state.picker = nil
        if let track = tracks.first {
          state.song = track
        }
        return .none

      case .picker(.presented(.delegate(.dismiss))):
        state.picker = nil
        return .none

      case .songConfirmed:
        guard state.song != nil else { return .none }
        state.step = .oneLiner
        return .none

      case let .oneLinerChanged(text):
        state.oneLiner = BusinessCardInput.oneLiner(text)
        return .none

      case .oneLinerConfirmed:
        guard BusinessCardInput.hasText(state.oneLiner) else { return .none }
        state.step = .instagram
        return .none

      case let .instagramChanged(text):
        state.instagram = BusinessCardInput.instagram(text)
        return .none

      case .instagramConfirmed:
        guard BusinessCardInput.hasText(state.instagram) else { return .none }
        return self.generate(&state)

      case .skipTapped:
        state.instagram = ""
        return self.generate(&state)

      case let .progressTicked(increment):
        state.percent = min(100, state.percent + increment)
        guard state.percent == 100 else { return .none }
        return .merge(.cancel(id: CancelID.generation), self.finishIfReady(state))

      case let .saved(cardID):
        state.cardID = cardID
        return self.finishIfReady(state)

      case .saveFailed:
        // 원본에 실패 화면이 없어 임시 문구 — 디자인 확인 필요
        state.step = .instagram
        state.percent = 0
        state.toast = "명함을 만들지 못했어요. 다시 시도해 주세요"
        return .cancel(id: CancelID.generation)

      case .finished:
        state.step = .done
        return .none

      case .shareTapped:
        state.isShareSheetPresented = true
        return .none

      case .shareSheetDismissed:
        state.isShareSheetPresented = false
        return .none

      case let .shareItemTapped(item, image):
        return self.share(item, image: image, state: &state)

      case .linkCopied:
        // 원본에 없는 문구 — 공유 카드(UI-3g)와 같은 임시 문구
        state.toast = "링크를 복사했어요"
        return .none

      case .linkFailed:
        state.toast = "링크를 만들지 못했어요"
        return .none

      case .imageSaved:
        state.toast = "이미지를 저장했어요"
        return .none

      case let .imageSaveFailed(error):
        state.toast = error == .photoAccessDenied ? "사진 접근을 허용하면 저장할 수 있어요" : "이미지를 저장하지 못했어요"
        return .none

      case let .systemShareReady(image, link):
        state.shareCount += 1
        state.systemShare = SystemShareItem(id: state.shareCount, image: image, link: link)
        return .none

      case .systemShareDismissed:
        state.systemShare = nil
        return .none

      case .toastDismissed:
        state.toast = nil
        return .none

      case .picker, .delegate:
        return .none
      }
    }
    .ifLet(\.$picker, action: \.picker) {
      SongPickerFeature()
    }
  }

  /// 생성 — 진행률을 올리면서 서버에 저장한다. 둘 다 끝나야 완성으로 넘어간다.
  private func generate(_ state: inout State) -> Effect<Action> {
    state.step = .generating
    state.percent = 0
    state.cardID = nil
    let card = state.card
    let ticker = Effect<Action>.run { send in
      for await _ in self.clock.timer(interval: Self.tick) {
        let increment = self.random { Int.random(in: 2 ... 5, using: &$0) }
        await send(.progressTicked(increment))
      }
    }
    let save = Effect<Action>.run { send in
      do {
        try await send(.saved(cardID: self.client.create(card)))
      } catch {
        await send(.saveFailed)
      }
    }
    return .merge(ticker, save).cancellable(id: CancelID.generation, cancelInFlight: true)
  }

  private func finishIfReady(_ state: State) -> Effect<Action> {
    guard state.step == .generating, state.percent == 100, state.cardID != nil else { return .none }
    return .run { send in
      try await self.clock.sleep(for: Self.finishDelay)
      await send(.finished)
    }
  }

  private func share(_ item: BusinessCardShareItem, image: Data?, state: inout State) -> Effect<Action> {
    state.isShareSheetPresented = false
    let cardID = state.cardID ?? ""
    switch item {
    case .link:
      return .run { send in
        do {
          let url = try await self.client.link(cardID)
          await self.shareClient.copy(url)
          await send(.linkCopied)
        } catch {
          await send(.linkFailed)
        }
      }

    case .saveImage:
      guard let image else { return .none }
      return .run { send in
        do {
          try await self.shareClient.saveImage(image)
          await send(.imageSaved)
        } catch {
          await send(.imageSaveFailed(error as? SongShareError))
        }
      }

    case .instagramStory:
      // 미결정 — Instagram 스토리 직접 공유는 Facebook App ID가 필요하다. 그 전까지 시스템 공유 시트로 넘긴다.
      guard let image else { return .none }
      return .send(.systemShareReady(image: image, link: nil))

    case .otherApps:
      guard let image else { return .none }
      return .run { send in
        let url = try? await self.client.link(cardID)
        await send(.systemShareReady(image: image, link: url))
      }
    }
  }
}

enum BusinessCardDelegate: Equatable {
  case dismiss
}
