# 결정 기록 (DEC)

사용자가 정한 것만 적는다. AI는 초안을 제안할 수 있지만 결정하지 않는다. 기준 문서끼리 충돌하면 여기가 가장 우선이다.

| ID | 날짜 | 결정 | 이유 · 대안 | 영향 문서 |
|---|---|---|---|---|
| DEC-001 | 2026-10-13 | 프로젝트 템플릿(ai-dev-starter)으로 작업 규칙 · 자동화를 시작한다 | 이슈 → 브랜치 → 검증 → PR 흐름을 첫날부터 쓰기 위해 | AGENTS.md |
| DEC-002 | 2026-10-13 | 아키텍처는 **지금 TCA 구조 유지**(Features/<F>/{Feature,View,Client,Models,Components}, 외부 접근은 `@Dependency` Client) | 기존 코드 3개 기능(App · Login · Main)이 이미 TCA로 일관됨 · CLAUDE.md가 TCA를 요구 · 투표 · 랭킹 규칙은 서버가 원본이라 클라이언트 Domain 계층 필요성이 낮음. 비교: TCA + Domain/Data 분리(규칙 테스트 · 에이전트 병렬에 유리하나 파일 수 7–9개) · 나중에 정하기. 다시 검토: 같은 규칙을 2개 이상 기능이 공유하거나 Reducer가 500줄을 넘을 때 | docs/conventions/architecture.md · agents.md · .claude/project.sh verify_arch |
| DEC-003 | 2026-10-13 | Git은 **기존 규칙 유지**: develop 기준 PR, 커밋 `[Type]: 한국어 요약`, 브랜치 `<type>/<issue>-<slug>`. 템플릿 스크립트를 이 형식에 맞춘다(`BRANCH_TYPES` · `COMMIT_PATTERN`). 직접 push 예외 없음 | 기존 이력 · docs/git 규칙과 일치. 대안: Conventional Commits로 전환 · 검사 끄기 | docs/conventions/git.md · .claude/project.sh · check.sh · start.sh |
| DEC-004 | 2026-10-13 | 도메인 규칙: 시간은 Asia/Seoul 기준 · 개인정보 · 토큰을 로그에 남기지 않음 · 투표 · 점수 · 순위는 서버 값이 원본 | 마감 · 시즌 · 오늘의 한 곡이 날짜 경계에 의존 · public 저장소 · 조작 방지 | AGENTS.md |
| DEC-005 | 2026-10-13 | iOS 26 이상은 **Claude Design 원본(iOS 26 패턴)대로** 만든다(리퀴드 글래스 탭 바 · 탭 바 액세서리 · 검색 탭 등). iOS 16–25용 디자인은 사용자가 나중에 따로 제공한다. 그 전까지 iOS 26 미만은 `#available` 분기만 두고 임의로 디자인하지 않는다. → 12차에서 홈(12b · 12c)과 크롬 공통 규칙(12d)을 제공받음. **사용자 결정: 12d를 모든 화면의 iOS 16 기준으로 쓴다** — 레이아웃은 iOS 26 원본을 공유하고 크롬만 12d대로 바꾼다 | 배포 대상은 iOS 16.0 유지, 원본은 iOS 26 기준 | docs/design/README.md · architecture.md · AGENTS.md |
| DEC-006 | 2026-10-13 | 홈 디자인은 사용자가 마무리해 결정본을 제공한다. → **사용자가 12차(UI-12a · 12b · 12c, 통합 홈)로 제공함**. 1b · 4a · 9a · 9b는 이것으로 대체 | 시안 4개가 병존했음 | requirements.md REQ-020 · design/screen-index.md |
| DEC-007 | 2026-10-14 | 화면 이동은 **TCA StackState**로 한다. 탭마다 `StackState<Path.State>` + `NavigationStack(path:)`, push되는 화면은 `@Reducer enum Path`의 case | 이동이 상태라 TestStore로 흐름을 테스트할 수 있고 딥링크(바통 초대 등)를 상태로 열 수 있음. 대안: 화면별 `@Presents`(트리) · 나중에 정하기 | docs/conventions/architecture.md · MainTabFeature |
| DEC-008 | 2026-10-15 | 통합 홈은 **12차 갱신본(17섹션)이 확정본**이다. 히어로 → TOP 100 → 배너 → 내 추천곡 → 투표 중 릴레이 → 1위 예측 → 친구가 듣는 중 → 지금 위플리에서 듣는 중 → 오늘의 플리 → 시간대 추천 → 내 최애 가수 → Fa♥orite → 커뮤니티 인기글 → 인기 랭킹 → 추천 플리 → 테마별 플리 → Youtube Cover. 백엔드가 필요한 섹션은 목업으로 먼저 만든다 | 원본에 확정 표시가 없어 확인함(DEC-006 갱신) | requirements.md REQ-020 · design/README.md 충돌 #13 |
| DEC-009 | 2026-10-15 | 디자인 쪽 원칙(분홍은 좋아요 · 급상승만 · 흰 바탕 버튼 금지 · iOS 세그먼트 · 라디오는 설정 화면만 · 「전체보기」 글자 링크 금지)을 **이미 만든 화면에도 적용**한다 | 앱 전체 톤을 하나로. 대안: 새 화면에만 적용 | design/README.md 「디자인 원칙」 · 이슈 #95 |
| DEC-010 | 2026-10-15 | 친구 프로필은 **13g B안**(게시글 · 플리 · 릴레이 · 들은 음악 탭)으로 만들고, 5a 사용자 프로필을 대신한다 | 13c A안과 병존했음. 대안: 13c · 나중에 정하기 | design/screen-index.md · REQ-071 · REQ-079 |
| DEC-011 | 2026-10-15 | 최소 글자 크기는 **디자인 시스템 글자 단계대로** 한다(탭 바 라벨 10 · 약관 11 · 태그 10 · HOST 배지 10 허용) | 공통 규칙 「12px 미만 금지」와 디자인 시스템이 어긋났음. 대안: 12px 이상으로 올림 | design/README.md 충돌 #11 · DesignSystem/WePLiFont |

