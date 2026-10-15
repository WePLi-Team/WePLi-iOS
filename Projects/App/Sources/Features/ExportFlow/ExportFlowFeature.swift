import ComposableArchitecture
import Foundation

// REQ-050 · UI-14c–14k · UI-14o · DEC-004 — 내 음악 앱으로 내보내기(시트)
// 서비스 고르기 → 담기 설정 → 처음이면 연결 → 곡 맞추기 → 확인 → 완료. 멜론 · 지니 · FLO 등은 곡 목록 복사.
// 곡을 먼저 다 맞추고, 확인을 받은 뒤 한 번에 담는다(원본 충돌 2 — 14i 「담기 전에 확인」을 따른다).

@Reducer
struct ExportFlowFeature {
  @ObservableState
  struct State: Equatable {
    let relayID: String
    let title: String
    let recommenderCount: Int
    let songs: [ExportSong]
    var step: ExportStep = .service
    /// 지난번에 담은 곳이 먼저 골라져 있다(14c)
    var service: ExportService = .appleMusic
    var connected: Set<ExportService> = []
    var name: String
    var selection: ExportSelection = .all
    var includesCredit = true
    var uploadsCover = true
    var matches: [String: ExportMatch] = [:]
    var resolutions: [String: ExportResolution] = [:]
    /// 다른 버전 고르기(14j) — 고르는 곡과 고른 것
    var picking: String?
    var pick: ExportResolution?
    var isConnecting = false
    var isAdding = false
    var addedCount = 0
    var autoExport = true
    var listFormat: ExportListFormat = .titleFirst
    var isCopied = false
    var toast: String?

    init(relayID: String, title: String, recommenderCount: Int, songs: [ExportSong]) {
      self.relayID = relayID
      self.title = title
      self.recommenderCount = recommenderCount
      self.songs = songs
      self.name = String("WePLi · \(title)".prefix(ExportText.nameLimit))
    }
  }

  enum Action: Equatable {
    case closeTapped
    case backTapped
    case serviceSelected(ExportService)
    case serviceNextTapped
    case connections(Set<ExportService>)
    case nameChanged(String)
    case selectionSelected(ExportSelection)
    case creditToggled(Bool)
    case coverToggled(Bool)
    case addTapped
    case connectTapped
    case connectResult(Bool)
    case laterTapped
    case matched(ExportMatchEvent)
    case matchingFinished
    case changeTapped(String)
    case alternativePicked(ExportResolution)
    case alternativeConfirmTapped
    case alternativesClosed
    case confirmTapped
    case addFoundOnlyTapped
    case added(Int)
    case addFailed
    case autoExportToggled(Bool)
    case openInServiceTapped
    case listFormatSelected(ExportListFormat)
    case copyTapped
    case copyReset
    case toastDismissed
    case delegate(ExportFlowDelegate)
  }

  enum CancelID {
    case matching
    case copied
  }

  /// 「복사했어요」를 보여주는 시간(원본 1800ms)
  static let copiedDuration: Duration = .milliseconds(1800)

  @Dependency(\.exportClient)
  var client

