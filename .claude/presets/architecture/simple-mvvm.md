# 아키텍처 — 가벼운 MVVM (후보 A)

> 프리셋 원본이다. 선택되면 `/project-setup`이 이 내용을 `docs/conventions/architecture.md`로 옮기고 프로젝트에 맞게 고친다.

이 프로젝트는 **기능 폴더 + MVVM** 구조를 쓴다. 계층을 잘게 나누지 않고, 규칙이 많아지는 기능만 나중에 UseCase · Repository로 나눈다(후보 B로 점진 이전).

```text
View  →  ViewModel  →  Service (API · 저장 · 시스템 기능)
```

| 구성 | 맡는 일 |
|---|---|
| View | 그리기 · 사용자 입력 전달 |
| ViewModel | 화면 상태, 간단한 규칙, Service 호출 |
| Service | API · 로컬 저장 · 시스템 기능(알림 · 권한 · 파일) 감싸기. 프로토콜/인터페이스로 두고 가짜 구현으로 테스트 |
| 내비게이션 | 플랫폼 기본 방식. 화면이 늘어 흐름이 복잡해지면 Router 도입을 DEC로 결정 |

## 폴더

```text
App/          진입점 · Service 조립          (공통 파일)
Core/         공통 컴포넌트 · Service 구현     (공통 파일)
Features/
└── <Feature>/   <Screen>View · <Screen>ViewModel · 기능 전용 Service · 컴포넌트
```

## 규칙

- View에 네트워크 · 저장 코드를 쓰지 않는다 — ViewModel → Service.
- 같은 규칙이 두 ViewModel에 생기면 Service나 공통 함수로 뺀다. 규칙이 계산 · 상태 전이 수준이 되면 그 기능은 UseCase로 나눈다(후보 B의 Domain 방식).
- 새 아키텍처 · 라이브러리는 임의로 들이지 않는다.

## 플랫폼 메모

| 플랫폼 | ViewModel | Service | 테스트 |
|---|---|---|---|
| iOS · macOS (SwiftUI) | `@MainActor @Observable final class` | `protocol …Service` + `Live…` · `Mock…` | Swift Testing / XCTest |
| Android (Compose) | `ViewModel` + `StateFlow` | `interface …Service` + 구현 · Fake | JUnit + coroutines-test |
| Web (React) | 화면 훅 `use<Screen>()` | `src/services/*` 함수 · 객체 | Vitest · Testing Library |

## 에이전트

`feature-agent`가 기능 하나(View · ViewModel · 기능 Service · 테스트)를 맡는다. `domain-agent` · `data-agent`는 쓰지 않는다. 리뷰는 `reviewer`, 조회는 `utility`.

## 아키텍처 검사

```sh
verify_arch() {
  bad=0
  # 화면 파일에 네트워크 · 저장 코드 직접 사용 금지
  grep -rlE 'URLSession|UserDefaults\.standard|FileManager\.default' --include=*View.swift . 2>/dev/null && bad=1
  grep -rlE 'Retrofit|HttpClient|SharedPreferences' --include=*Screen.kt . 2>/dev/null && bad=1
  grep -rlE 'fetch\(|axios|localStorage' --include=*.tsx src 2>/dev/null | grep -vE '(/services/|/hooks/|use[A-Z][A-Za-z]*\.tsx)' && bad=1
  [ $bad -eq 0 ]
}
```