| DEC-012 | 2026-10-19 | 오늘의 한 곡(UI-6c)은 **홈 「오늘의 플리」 섹션 머리**에서 연다. 홈 17섹션(DEC-008)은 그대로 둔다 | 6c 원본에 진입점이 없었음. 대안: 매일 알림 · 커뮤니티 위 카드 | design/screen-index.md · REQ-101 |
| DEC-013 | 2026-10-19 | 고객센터(UI-7b)는 **마이 › 앱 정보 그룹의 「고객센터」 행**에서 연다 | 1e · 7b 원본에 진입점이 없었음. 대안: 앱 정보(7g) 안 링크 · 둘 다 | REQ-111 · UI-1e |
| DEC-014 | 2026-10-19 | 시스템 상태(UI-7d)는 **앱 시작 때 서버 설정**으로 띄운다(강제 업데이트 · 점검 · 이벤트 팝업). 오프라인은 네트워크 감지, 이용 제한은 커뮤니티 동작 때 서버 응답. 겹치면 **강제 업데이트 > 점검 > 오프라인 > 이용 제한 > 이벤트** 순으로 하나만 보인다. 백엔드가 정해지기 전까지 목업 | 원본에 표시 조건 · 우선순위가 없었음. 대안: 화면만 먼저 · 나중에 정하기 | REQ-112 |
| DEC-015 | 2026-10-19 | 잠금화면 위젯(UI-13e)을 위해 **위젯 확장 타깃과 App Group(group.<번들 ID>)을 추가**한다. 데이터는 목업. Apple Developer의 App Group 등록은 사용자가 한다 | 13e는 WidgetKit 확장이 필요함. 대안: 화면 · 모델만 먼저 | REQ-079 · Project.swift |
