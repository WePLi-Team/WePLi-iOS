# 결정 기록 (DEC)

사용자가 정한 것만 적는다. AI는 초안을 제안할 수 있지만 결정하지 않는다. 기준 문서끼리 충돌하면 여기가 가장 우선이다.

| ID | 날짜 | 결정 | 이유 · 대안 | 영향 문서 |
|---|---|---|---|---|
| DEC-001 | 2026-10-13 | 프로젝트 템플릿(ai-dev-starter)으로 작업 규칙 · 자동화를 시작한다 | 이슈 → 브랜치 → 검증 → PR 흐름을 첫날부터 쓰기 위해 | AGENTS.md |
| DEC-002 | 2026-10-13 | 아키텍처는 **지금 TCA 구조 유지**(Features/<F>/{Feature,View,Client,Models,Components}, 외부 접근은 `@Dependency` Client) | 기존 코드 3개 기능(App · Login · Main)이 이미 TCA로 일관됨 · CLAUDE.md가 TCA를 요구 · 투표 · 랭킹 규칙은 서버가 원본이라 클라이언트 Domain 계층 필요성이 낮음. 비교: TCA + Domain/Data 분리(규칙 테스트 · 에이전트 병렬에 유리하나 파일 수 7–9개) · 나중에 정하기. 다시 검토: 같은 규칙을 2개 이상 기능이 공유하거나 Reducer가 500줄을 넘을 때 | docs/conventions/architecture.md · agents.md · .claude/project.sh verify_arch |
| DEC-003 | 2026-10-13 | Git은 **기존 규칙 유지**: develop 기준 PR, 커밋 `[Type]: 한국어 요약`, 브랜치 `<type>/<issue>-<slug>`. 템플릿 스크립트를 이 형식에 맞춘다(`BRANCH_TYPES` · `COMMIT_PATTERN`). 직접 push 예외 없음 | 기존 이력 · docs/git 규칙과 일치. 대안: Conventional Commits로 전환 · 검사 끄기 | docs/conventions/git.md · .claude/project.sh · check.sh · start.sh |
| DEC-004 | 2026-10-13 | 도메인 규칙: 시간은 Asia/Seoul 기준 · 개인정보 · 토큰을 로그에 남기지 않음 · 투표 · 점수 · 순위는 서버 값이 원본 | 마감 · 시즌 · 오늘의 한 곡이 날짜 경계에 의존 · public 저장소 · 조작 방지 | AGENTS.md |
| DEC-005 | 2026-10-13 | iOS 26 이상은 **Claude Design 원본(iOS 26 패턴)대로** 만든다(리퀴드 글래스 탭 바 · 탭 바 액세서리 · 검색 탭 등). iOS 16–25용 디자인은 사용자가 나중에 따로 제공한다. 그 전까지 iOS 26 미만은 `#available` 분기만 두고 임의로 디자인하지 않는다 | 배포 대상은 iOS 16.0 유지, 원본은 iOS 26 기준 | docs/design/README.md · architecture.md · AGENTS.md |
| DEC-006 | 2026-10-13 | 홈 디자인은 사용자가 마무리해 결정본을 제공한다. 그 전까지 1b · 4a · 9a · 9b 중 어느 것도 채택하지 않는다 | 시안 4개가 병존 | requirements.md REQ-020 |
