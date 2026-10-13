# 아키텍처 — Feature-based Lightweight Clean Architecture (후보 B)

> 프리셋 원본이다. 선택되면 `/project-setup`이 이 내용을 `docs/conventions/architecture.md`로 옮기고 프로젝트에 맞게 고친다.

이 프로젝트는 **Feature-based Lightweight Clean Architecture**를 쓴다. 무거운 프레임워크(TCA · Redux 계열 등)는 쓰지 않는다. 플랫폼별 구현은 아래 「플랫폼별」 절(`clean-<플랫폼>.md`).

```text
View (화면)
    ↓
ViewModel (화면 상태)
    ↓
UseCase (비즈니스 로직)
    ↓
Repository (데이터 접근 추상화)
    ↓
API / Database
```

| 구성 | 맡는 일 |
|---|---|
| MVVM | UI와 화면 상태 분리 |
| UseCase | 도메인 규칙 · 계산 (TODO(setup) 이 프로젝트의 핵심 도메인 예: 결제 · 예약 · 사용량 집계) |
| Repository | 서버 · DB · 로컬 저장소 접근 추상화. 인터페이스는 Domain, 구현은 Data |
| DI | 의존성 주입 — 조립은 앱 진입점 한 곳 |
| Router | 내비게이션 관리 — View는 목적지만 요청한다 |
| State Machine | 상태 전이가 있는 도메인(주문 · 승인 · 구독 등)의 허용 전이를 한 곳에서 관리 |

## 의존 방향 (어기면 아키텍처 위반)

- View → ViewModel → UseCase → Repository(인터페이스). 반대 방향 · 건너뛰기 금지.
- **View · ViewModel에 비즈니스 로직을 넣지 않는다.** 계산 · 규칙 · 상태 전이는 UseCase · State Machine.
- Domain(UseCase · Entity · State Machine · Repository 인터페이스)은 UI 프레임워크 · 네트워크 · DB 라이브러리를 import하지 않는다 — 순수 코드로 단위 테스트한다.
- Data(Repository 구현 · API · DB · DTO)는 DTO를 Domain Entity로 바꿔서 넘긴다. DTO가 화면까지 올라가지 않는다.
- View는 내비게이션 구조(스택 · 경로)를 직접 만지지 않고 `router.navigate(.목적지)`만 부른다.

## 폴더

기술 계층보다 **기능(Feature) 중심**으로 나눈다. 기능 안에서 계층을 나눈다.

```text
App/                 진입점 · DI 조립 · AppRouter · AppRoute        (공통 파일)
Core/                공통 유틸 · 디자인 시스템 · 네트워크 클라이언트   (공통 파일)
Features/
└── <Feature>/
    ├── Presentation/   View · ViewModel · 기능 컴포넌트 · <Feature>Route
    ├── Domain/         UseCase · Entity · State Machine · Repository 인터페이스
    └── Data/           Repository 구현 · API · DB · DTO · Mapper
```

기능 목록: TODO(setup) 기획의 화면 · 요구사항에서 뽑는다 (예: Auth · Settings · …)

작은 기능은 `Domain/` · `Data/`를 만들지 않아도 된다. 필요해질 때 이 구조로 들인다.

## 내비게이션 — Router

```text
View
  └── router.navigate(.feature(.detail(id)))
                ↓
             AppRouter
                ↓
       플랫폼 내비게이션 (NavigationStack · NavHost · 라우터)
```

- `AppRoute`는 기능별 Route를 감싼다: `AppRoute ├ AuthRoute ├ SettingsRoute ├ …`
- 각 `<Feature>Route`는 그 기능 폴더에 두고, 목적지 → 화면 생성을 맡는다.
- `AppRouter`는 스택 · 탭 · 뒤로 가기(`navigate` · `back` · `backToRoot` · `replace`)만 다룬다.

## 에이전트 오케스트레이션

한 에이전트가 모든 일을 하지 않고 **Orchestrator + 계층별 에이전트**로 나눈다(정의: `.claude/agents/`, 규칙: `docs/conventions/agents.md`).

```text
             Orchestrator (메인 세션)
                  │
      ┌───────────┼───────────┐
      ↓           ↓           ↓
 feature-agent domain-agent data-agent
      │           │           │
      └───────────┼───────────┘
                  ↓
        reviewer + verify.sh
```

| 역할 | 맡는 일 | 소유 경로 |
|---|---|---|
| Orchestrator | 요구사항 · 기존 코드 분석, 작업 분해, **계약(인터페이스) 먼저 확정**, 배정, 통합, 최종 검증 | 공통 파일 (`App/` · `Core/` · 설정 · 문서) |
| feature-agent | View, ViewModel, 기능 컴포넌트, `<Feature>Route` 연결 | `Features/<F>/Presentation/` + 그 테스트 |
| domain-agent | UseCase, 비즈니스 규칙, State Machine, Entity, Repository 인터페이스, **Domain 단위 테스트** | `Features/<F>/Domain/` + 그 테스트 |
| data-agent | Repository 구현, API, DB, DTO · Mapping | `Features/<F>/Data/` + 그 테스트 |
| reviewer | 아키텍처 위반 · 회귀 · 오류 검사, 빠진 테스트 지적 (읽기 전용) | — |
| 빌드 · 테스트 실행 | `verify.sh` (스크립트, AI가 아님) | — |

## 운영 원칙

- 모든 에이전트는 이 문서와 기존 코드를 먼저 확인하고, **기존 패턴을 먼저 재사용**한다.
- 새 아키텍처 · 라이브러리를 임의로 들이지 않는다(필요하면 멈추고 DEC 초안으로 묻는다).
- 병렬은 **소유 경로가 겹치지 않을 때만**. 한 기능을 나눌 때 순서: ① domain-agent가 Entity · UseCase · Repository 인터페이스를 먼저 커밋(계약) → ② feature-agent · data-agent가 그 계약에 맞춰 병렬 → ③ 오케스트레이터가 DI · Route 조립.
- 모델: 단순 화면 · 데이터 연결은 빠르고 저렴한 모델(sonnet), 복잡한 Domain · State Machine · 리뷰 · 아키텍처 판단은 추론이 강한 모델(opus), 조회는 haiku.

## 플랫폼별

`clean-apple-swiftui.md` · `clean-android-compose.md` · `clean-web-react.md` 중 해당하는 것을 붙인다.
