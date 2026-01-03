# Claude Code 개발 가이드

이 문서는 WePLi iOS 프로젝트에서 Claude Code를 활용한 개발 방법을 설명합니다.

## 개발 워크플로우

### 1. 새 기능 개발 (TCA Feature)

새로운 TCA Feature를 개발하는 전체 흐름입니다.

```
┌─────────────────────────────────────────────────────────────┐
│  1. 기능 분석 및 계획                                        │
│     - 기능 요구사항 정리                                     │
│     - State, Action, Reducer 설계                           │
│     - 의존성(Dependency) 식별                               │
├─────────────────────────────────────────────────────────────┤
│  2. TCA 컴포넌트 구현                                        │
│     ┌──────────────────────────────────────────────────┐    │
│     │  State 정의 → Action 정의 → Reducer 구현         │    │
│     │  → View 구현 → Dependency 연결                   │    │
│     └──────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│  3. 테스트 작성                                              │
│     - TestStore를 사용한 Reducer 테스트                      │
│     - 각 Action에 대한 State 변화 검증                       │
├─────────────────────────────────────────────────────────────┤
│  4. 검증 및 커밋                                             │
│     - SwiftLint/SwiftFormat 통과 확인                        │
│     - 빌드 및 테스트 통과 확인                               │
│     - 마이크로 커밋으로 변경사항 기록                         │
└─────────────────────────────────────────────────────────────┘
```

### 2. TCA Feature 구현 순서

#### Step 1: State 정의

```swift
@Reducer
struct PlaylistFeature {
  @ObservableState
  struct State: Equatable {
    var playlists: [Playlist] = []
    var isLoading: Bool = false
    var error: String?
  }
}
```

#### Step 2: Action 정의

```swift
enum Action {
  case onAppear
  case fetchPlaylists
  case playlistsResponse(Result<[Playlist], Error>)
  case playlistTapped(Playlist)
}
```

#### Step 3: Reducer 구현

```swift
var body: some ReducerOf<Self> {
  Reduce { state, action in
    switch action {
    case .onAppear:
      return .send(.fetchPlaylists)

    case .fetchPlaylists:
      state.isLoading = true
      return .run { send in
        // API 호출
      }

    case let .playlistsResponse(.success(playlists)):
      state.isLoading = false
      state.playlists = playlists
      return .none

    case let .playlistsResponse(.failure(error)):
      state.isLoading = false
      state.error = error.localizedDescription
      return .none

    case .playlistTapped:
      return .none
    }
  }
}
```

#### Step 4: View 구현

```swift
struct PlaylistView: View {
  let store: StoreOf<PlaylistFeature>

  var body: some View {
    WithPerceptionTracking {
      List(store.playlists) { playlist in
        // ...
      }
      .onAppear { store.send(.onAppear) }
    }
  }
}
```

---

## 주요 개발 명령어

### 빌드 및 테스트

```bash
# 프로젝트 생성
tuist install && tuist generate

# 빌드
xcodebuild -workspace WePLi.xcworkspace -scheme WePLi build

# 테스트 실행
xcodebuild -workspace WePLi.xcworkspace -scheme WePLi \
  -destination 'platform=iOS Simulator,name=iPhone 15' test

# 린트
swiftlint --config .swiftlint.yml
swiftformat --lint . --config .swiftformat
```

### Fastlane

```bash
bundle exec fastlane ios bootstrap   # 환경 설정
bundle exec fastlane ios test        # 테스트 실행
bundle exec fastlane ios build_debug # Debug 빌드
```

---

## TCA 테스트 작성

### TestStore 사용법

```swift
import ComposableArchitecture
import XCTest

@MainActor
final class PlaylistFeatureTests: XCTestCase {
  func testFetchPlaylists() async {
    let store = TestStore(initialState: PlaylistFeature.State()) {
      PlaylistFeature()
    } withDependencies: {
      $0.playlistClient.fetch = { [Playlist.mock] }
    }

    await store.send(.fetchPlaylists) {
      $0.isLoading = true
    }

    await store.receive(\.playlistsResponse.success) {
      $0.isLoading = false
      $0.playlists = [Playlist.mock]
    }
  }
}
```

### 테스트 원칙

1. **각 Action에 대한 State 변화 테스트**
2. **Effect 결과에 대한 검증**
3. **Dependency Mock 활용**
4. **에러 케이스 테스트**

---

## 커밋 규칙

TCA 개발 시 권장 커밋 분리:

```bash
# State/Action 정의
git commit -m "[Feat]: PlaylistFeature State 및 Action 정의"

# Reducer 구현
git commit -m "[Feat]: PlaylistFeature Reducer 구현"

# View 구현
git commit -m "[Design]: PlaylistView UI 구현"

# 테스트 추가
git commit -m "[Test]: PlaylistFeature Reducer 테스트 추가"

# 리팩토링
git commit -m "[Refactor]: PlaylistFeature 에러 처리 개선"
```

---

## Dependency 관리

### Dependency 정의

```swift
// Dependencies.swift
import Dependencies

struct PlaylistClient {
  var fetch: @Sendable () async throws -> [Playlist]
  var create: @Sendable (Playlist) async throws -> Playlist
}

extension PlaylistClient: DependencyKey {
  static let liveValue = PlaylistClient(
    fetch: { /* API 호출 */ },
    create: { /* API 호출 */ }
  )

  static let testValue = PlaylistClient(
    fetch: { [] },
    create: { $0 }
  )
}

extension DependencyValues {
  var playlistClient: PlaylistClient {
    get { self[PlaylistClient.self] }
    set { self[PlaylistClient.self] = newValue }
  }
}
```

### Reducer에서 사용

```swift
@Reducer
struct PlaylistFeature {
  @Dependency(\.playlistClient) var playlistClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .fetchPlaylists:
        return .run { send in
          let playlists = try await playlistClient.fetch()
          await send(.playlistsResponse(.success(playlists)))
        } catch: { error, send in
          await send(.playlistsResponse(.failure(error)))
        }
      // ...
      }
    }
  }
}
```

---

## 참고 자료

- [TCA 공식 문서](https://pointfreeco.github.io/swift-composable-architecture/)
- [Kent Beck TDD 가이드](./kentback-tdd-guide.md)
- [프로젝트 CLAUDE.md](../../CLAUDE.md)
