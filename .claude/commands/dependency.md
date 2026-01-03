# TCA Dependency 생성

다음 API/서비스에 대한 TCA Dependency를 생성해주세요: $ARGUMENTS

## Dependency 구조

```swift
import Dependencies

struct {Name}Client {
  var fetch: @Sendable () async throws -> [Model]
  var create: @Sendable (Model) async throws -> Model
  var update: @Sendable (Model) async throws -> Model
  var delete: @Sendable (String) async throws -> Void
}

extension {Name}Client: DependencyKey {
  static let liveValue = {Name}Client(
    fetch: {
      // 실제 API 호출 (Moya/Supabase)
    },
    create: { model in
      // 생성 API
    },
    update: { model in
      // 수정 API
    },
    delete: { id in
      // 삭제 API
    }
  )

  static let testValue = {Name}Client(
    fetch: { [] },
    create: { $0 },
    update: { $0 },
    delete: { _ in }
  )

  static let previewValue = {Name}Client(
    fetch: { [.mock, .mock2] },
    create: { $0 },
    update: { $0 },
    delete: { _ in }
  )
}

extension DependencyValues {
  var {name}Client: {Name}Client {
    get { self[{Name}Client.self] }
    set { self[{Name}Client.self] = newValue }
  }
}
```

## 파일 위치

- `Projects/App/Sources/Dependencies/{Name}Client.swift`

## Reducer에서 사용

```swift
@Reducer
struct SomeFeature {
  @Dependency(\.{name}Client) var {name}Client

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .fetchData:
        return .run { send in
          let data = try await {name}Client.fetch()
          await send(.dataResponse(.success(data)))
        } catch: { error, send in
          await send(.dataResponse(.failure(error)))
        }
      // ...
      }
    }
  }
}
```