  @Dependency(\.continuousClock)
  var clock

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .closeTapped:
        return .merge(.cancel(id: CancelID.matching), .send(.delegate(.dismiss)))
      case .backTapped:
        // 담기 설정 · 곡 목록(14o) → 서비스 선택, 접근 허용(14e) → 담기 설정
        state.step = [.settings, .copyList].contains(state.step) ? .service : .settings
        return .none
      case .serviceSelected, .serviceNextTapped, .connections:
        return self.serviceStep(&state, action)
      case .nameChanged, .selectionSelected, .creditToggled, .coverToggled, .addTapped:
        return self.settingsStep(&state, action)
      case .connectTapped, .connectResult, .laterTapped:
        return self.connectStep(&state, action)
      case .matched, .matchingFinished:
        return self.matchingStep(&state, action)
      case .changeTapped, .alternativePicked, .alternativeConfirmTapped, .alternativesClosed:
        return self.alternativesStep(&state, action)
      case .confirmTapped, .addFoundOnlyTapped, .added, .addFailed:
        return self.addStep(&state, action)
      case .autoExportToggled, .openInServiceTapped, .listFormatSelected, .copyTapped, .copyReset:
        return self.doneStep(&state, action)
      case .toastDismissed:
        state.toast = nil
        return .none
      case .delegate:
        return .none
      }
    }
  }

  // MARK: 14c 서비스 선택

  private func serviceStep(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case let .serviceSelected(service):
      state.service = service
      return .none
    case .serviceNextTapped:
      // 「멜론 · 지니 · FLO 등」이면 곡 목록 옮기기(14o)
      state.step = state.service == .otherApps ? .copyList : .settings
      guard state.connected.isEmpty else { return .none }
      return .run { send in
        var connected: Set<ExportService> = []
        for service in ExportService.allCases where await self.client.isConnected(service) {
          connected.insert(service)
        }
        await send(.connections(connected))
      }
    case let .connections(connected):
      state.connected = connected
      return .none
    default:
      return .none
    }
  }

  // MARK: 14d 담기 설정

  private func settingsStep(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case let .nameChanged(text):
      state.name = String(text.prefix(ExportText.nameLimit))
    case let .selectionSelected(selection):
      state.selection = selection
    case let .creditToggled(isOn):
      state.includesCredit = isOn
    case let .coverToggled(isOn):
      state.uploadsCover = isOn
    case .addTapped:
      guard !state.selectedSongs.isEmpty else { return .none }
      // 연결해 둔 서비스면 연결 단계를 건너뛴다(원본 2절)
      if state.connected.contains(state.service) {
        return self.startMatching(&state)
      }
      // Apple Music은 시스템 알림 전에 설명(14e), Spotify · YouTube는 시스템 보안 로그인 창이 바로 뜬다(14g)
      guard state.service == .appleMusic else { return self.connect(&state) }
      state.step = .appleMusicPermission
    default:
      break
    }
    return .none
  }

  // MARK: 14e · 14g 처음 한 번 연결

  private func connectStep(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case .connectTapped:
      return self.connect(&state)
    case let .connectResult(isConnected):
      state.isConnecting = false
      guard isConnected else {
        // 원본에 없는 문구 — 거절했을 때 설정 앱 안내 화면이 없다(디자인 확인 필요)
        state.toast = "\(state.service.name)에 연결하지 못했어요"
        return .none
      }
      state.connected.insert(state.service)
      return self.startMatching(&state)
    case .laterTapped:
      state.step = .settings
      return .none
    default:
      return .none
    }
  }

  private func connect(_ state: inout State) -> Effect<Action> {
    guard !state.isConnecting else { return .none }
    state.isConnecting = true
    let service = state.service
    return .run { send in
      let isConnected = await (try? self.client.connect(service)) ?? false
      await send(.connectResult(isConnected))
    }
  }

  // MARK: 14h 곡 맞추기

  private func startMatching(_ state: inout State) -> Effect<Action> {
    state.step = .matching
    state.matches = [:]
    state.resolutions = [:]
    let service = state.service
    let songs = state.selectedSongs
    return .run { send in
      for await event in self.client.match(service, songs) {
        await send(.matched(event))
      }
      await send(.matchingFinished)
    }
    .cancellable(id: CancelID.matching, cancelInFlight: true)
  }

  private func matchingStep(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case let .matched(event):
      state.matches[event.songID] = event.match
    case .matchingFinished:
      // 다 찾은 뒤 확인(14i)에서 한 번에 고른다
      state.step = .review
    default:
      break
    }
    return .none
  }

  // MARK: 14j 다른 버전 고르기

  private func alternativesStep(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case let .changeTapped(songID):
      state.picking = songID
      state.pick = state.resolutions[songID]
    case let .alternativePicked(resolution):
      state.pick = resolution
    case .alternativeConfirmTapped:
      guard let songID = state.picking, let pick = state.pick else { return .none }
      state.resolutions[songID] = pick
      state.picking = nil
      state.pick = nil
    case .alternativesClosed:
      state.picking = nil
      state.pick = nil
    default:
      break
    }
    return .none
  }

  // MARK: 14i → 14k 담기

  private func addStep(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case .confirmTapped:
      return self.add(&state, songIDs: state.exportSongIDs)
    case .addFoundOnlyTapped:
      // 「확인할 곡은 빼고 N곡만 담기」
      return self.add(&state, songIDs: state.foundSongs.map(\.id))
    case let .added(count):
      state.isAdding = false
      state.addedCount = count
      state.step = .done
      return .none
    case .addFailed:
      state.isAdding = false
      // 원본에 없는 문구 — 문제가 생겼을 때(14n)는 2단계에서 만든다
      state.toast = "\(state.service.name)에 담지 못했어요. 다시 시도해 주세요"
      return .none
    default:
      return .none
    }
  }

  private func add(_ state: inout State, songIDs: [String]) -> Effect<Action> {
    guard !state.isAdding, !songIDs.isEmpty else { return .none }
    state.isAdding = true
    let service = state.service
    let name = state.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? state.title : state.name
    return .run { send in
      do {
        try await self.client.createPlaylist(service, name, songIDs)
        await send(.added(songIDs.count))
      } catch {
        await send(.addFailed)
      }
    }
  }

  // MARK: 14k 완료 · 14o 곡 목록

  private func doneStep(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case let .autoExportToggled(isOn):
      state.autoExport = isOn
      let service = state.service
      return .run { _ in await self.client.setAutoExport(service, isOn) }
    case let .listFormatSelected(format):
      state.listFormat = format
      return .none
    case .copyTapped:
      state.isCopied = true
      let text = state.listFormat.lines(state.selectedSongs).joined(separator: "\n")
      return .run { send in
        await self.client.copy(text)
        try await self.clock.sleep(for: Self.copiedDuration)
        await send(.copyReset)
      }
      .cancellable(id: CancelID.copied, cancelInFlight: true)
    case .copyReset:
      state.isCopied = false
      return .none
    // 목업에는 만든 플리 주소가 없다 — 실제 연동 때 플리 URL을 연다
    default:
      return .none
    }
  }
}

