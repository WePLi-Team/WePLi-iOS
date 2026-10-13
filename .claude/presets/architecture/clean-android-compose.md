### Android — Kotlin · Jetpack Compose (후보 B 구현)

| 구성 | 구현 |
|---|---|
| View | `@Composable fun <Screen>Screen(state, onAction)` — 상태를 받아 그리기만. `<Screen>Route` Composable이 ViewModel을 연결 |
| ViewModel | `class <Screen>ViewModel(...) : ViewModel()` — `StateFlow<UiState>` 노출, 행동은 `fun onAction(action)`. UseCase 생성자 주입 |
| UseCase | `class <Verb><Noun>UseCase(private val repo: …) { suspend operator fun invoke(...): T }` — `android.*` · Compose import 금지 (가능하면 순수 Kotlin 모듈) |
| Repository | Domain: `interface <Name>Repository`. Data: `class Default<Name>Repository` (Retrofit · Ktor · Room) · 테스트: `Fake<Name>Repository` |
| DI | 기존 프로젝트에 있으면 그것(Hilt · Koin), 없으면 수동 `AppContainer`(Application에서 생성). 새 DI 라이브러리 도입은 DEC로 결정 |
| Router | Navigation Compose `NavHost` + `sealed interface AppRoute` (type-safe `@Serializable` 목적지), 기능별 `<F>Route` + `NavGraphBuilder.<f>Graph(router)`. 화면은 `router.navigate(...)` 람다만 받는다 |
| State Machine | `sealed interface <Name>State` + `fun transition(event): <Name>State` — 허용 안 되는 전이는 예외 · `Result.failure` |
| 테스트 | Domain · ViewModel: JUnit + kotlinx-coroutines-test (+ Turbine). UI: Compose UI Test(핵심 흐름만) |

경로 예: `app/src/main/java/<pkg>/features/<f>/presentation/…` · `…/domain/…` · `…/data/…` (패키지 이름은 소문자)

아키텍처 검사(`verify_arch`):

```sh
verify_arch() {
  bad=0
  grep -rlE '^import (android\.|androidx\.compose|retrofit2|io\.ktor|androidx\.room)' --include=*.kt . 2>/dev/null | grep '/domain/' && bad=1
  grep -rlE 'Default[A-Za-z]*Repository|Retrofit|HttpClient' --include=*.kt . 2>/dev/null | grep '/presentation/' && bad=1
  grep -rlE 'NavController' --include=*Screen.kt . 2>/dev/null | grep '/presentation/' && bad=1
  [ $bad -eq 0 ]
}
```
