# TCA Feature 생성

다음 기능에 대한 TCA Feature를 생성해주세요: $ARGUMENTS

## 생성할 항목

1. **State 정의** (`@ObservableState`)
   - 필요한 상태 프로퍼티
   - Equatable 준수

2. **Action 정의** (`enum Action`)
   - 사용자 액션 (onAppear, 버튼 탭 등)
   - 응답 액션 (API 결과 등)

3. **Reducer 구현** (`@Reducer`)
   - 각 Action에 대한 State 변경
   - Effect 처리 (.run, .send 등)
   - @Dependency 주입

4. **View 구현** (SwiftUI View)
   - StoreOf<Feature> 사용
   - WithPerceptionTracking 래핑
   - store.send() 호출

5. **Dependency** (필요 시)
   - DependencyKey 정의
   - liveValue, testValue 구현

## 파일 위치

- Feature: `Projects/App/Sources/Features/{FeatureName}/`
- View: `Projects/App/Sources/Features/{FeatureName}/`
- Dependency: `Projects/App/Sources/Dependencies/`

## 참고

- [claude-commands-guide.md](docs/dev/claude-commands-guide.md)
- [kentback-tdd-guide.md](docs/dev/kentback-tdd-guide.md)