enum ExportFlowDelegate: Equatable {
  case dismiss
}

extension ExportFlowFeature.State {
  /// 14d 「담을 곡」
  var selectedSongs: [ExportSong] {
    switch self.selection {
    case .all: self.songs
    case .top10: Array(self.songs.prefix(10))
    case .voted: self.songs.filter(\.isVoted)
    }
  }

  var votedCount: Int {
    self.songs.filter(\.isVoted).count
  }

  var matchedCount: Int {
    self.selectedSongs.filter { self.matches[$0.id] != nil }.count
  }

  /// 14i 「확인이 필요한 곡」 — 같은 음원이 없거나 다른 버전으로 찾은 곡
  var checkSongs: [ExportSong] {
    self.selectedSongs.filter { self.matches[$0.id].map { $0 != .found } ?? false }
  }

  var foundSongs: [ExportSong] {
    self.selectedSongs.filter { self.matches[$0.id] == .found }
  }

  /// 담을 곡 — 빼기로 한 곡과 아직 버전을 고르지 않은 「확인 필요」 곡은 담지 않는다
  var exportSongIDs: [String] {
    self.selectedSongs.compactMap { song in
      switch (self.matches[song.id], self.resolutions[song.id]) {
      case (_, .skip), (.needsCheck, nil), (nil, _): nil
      case let (_, .replace(alternative)): alternative.id
      default: song.id
      }
    }
  }

  var pickingSong: ExportSong? {
    self.picking.flatMap { id in self.songs.first { $0.id == id } }
  }

  var pickingAlternatives: [ExportAlternative] {
    guard let id = self.picking, case let .needsCheck(alternatives) = self.matches[id] else { return [] }
    return alternatives
  }
}
