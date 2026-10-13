# 자동화 — Claude Code 스킬 · Hook · 설정

최소 자동화만 둔다. 새 도구보다 기존 도구(`git` · `gh` · 빌드 도구)를 먼저 쓴다.

| 구성 | 파일 | 하는 일 |
|---|---|---|
| 설정 한 곳 | `.claude/project.sh` | 저장소 · 기본 브랜치 · 커밋 언어 · 연결 ID · 경로→영역 · 영역별 검증 함수 |
| `/project-setup` | `.claude/skills/project-setup/` | 첫 세션에 빈칸(`TODO(setup)`)을 대화로 채움 |
| `/design-sync` | `.claude/skills/design-sync/` | Claude Design(`DESIGN_URL`) 변경을 etag로 찾아 요구사항 · 화면 문서 갱신(읽기 전용) |
| `/start-feature` | `.claude/skills/start-feature/` | 미커밋 확인 → 이슈 열림 확인 → `main` 최신화 → 브랜치 생성 → 연결 ID 안내 |
| `/finish-feature` | `.claude/skills/finish-feature/` | `check.sh`(브랜치 · 커밋 형식 · 비밀값 · 영역) → `verify.sh <영역>` → PR 초안 → 승인 후 push · PR |
| SessionStart hook | `.claude/hooks/session-start.sh` · `.claude/settings.json` | 세션 시작 때 브랜치 · 변경 수 · 이슈 번호 · 설정 미완료를 두세 줄로 알림 |

직접 실행:

```sh
sh .claude/skills/start-feature/scripts/start.sh feat 12 login-form
sh .claude/skills/finish-feature/scripts/check.sh
sh .claude/skills/finish-feature/scripts/verify.sh claude web
```

## 아키텍처 검사

`verify.sh arch` — `.claude/project.sh`의 `verify_arch`(플랫폼 프리셋에서 붙임)가 계층 침범을 grep으로 찾는다: Domain의 UI · 네트워크 import, 화면의 Data 직접 사용, View의 내비게이션 직접 조작. 걸리면 파일 경로가 로그에 나온다. 규칙이 프로젝트와 맞지 않으면 함수를 고친다(검사를 지워서 통과시키지 않는다).

## 검증 영역 추가

`.claude/project.sh`에서
1. `AREAS`에 `^apps/web/   web` 같은 줄 추가(경로 → 영역)
2. `verify_web() { npm --prefix apps/web test --silent; }` 함수 추가
3. `verify.sh web`으로 실제 실행해 PASS 확인. 없는 명령을 성공 처리하지 않는다.

## Hook 끄기

| 상황 | 방법 |
|---|---|
| 모두에게 끄기 | `.claude/settings.json`에서 `SessionStart` 블록 삭제 후 커밋 |
| 나만 잠깐 | `.claude/settings.local.json`(gitignore됨)에 `{"disableAllHooks": true}` — 전역 hook도 함께 꺼짐 |
| 출력 확인 | `echo '{}' \| CLAUDE_PROJECT_DIR=$PWD sh .claude/hooks/session-start.sh; echo $?` |

차단(PreToolUse) · 자동 수정(PostToolUse) hook은 기본으로 두지 않는다. 필요하면 따로 시험한 뒤 추가한다.
