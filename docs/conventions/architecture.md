# 아키텍처 — TCA 기능 폴더 (지금 구조 유지)

결정: DEC-002 (후보 C. 지금 구조 유지). 이 저장소의 기존 TCA 구조를 그대로 문서화한 것이다. 새 구조 · 라이브러리를 임의로 들이지 않는다.

## 한눈에

```text
WePLiApp (App.swift)
  └ ContentView → AppView(store: AppFeature)        ← 루트 Reducer · 화면 전환
       ├ LoginView(store: LoginFeature)
       └ MainView(store: MainFeature)
             └ Components/*Section (상태 없는 하위 View)

Reducer(*Feature) ──@Dependency──▶ Client(struct of closures) ──▶ Moya · Supabase · Keychain · GoogleSignIn
```

- **화면 상태 · 규칙 = Reducer.** `State`(`@ObservableState`, `Equatable`) · `Action` · `body`.
- **외부 접근 = Client.** 클로저 묶음 struct + `DependencyKey`(`liveValue` · `testValue` · `previewValue`) + `DependencyValues` 확장. Reducer는 Client만 부른다.
- **View는 store만 본다.** `WithPerceptionTracking`(iOS 16 대응) 안에서 `store`를 읽고 `store.send`로만 알린다. 네트워크 · 저장 · SDK를 직접 쓰지 않는다.

## 의존 방향

```text
View ──▶ Feature(Reducer) ──▶ Client(인터페이스) ◀── liveValue(Moya · Supabase …)
                                   ▲
                       Models(값 타입, Equatable · Sendable)
```

- View · Components → Moya · Supabase · KeychainAccess · GoogleSignIn · `URLSession` · `UserDefaults.standard` 금지 (`verify_arch`가 검사)
- `*Feature.swift` → 위 SDK 직접 사용 금지. Client를 거친다 (`verify_arch`)
- 기능끼리는 부모 Reducer의 `Scope`로만 잇는다. 형제 Feature의 내부 Action을 직접 보내지 않는다(부모가 delegate Action을 받아 연결).

## 폴더

```text
Projects/App/Sources/
  App.swift · ContentView.swift          진입점 (공통 파일)
  Features/
    App/        AppFeature · AppView     루트 Reducer · 로그인 ↔ 메인 전환 (공통 파일)
    <Feature>/
      <Feature>Feature.swift             Reducer
      <Feature>View.swift                화면
      Client/<Feature>Client.swift       외부 접근 (+ <Feature>MockData.swift)
      Models/<Feature>Models.swift       값 타입
      Components/<Name>Section.swift     하위 View
  Components/                            여러 기능이 쓰는 View (공통 파일)
  Extensions/                            (공통 파일)
Projects/App/Resources/                  Assets · Colors · Localizable.xcstrings (공통 파일)
Projects/App/Tests/                      TestStore 기반 Reducer 테스트 → Tests/Features/<Feature>/
Projects/Core/{DesignSystem,Network,Utils}  미결정 — 아직 빈 모듈. 옮길 시점은 DEC로 정한다
```

- 지금은 `AuthClient`가 `LoginFeature.swift` 안에 있다. 새 Client는 `Client/` 폴더에 둔다(기존 것은 옮기지 않음 — 별도 이슈).

## 기능 하나 추가할 때

1. `Features/<F>/` 에 Feature · View · (필요하면) Client · Models — 보통 4–6개 파일
2. 부모 Reducer에 `Scope` 또는 `@Presents` / `StackState` 연결 (공통 파일 → 오케스트레이터)
3. `Tests/Features/<F>/<F>FeatureTests.swift` — `TestStore`로 Action → State 변화 · Client 호출 확인
4. 파일 머리에 관련 ID: `// REQ-012 · UI-2c`

## 내비게이션

- 지금: `AppFeature.isLoggedIn`으로 로그인 ↔ 메인을 바꾼다(임시, 커밋 5361938).
- 탭 구조는 홈 · 릴레이 · 커뮤니티 · 마이 + 검색(원본 공통 규칙).
- 미결정 — 화면 push(`StackState` vs `NavigationStack` path) · 시트(`@Presents`) 방식. 첫 탭 바 이슈에서 DEC로 정한다.

## OS 버전별 UI (DEC-005)

- iOS 26 이상: Claude Design 원본(리퀴드 글래스 탭 바 · `tabViewBottomAccessory` · `Tab(role: .search)` 등)대로.
- iOS 16–25: 사용자가 디자인을 나중에 제공한다. 그 전까지는 `if #available(iOS 26, *)` 분기를 두고 아래쪽은 시스템 기본 컴포넌트로만 둔다(임의 디자인 금지).
- 분기는 View 안에서만 한다. Reducer · Client는 OS 버전을 모른다.

## 규칙이 있는 기능

투표 · 곡 월드컵 · 바통 릴레이 · 1위 예측 · 시즌 랭킹 · 역전 알림은 **서버 값이 원본**이다(AGENTS.md). Reducer는 표시 · 낙관적 업데이트 · 실패 시 되돌리기만 맡는다. 클라이언트에서 계산해야 하는 규칙(마감 카운트다운, KST 날짜 경계)은 Client 또는 순수 함수로 빼서 단위 테스트한다.

## 에이전트 구성

| 에이전트 | 맡는 것 | 소유 경로 |
|---|---|---|
| `feature-agent` | 기능 하나 전체: Feature · View · Client · Models · Components · 테스트 | `Projects/App/Sources/Features/<F>/` · `Projects/App/Tests/Features/<F>/` |
| `reviewer` | 아키텍처 위반 · 원문 불일치 · 빠진 테스트 (읽기 전용) | — |
| `utility` | 파일 찾기 · ID 뽑기 | — |
| `domain-agent` · `data-agent` | **사용 안 함** (계층을 나누지 않음) | — |

## 다시 검토할 조건

- 규칙이 클라이언트에 많이 생겨 Reducer가 비대해지면(예: 한 Reducer 500줄 이상, 같은 규칙을 2개 이상 기능이 공유) Domain 분리(UseCase) 검토
- 실제 API가 붙어 Client가 많아지면 `Core/Network`로 공통 클라이언트 이동 검토
