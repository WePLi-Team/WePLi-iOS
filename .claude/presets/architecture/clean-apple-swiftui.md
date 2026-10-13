### iOS · macOS — Swift · SwiftUI (후보 B 구현)

| 구성 | 구현 |
|---|---|
| View | SwiftUI `View`. 상태는 ViewModel에서 받고, 사용자 행동은 ViewModel 메서드 호출 |
| ViewModel | `@MainActor @Observable final class <Screen>ViewModel` — UseCase를 생성자 주입. 화면 상태(`state`)와 행동 메서드만 |
| UseCase | `struct` 또는 `final class`, `func callAsFunction(...) async throws -> T` 또는 이름 있는 메서드. SwiftUI · Foundation 네트워킹 import 금지 |
| Repository | Domain: `protocol <Name>Repository: Sendable`. Data: `final class Live<Name>Repository` · 테스트: `InMemory<Name>Repository` |
| DI | `App/AppContainer.swift` 하나에서 Live 구현 조립, `@Environment`로 내려준다. 프리뷰 · 테스트는 InMemory 구현 |
| Router | `@MainActor @Observable final class AppRouter` + `NavigationStack(path:)`. `enum AppRoute: Hashable { case auth(AuthRoute) … }`, 기능별 `enum <F>Route: Hashable` + `@ViewBuilder func view(router:)` |
| State Machine | `enum <Name>State` + `func transition(_ event:) throws -> <Name>State` — 허용 안 되는 전이는 오류 |
| 테스트 | Domain · ViewModel: Swift Testing(`@Test`) · XCTest. UI: XCUITest(핵심 흐름만) |

macOS 메뉴바 · 창 앱: Router 대신(또는 함께) `WindowRouter`(열 창 · 시트 관리)를 두고 같은 원칙(View는 목적지만 요청)을 따른다. `NSStatusItem` · `NSWindow` 등 AppKit 연결은 `App/` 또는 해당 Feature의 `Presentation/`에 두고 Domain으로 새지 않게 한다.

경로 예: `<앱>/Features/<F>/Presentation/<Screen>View.swift` · `…/<Screen>ViewModel.swift` · `<앱>/Features/<F>/Domain/<Verb><Noun>UseCase.swift` · `<앱>Tests/Features/<F>/…Tests.swift`

아키텍처 검사(`.claude/project.sh`에 추가, `verify.sh arch`):

```sh
verify_arch() {
  bad=0
  # Domain은 UI · 네트워크를 모른다
  grep -rlE '^import (SwiftUI|UIKit|AppKit)' --include=*.swift . 2>/dev/null | grep '/Domain/' && bad=1
  grep -rlE 'URLSession|JSONDecoder' --include=*.swift . 2>/dev/null | grep '/Domain/' && bad=1
  # 화면은 Data 계층을 직접 쓰지 않는다
  grep -rlE 'Live[A-Za-z]*Repository|URLSession' --include=*.swift . 2>/dev/null | grep '/Presentation/' && bad=1
  # View가 내비게이션 경로를 직접 만지지 않는다
  grep -rlE 'NavigationPath\(|\.append\(.*Route' --include=*View.swift . 2>/dev/null | grep '/Presentation/' && bad=1
  [ $bad -eq 0 ]
}
```
