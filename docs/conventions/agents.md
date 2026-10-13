# 에이전트 오케스트레이션 · 병렬 개발

메인 세션 = **오케스트레이터**. 어떤 에이전트를 쓰는지와 소유 경로는 `docs/conventions/architecture.md`(고른 아키텍처)가 원본이다. 에이전트 정의: `.claude/agents/`.

- **이 저장소(DEC-002 · TCA 구조 유지)**: `feature-agent`가 기능 하나 전체(Feature · View · Client · Models · Components · TestStore 테스트)를 맡는다. `domain-agent` · `data-agent`는 **사용 안 함**(파일은 남겨 둠). 아래 「기능 하나를 나누는 순서」는 계층을 나눈 구조일 때만 쓰며, 지금은 해당 없음.

## 역할

| 에이전트 | 모델 | 도구 | 격리 | 맡기는 일 |
|---|---|---|---|---|
| 오케스트레이터(메인) | 사용자 설정 | 전체 | 저장소 본체 | 분석 · 분해 · 계약 확정 · 배정 · 공통 파일 · DI · AppRoute 조립 · 검증 실행 · 커밋 · PR |
| `feature-agent` | sonnet | 읽기 · 쓰기 · Bash | worktree | View · ViewModel · 기능 컴포넌트 · `<F>Route` |
| `domain-agent` | **opus** | 읽기 · 쓰기 · Bash | worktree | UseCase · 규칙 · State Machine · Entity · Repository 인터페이스 · Domain 테스트 |
| `data-agent` | sonnet | 읽기 · 쓰기 · Bash | worktree | Repository 구현 · API · DB · DTO · Mapping |
| `reviewer` | **opus** | Read · Grep · Glob | 없음 | 아키텍처 위반 · 회귀 · 원문 불일치 · 빠진 테스트 (읽기 전용) |
| `utility` | haiku | Read · Grep · Glob | 없음 | 파일 찾기 · ID · 값 뽑기 · 짧은 요약 |

- **Review/Test = `reviewer`(읽기 전용 판단) + `verify.sh`(빌드 · 테스트 실행).** 테스트 작성은 각 계층 에이전트가 자기 코드와 함께 한다. git · 빌드 · 테스트 실행은 AI에 맡기지 않고 스크립트로 한다.
- **읽기 전용은 도구 목록으로 보장한다.** 메인 세션 권한 모드(bypass 등)가 에이전트 파일의 `permissionMode`보다 우선하기 때문이다.
- 모델은 호출할 때 바꿀 수 있다: 단순한 Domain(필드 추가 등)은 `model: sonnet`으로 내리고, 같은 작업이 sonnet으로 2번 실패하면 opus로 올린다. 바꾼 이유는 작업 기록에 남긴다.

## 기능 하나를 나누는 순서 (계층 구조일 때)

```text
1. 오케스트레이터  요구사항 · 기존 코드 분석 → 작업 분해 (작으면 나누지 않고 한 에이전트 또는 직접)
2. domain-agent    계약 커밋: Entity · UseCase 시그니처 · Repository 인터페이스 · 가짜 구현
3. 오케스트레이터  계약을 기능 브랜치에 합침
4. feature-agent ∥ data-agent   같은 계약 위에서 병렬 (소유 경로가 다름)
   domain-agent                  규칙 구현 · 테스트 (필요하면 4와 병렬)
5. 오케스트레이터  DI 조립 · AppRoute 연결(공통 파일) → verify.sh (arch 포함) → reviewer → PR
```

계약이 바뀌어야 하면 4를 멈추고 2로 돌아간다. 에이전트끼리 서로의 경로를 고치지 않는다.

## 맡길 때 넘기는 것 (필요한 것만)

```
작업: <이슈 #N · 기능 · 화면 ID>
원문 요약: <관련 행 · 규칙 · 연결 ID — 전문을 붙이지 않는다>
계약: <쓸 UseCase · Repository 인터페이스 (커밋 해시)>
소유 경로: <예: Features/Settings/Presentation/>
쓰면 안 되는 파일: 공통 파일 · 다른 계층
검증: <명령 · 작업마다 다른 환경 변수(시뮬레이터 · 포트 · 빌드 폴더)>
완료 기준: <체크 목록>
```

## 돌려받은 뒤

보고를 믿지 않고 **직접 검증한다**: `git diff --stat origin/develop...<branch>`로 보고한 파일 · 테스트가 실제로 있는지, 소유 경로 안인지 → `verify.sh <영역> arch` → `reviewer`.

## 병렬 규칙

- 병렬 구현 에이전트는 **2개로 시작**, 문제가 없을 때만 최대 3개.
- 소유 경로가 겹치지 않을 때만 병렬. 같은 공통 파일이 필요한 작업은 순차.
- 충돌이 나면 `git merge --abort` 후 순차로 돌린다. 충돌을 AI가 임의로 풀지 않는다.
- 시뮬레이터 · 포트 · 빌드 산출물 폴더는 작업마다 나눈다(같이 쓰면 테스트가 엉뚱하게 실패한다).
- worktree 결과는 받는 즉시 이슈 브랜치로 옮긴다: `git branch feat/<issue>-<slug> worktree-agent-<id>`. 미루면 정리 때 사라질 수 있다.
- 통합은 의존이 적은 것부터 하나씩: 최신 `develop` 병합 → 검증 → PR → 병합 → 다음.

## 공통 파일 (오케스트레이터 전용)

`docs/**` · `.claude/**` · `.github/**` · `AGENTS.md` · `CLAUDE.md` · `README.md` · `.gitignore`, 그리고 이 저장소의 다음 파일:

- 진입점 · 루트 Reducer(화면 전환): `Projects/App/Sources/App.swift` · `ContentView.swift` · `Features/App/`
- 공용 View · 확장: `Projects/App/Sources/Components/` · `Extensions/`
- 리소스: `Projects/App/Resources/`(Assets · Colors · `Localizable.xcstrings`) · `Projects/App/Derived/` · `Generated/`(생성물, 손으로 고치지 않음)
- Core 모듈: `Projects/Core/**`
- 프로젝트 · 의존성: `Projects/App/Project.swift` · `Workspace.swift` · `Tuist/**`(`Package.swift` · `Package.resolved` · `ProjectDescriptionHelpers`) · `Projects/App/App.entitlements`
- 설정: `Configs/*.xcconfig`(Debug · Release는 비밀값 — 커밋 금지) · `.swiftlint.yml` · `.swiftformat` · `swiftgen.yml` · `fastlane/` · `mise.toml`
