# 코드 규칙 — 폴더 · 이름 · 오류 · 테스트

`AGENTS.md`의 세부 내용이다. 실제와 달라지면 이 문서를 먼저 고친다.

## 폴더 구조

기능 중심 · 계층 구조는 `docs/conventions/architecture.md`가 원본이다. 여기에는 실제 경로만 적는다.

```
Projects/App/Sources/Features/<Feature>/
  <Feature>Feature.swift  <Feature>View.swift
  Client/<Feature>Client.swift  Client/<Feature>MockData.swift
  Models/<Feature>Models.swift
  Components/<Name>Section.swift
Projects/App/Tests/Features/<Feature>/<Feature>FeatureTests.swift
Projects/App/Resources/{Assets,Colors}.xcassets · Localizable.xcstrings
```
- 공통 컴포넌트 · 설정은 한 곳에 두고 「공통 파일」로 취급한다(`docs/conventions/agents.md`).

## 이름

| 대상 | 규칙 | 예 |
|---|---|---|
| Reducer | `<Feature>Feature` (`@Reducer struct`) | `RelayDetailFeature` |
| View | `<Feature>View`, `store: StoreOf<<Feature>Feature>` | `RelayDetailView` |
| Action | 사용자 동작은 `<대상><동작>`(과거형), 응답은 `<무엇>Response` / `<무엇>Loaded` | `voteButtonTapped` · `dataLoaded(_)` |
| 부모에게 알림 | `case delegate(Delegate)` | `.delegate(.didFinishVoting)` |
| Client | `<Feature>Client` struct of closures + `DependencyValues.<feature>Client` | `mainClient` |
| 하위 View | `<Name>Section` · `<Name>Row` · `<Name>Card` | `ChartSection` |
| 테스트 | `<Feature>FeatureTests`, `func test<동작>_<기대>()` | `testVoteTapped_updatesRank` |
| 파일 · 타입 | UpperCamelCase, 파일 하나에 주 타입 하나 | |

- Swift 스타일은 `.swiftlint.yml` · `.swiftformat`이 원본이다(2칸 들여쓰기, 120자, `self` 명시). `print` 대신 `Logger`를 쓴다.

- 파일 머리에 관련 ID를 적는다: `// REQ-012`.

## 값 · 토큰

- 색 · 간격 · 글자 · 시간 같은 값은 토큰 · 설정 이름으로만 쓴다. 화면 코드에 숫자를 직접 쓰지 않는다.
- 토큰은 `Projects/App/Sources/DesignSystem/`에 있다(REQ-004).

  | 무엇 | 쓰는 법 |
  |---|---|
  | 색 | `WePLiColor.accent` · `.surface1` · `.textSecondary` … |
  | 그라디언트 | `WePLiGradient.cta` · `.brand` · `.bottomFade` |
  | 글자 | `.wepliFont(.body)` · `.wepliFont(.title2)` · 굵기만 바꿀 때 `.wepliFont(.subheadline, weight: .medium)` |
  | OS별 크롬 | `@Environment(\.wepliChrome)` → `.glass`(iOS 26) / `.material`(iOS 16–25). 수치는 `chrome.sheetCornerRadius` 등 |
  | 컴포넌트 | `WePLiIconButton` · `WePLiPrimaryButton` · `.wepliToast($message)` · `.wepliSheetStyle()` |
- iOS 26 전용 API(`glassEffect` 등)는 배포 대상이 iOS 16이라 `if #available(iOS 26, *)`로 감싸고, 그 밖의 OS는 디자인 값(`wepliGlass`)으로 그린다. CI도 Xcode 26.5라 `#if compiler(>=6.2)` 가드는 더 필요 없다.
- 기존 `Colors.xcassets`(Neutral · CoolGray)는 원본 디자인 토큰이 아니다. 새 화면에서는 `WePLiColor`를 쓴다.
- 생성물은 손으로 고치지 않는다.

## 오류 처리

- 화면 상태: 로딩 · 빈 · 오류 · 오프라인 · 권한 없음을 구분한다.
- 사용자에게 보이는 문구는 기준 문서 문구를 쓴다. 내부 오류 메시지 · 스택을 화면에 보이지 않는다.
- 오류를 삼키지 않는다. 잡으면 기록하거나 사용자에게 알린다.
- 로그에 개인정보 · 토큰을 남기지 않는다.
- 되돌리기 어려운 동작은 확인 단계를 거친다.

## 테스트

| 대상 | 최소 기준 | 명령 (`.claude/project.sh` verify_<영역>) |
|---|---|---|
| Reducer(`*Feature`) | Action마다 State 변화 · Client 호출을 `TestStore`로 확인. Client는 `withDependencies`로 가짜 주입 | `verify_ios` (아래) |
| 시간 · 마감 계산 | Asia/Seoul 기준 날짜 경계 · 카운트다운 포맷 단위 테스트(`continuousClock` · `date` 의존성 고정) | `verify_ios` |
| View | 테스트 없음. `#Preview`에 상태별(로딩 · 빈 · 오류) 미리보기 | — |
| 아키텍처 | View · Feature가 SDK · `URLSession`을 직접 쓰지 않음 | `verify_arch` |
| 린트 | SwiftLint (CI는 `--strict` + SwiftFormat lint) | `verify_ios` 첫 단계 |

`verify_ios` = `mise exec -- swiftformat --lint` · `mise exec -- swiftlint --strict`(버전은 `.mise.toml`) → `verify_arch` → `xcodebuild test -workspace WePLi.xcworkspace -scheme WePLi -destination 'platform=iOS Simulator,name=${SIM:-iPhone 17}'`. 워크스페이스가 없으면 먼저 `tuist install && tuist generate --no-open`.

- 테스트 데이터는 가짜만 쓴다(실제 이름 · 번호 · 계좌 금지).
- 보고에는 실행한 명령과 결과를 그대로 붙인다. 못 돌렸으면 "미실행"과 이유.
- 검사를 약하게 만들어 통과시키지 않는다(테스트 삭제 · 기대값 변경 · `continue-on-error` 금지).
