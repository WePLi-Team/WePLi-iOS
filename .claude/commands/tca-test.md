# TCA Feature 테스트 생성

다음 Feature에 대한 TestStore 테스트를 생성해주세요: $ARGUMENTS

## 테스트 작성 원칙 (TDD)

1. **Red**: 먼저 실패하는 테스트 작성
2. **Green**: 최소한의 코드로 테스트 통과
3. **Refactor**: 테스트 통과 상태에서 리팩토링

## 생성할 테스트 케이스

1. **State 변화 테스트**
   - 동기적 Action의 State 변화 검증
   - 초기 State 확인

2. **Effect 테스트**
   - 비동기 Action 및 응답 처리
   - `.receive()` 검증

3. **에러 케이스 테스트**
   - 실패 시나리오 처리
   - 에러 State 검증

4. **엣지 케이스 테스트**
   - 경계 조건 처리
   - 빈 데이터, 중복 요청 등

## 테스트 템플릿

```swift
import ComposableArchitecture
import XCTest

@MainActor
final class {FeatureName}Tests: XCTestCase {

  func test_onAppear_shouldFetchData() async {
    let store = TestStore(initialState: {Feature}.State()) {
      {Feature}()
    } withDependencies: {
      $0.{client}.fetch = { /* mock data */ }
    }

    await store.send(.onAppear) {
      $0.isLoading = true
    }

    await store.receive(\.{response}.success) {
      $0.isLoading = false
      $0.data = /* expected data */
    }
  }
}
```

## 파일 위치

- `Projects/App/Tests/{FeatureName}Tests/`

## 참고

- [kentback-tdd-guide.md](docs/dev/kentback-tdd-guide.md)
